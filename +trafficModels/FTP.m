classdef FTP < trafficModels.PacketProcessing
    %FTP Class for File Transfer Protocol traffic model simulations.
    % An FTP session is a sequence of file transfers
    % separated by reading times
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing
    % networkElements.ue.User
    % parameters.user.Parameters

    properties
        % maximum file size
        % [1x1]double maximum file size in bytes
        % which indicates upper truncation value for
        % log normal distribution
        maxFileSize

        % sigma of the truncated log normal distribution
        % [1x1]double standard deviation value of file size distribution
        sigma

        % mean of the truncated log normal distribution
        % [1x1]double mean value of file size distribution
        meanFileSize

        % mean of the exponential distribution
        % [1x1]double mean value of reading time distribution in
        % seconds
        meanReadingTime

        % lambda of the exponential distribution
        % [1x1]double lambda value of reading time distribution
        lambda

        % packet size
        % [1x1]double packet size in bits
        packetSize

        % number of slots
        % [1x1]double number of slots necessary to generate new packet
        numSlots

        % initial time
        % [1x1]double random initial time for packet generation
        initialTime
    end

    methods
        function obj = FTP()
            % class constructor

            % call superclass constructor
            obj = obj@trafficModels.PacketProcessing();

            % set parameters
            obj.maxFileSize     = 5*10^6;
            obj.sigma           = 0.35;
            obj.meanFileSize    = 14.45;
            obj.meanReadingTime = 180;
            obj.lambda = 0.006;

            %% set log normal distribution for file size
            distribution = makedist('Lognormal', 'mu', obj.meanFileSize, 'sigma', obj.sigma);
            truncDist    = truncate(distribution, obj.maxFileSize/10000, obj.maxFileSize);

            % set packet size in bits
            obj.packetSize = ceil(random(truncDist) * 8);

            %% set exponential distribution for reading time
            percentile   = 1/obj.lambda + 1/obj.lambda*10;
            distribution = makedist('Exponential', 'mu', obj.meanReadingTime);
            truncDist    = truncate(distribution, percentile/10000, percentile);

            % set reading time in msec, it is equal to
            % number of slots that are necessary for packet generation
            obj.numSlots = ceil(random(truncDist) * 1e3);

            % set initial time
            obj.initialTime = randi(obj.numSlots);

            % check parameters
            obj.checkParametersFTP;
        end

        function checkNewPacket(obj,iSlot)
            % check if new packet generation is necessary in the current slot
            %
            % input:
            %   iSlot: [1x1]double index of current slot

            checkNewPacket@trafficModels.PacketProcessing(obj,obj.packetSize,obj.numSlots,iSlot,obj.initialTime);
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

        function updateAfterTransmit(obj,sentBits,iSlot)
            % update data in buffer according to the user throughput
            %
            % input:
            %   sentBits:  [1x1]double number of transmitted bits in
            %                  current slot
            %   iSlot:     [1x1]double index of current slot

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

        function checkParametersFTP(obj)
            % check parameters compability

            if obj.maxFileSize ~= 5*10^6
                warning("FTP:MaxFileSizeCompatibility", ...
                    "Maximum file size must equal the default value.");
            end

            if obj.sigma ~= 0.35
                warning("FTP:FileSizeSigmaCompatibility", ...
                    "Standard deviation value of the log normal distribution must equal the default value.");
            end

            if obj.meanFileSize ~= 14.45
                warning("FTP:MeanFileSizeCompatibility", ...
                    "Mean of the log normal distribution must equal the default value.");
            end

            if obj.meanReadingTime ~= 180
                warning("FTP:MeanReadingTimeCompatibility", ...
                    "Mean of the exponential distribution must equal the default value.");
            end

            if obj.lambda ~= 0.006
                warning("FTP:LambdaCompatibility", ...
                    "Lambda of the exponential distribution must equal the default value.");
            end
        end
    end
end

