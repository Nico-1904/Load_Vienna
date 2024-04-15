classdef PacketProcessing < tools.HiddenHandle & matlab.mixin.Heterogeneous
    %PacketProcessing superclass for all traffic models
    % that contains packet generation and transmission
    % functionalities according to traffic models states. In this
    % class, a buffer that contains data packets is created, each
    % packet is associated with a user to which it belongs
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.DataPacket, trafficModels.ConstantRate,
    % trafficModels.FullBuffer, trafficModels.FTP, trafficModels.HTTP,
    % trafficModels.VideoStreaming, trafficModels.Gaming,
    % trafficModels.VoIP

    properties
        % packet buffer
        % [1xnPackets]handleObject trafficModels.DataPacket
        packetBuffer

        % packet counter
        % [1x1]double counter for packets number in the buffer
        packetCounter = 1;

        % queue size in bits
        % [1x1]integer number of non transmitted bits in the packets buffer
        nBitsQueue = 0;
    end

    properties(Dependent)
        % a user and a corresponding traffic model are considered active
        % if at least one bit is in the buffer
        %
        % see also: scheduler.Scheduler,
        % scheduler.BestCQIScheduler,
        % scheduler.RoundRobinScheduler
        isActive
    end

    methods
        function checkNewPacket(obj, bits, numofSlots, iSlot, initialTime)
            % check if new data packet has to be generated in the
            % current slot, if necessary, a new packet is
            % appended to packets buffer
            %
            % input:
            %   bits:        [1x1]double packet size
            %   numofSlots : [1x1]double number of slots necessary to
            %                 generate new packet
            %   iSlot:       [1x1]double index of current slot
            %   initialTime: [1x1]double initial time for packet
            %                 generation

            % check if current slot equals initial time or
            % multiple of number of slots that are needed to generate
            % new packet added to the initial time
            if iSlot == initialTime || ~mod(iSlot-initialTime,numofSlots)
                % add packet to the buffer
                packetToAdd = trafficModels.DataPacket(bits,iSlot,obj.packetCounter);
                obj.packetBuffer = [obj.packetBuffer, packetToAdd];

                % update number of bits in queue
                obj.nBitsQueue = obj.nBitsQueue + bits;

                % set number of remaining bits of packet to
                % packet size
                obj.packetBuffer(obj.packetCounter).setLeftBits(bits);

                % increase packet counter after adding packet
                % to the buffer
                obj.packetCounter = obj.packetCounter +1;
            end
        end

        function value = get.isActive(obj)
            % a trafficmodel is considered as active if at least one bit
            % in its queue
            %
            % output:
            %   value: [1 x 1]logical
            value =  obj.nBitsQueue >0;
        end

        function [bufferedPackets, bufferedBits, generationSlot] = getBufferState(obj)
            % check packets in buffer and provide their number, ther
            % generation times and how many bits remain in each one
            %
            % output:
            %   bufferedPackets: [1x1]double number of packets
            %   bufferedBits:    [1xnPackets]double remaining
            %                     bits in each packet
            %   generationSlot : [1xnPackets]double generation slot for
            %                     each packet

            % get number of buffered packet
            bufferedPackets = length(obj.packetBuffer);

            % initialize an array for buffered bits
            bufferedBits = zeros(1,length(obj.packetBuffer));

            % initialize an array for generation times
            generationSlot = zeros(1,length(obj.packetBuffer));

            % get buffered bits and generation times of packets
            for i = 1:length(obj.packetBuffer)
                bufferedBits(i) = obj.packetBuffer(i).getLeftBits;
                generationSlot(i) = obj.packetBuffer(i).getGenerationSlot;
            end
        end

        function updateAfterTransmit(obj,sentBits, iSlot)
            % check if there are packets in the buffer
            % and update the remaining bits and successful transmission
            % times for these packets accordingly. Transmitted packets are kept in the buffer
            % since clearing the buffer is being done at the end of a chunk simulation
            %
            % input:
            %   sentBits :    [1x1]double number of transmitted bits in
            %                  current slot
            %   iSlot:        [1x1]double index of current slot

            [bufferedPackets, bufferedBits,~] = obj.getBufferState;

            if bufferedPackets

                % comupte the index of the packet which has the longest time in buffer
                iOldestPacket = find(bufferedBits,1);

                % compute remaining bits in the longest packet after a transmission
                bitsAfterTransmission = bufferedBits(iOldestPacket)- sentBits;

                % recompute remaining bits in the longest packet
                if bitsAfterTransmission > 0
                    obj.packetBuffer(iOldestPacket).setLeftBits(bitsAfterTransmission);
                elseif bitsAfterTransmission == 0
                    obj.packetBuffer(iOldestPacket).setLeftBits(bitsAfterTransmission);
                    obj.packetBuffer(iOldestPacket).setSuccessSlot(iSlot);

                    % if the remaining number of bits is negative then carry over
                    % this negative number of bits to the second packet in the
                    % buffer and so on
                elseif bitsAfterTransmission < 0
                    initial = iOldestPacket;
                    while bitsAfterTransmission < 0 && length(bufferedBits)> iOldestPacket
                        iOldestPacket = iOldestPacket + 1;
                        bitsAfterTransmission = bufferedBits(iOldestPacket) + bitsAfterTransmission;
                    end

                    % if packet is fully transmitted, set its remaining size
                    % to zero and set time of successful transmission equals to the current slot
                    last = iOldestPacket-1 ;
                    if bitsAfterTransmission > 0
                        for i = initial:last
                            obj.packetBuffer(i).setLeftBits(0);
                            obj.packetBuffer(i).setSuccessSlot(iSlot);
                        end
                        obj.packetBuffer(iOldestPacket).setLeftBits(bitsAfterTransmission);
                    else
                        for k = initial:length(obj.packetBuffer)
                            obj.packetBuffer(k).setLeftBits(0);
                            obj.packetBuffer(k).setSuccessSlot(iSlot);
                        end
                    end
                end
            end

            % update number of bits in queue
            obj.nBitsQueue = obj.nBitsQueue - sentBits;

            % set to zero if more bits would be sent than in queue
            obj.nBitsQueue = obj.nBitsQueue * (obj.nBitsQueue>0);
        end

        function latency = getTransmissionLatency(obj)
            % calculate packets transmission latency which is the difference
            % between packet generation time and successful transmission time
            %
            % To make simulations more realistic, 1 slot of latency is
            % added to the latency values
            % output:
            %   latency: [1xnPackets]double packets transmission latency

            latency = zeros(1, length(obj.packetBuffer));

            % compute transmission latency
            for p = 1 :length(obj.packetBuffer)
                latency(p) = obj.packetBuffer(p).getSuccessSlot - obj.packetBuffer(p).getGenerationSlot;
            end

            latency = latency + 1;
        end

        function clearBuffer(obj)
            % reinitialize the traffic model
            % It it necessary due to the timeline of the simulator to reset
            % packets buffer after each chunk simulation

            % check if there is data in the buffer
            [bufferedPackets,~,~] = obj.getBufferState;
            if bufferedPackets
                obj.packetBuffer = [];

                % reinitialize packet counter
                obj.packetCounter = 1;
            end
        end
    end
end

