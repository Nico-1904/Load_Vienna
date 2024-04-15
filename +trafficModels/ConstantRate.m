classdef ConstantRate < trafficModels.PacketProcessing
    %ConstantRate Class is used for generation
    % of packets of fixed size and packet arrival rate
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing
    % networkElements.ue.User
    % parameters.user.trafficModel.TrafficModel
    % parameters.user.Parameters

    properties
        % packet size
        % [1x1]double packet size in bits
        size

        % number of slots
        % [1x1]double number of slots needed to generate new packet
        numSlots

        % initial time
        % [1x1]double random initial time for packet generation
        initialTime
    end

    methods
        function obj = ConstantRate(trafficModelParams)
            % class constructor
            %
            % input:
            %   trafficModelParams:
            %   [1x1]handleObject parameters.user.trafficModel.TrafficModel

            % call superclass constructor
            obj = obj@trafficModels.PacketProcessing();

            % set parameters
            obj.size	    = trafficModelParams.size;
            obj.numSlots    = trafficModelParams.numSlots;
            if trafficModelParams.initialTime == 0
                obj.initialTime = randi(obj.numSlots);
            else
                obj.initialTime = trafficModelParams.initialTime;
            end
        end

        function checkNewPacket(obj,iSlot)
            % check if new packet generation is necessary in the current slot
            %
            % input:
            %   iSlot: [1x1]double index of current slot

            checkNewPacket@trafficModels.PacketProcessing(obj,obj.size,obj.numSlots,iSlot,obj.initialTime);
        end

        function [bufferedPackets, remainingBits, generationSlot] = getBufferState(obj)
            % get various information about packets
            %
            % output:
            %   bufferedPackets: [1x1]double number of buffered packets
            %   remainingBits:   [1xnPackets]double remaining number of
            %                     bits for each packet
            %   generationSlot : [1xnPackets]double generation time for
            %                     each packet

            [bufferedPackets, remainingBits, generationSlot] = getBufferState@trafficModels.PacketProcessing(obj);
        end

        function updateAfterTransmit(obj, sentBits, iSlot)
            % update data in buffer according to the user throughput
            %
            % input:
            %   sentBits: [1x1]double number of transmitted bits in current slot
            %   iSlot:    [1x1]double index of current slot

            updateAfterTransmit@trafficModels.PacketProcessing(obj,sentBits,iSlot);
        end

        function latency = getTransmissionLatency(obj)
            % compute packets transmission latency
            %
            % output:
            %   latency: [1xnPackets]double transmission delay of packets

            latency = getTransmissionLatency@trafficModels.PacketProcessing(obj);
        end

        function clearBuffer(obj)
            % clear packets buffer

            clearBuffer@trafficModels.PacketProcessing(obj);
        end
    end
end

