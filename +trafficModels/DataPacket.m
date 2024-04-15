classdef DataPacket < tools.HiddenHandle
    %DataPacket Class creates data packets to be
    % added into packets buffer. They are discriminated by their properties
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing

    properties
        % generation time
        % [1x1]double generation time of packet in slots
        generationTime

        % success time
        % [1x1]double time of successful transmission of packet in slots
        successTime

        % packet size
        % [1x1]double packet size in bits
        packetSize

        % remaining of packet size
        % [1x1]double remaining of packet size after a transmission in bits
        remPacketSize

        % identity number
        % [1x1]double identification number of packet
        id
    end

    methods
        function obj = DataPacket(packetSize, generationTime, id)
            % class constructor
            %
            % input:
            %   packetSize:      [1x1]double packet size in bits
            %   generationTime : [1x1]double packet generation time
            %                     in slots
            %   id:              [1x1]double identification number of packet

            % get parameters
            obj.packetSize = packetSize;
            obj.generationTime = generationTime;
            obj.id = id;
            obj.successTime = Inf;

            % check parameters
            obj.checkParametersPacket;
        end

        function gotSize = getSize(obj)
            % get size of packet
            %
            % output:
            %   gotSize: [1x1]double packet size in bits

            gotSize = obj.packetSize;
        end

        function gotSlot = getGenerationSlot(obj)
            % get generation time of packet
            %
            % output:
            %   gotSlot: [1x1]double packet generation slot

            gotSlot = obj.generationTime;
        end

        function gotSlot = getSuccessSlot(obj)
            % get successful transmission time of packet
            %
            % output:
            %   gotSlot: [1x1]double successful transmission
            %             slot of packet

            gotSlot = obj.successTime;
        end

        function gotLeftBits = getLeftBits(obj)
            % get remaining bits of packet size
            %
            % output:
            %   gotLeftBits: [1x1]double number of remaining bits of
            %                 packet

            gotLeftBits = obj.remPacketSize;
        end

        function setLeftBits(obj,bits)
            % set remaining packet size to number of bits
            %
            % input:
            %   bits: [1x1]double number of bits

            obj.remPacketSize = bits;
        end

        function setSuccessSlot(obj,time)
            % set successful transmission time of packet
            %
            % input:
            %   time: [1x1]double number of slots

            obj.successTime = time;
        end

        function checkParametersPacket(obj)
            % check parameters compability

            if obj.packetSize <= 0
                warning("DATAPACKET:PacketSizeCompatibility", ...
                    "Packet size must be positive value");
            end

            if floor(obj.generationTime) ~= obj.generationTime || obj.generationTime <= 0
                warning("DATAPACKET:GenerationTimeCompatibility", ...
                    "Generation time must be positive integer");
            end

            if floor(obj.id) ~= obj.id || obj.id <= 0
                warning("DATAPACKET:IDCompatibility", ...
                    " Packet identification number must be positive integer");
            end

            if obj.successTime ~= Inf
                warning("DATAPACKET:SucessTimeCompatibility", ...
                    " Initial successful transmission time must be Infinite");
            end
        end
    end
end

