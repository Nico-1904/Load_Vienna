classdef HTTP < trafficModels.PacketProcessing
    %HTTP Class for web-browsing using Hypertext Transfer
    % Protocol. A web-page consists of a main object and embedded
    % objects. The time that the user spends reading the web-page
    % before transitioning to another page is called reading time
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing
    % networkElements.ue.User
    % parameters.user.Parameters

    properties
        % maximum main file size
        % [1x1]double maximum main file size in bytes
        % which indicates upper truncation value for
        % log normal distribution
        maxMainFile

        % minimum main file size
        % [1x1]double minimum main file size in bytes
        % which indicates lower truncation value for
        % log normal distribution
        minMainFile

        % sigma of the truncated log normal distribution
        % [1x1]double standard deviation value of main file size distribution
        sigmaMainFile

        % mean of the truncated log normal distribution
        % [1x1]double mean value of main file size distribution
        meanMainFile

        % maximum embedded file size
        % [1x1]double maximum embedded file size in bytes
        % which indicates upper truncation value for
        % log normal distribution
        maxEmbFile

        % mninimum embedded file size
        % [1x1]double minimum embedded file size in bytes
        % which indicates lower truncation value for
        % log normal distribution
        minEmbFile

        % sigma of the truncated log normal distribution
        % [1x1]double standard deviation value of embedded file size distribution
        sigmaEmbFile

        % mean of the truncated log normal distribution
        % [1x1]double mean value of embedded file size distribution
        meanEmbFile

        % mean of the exponential distribution
        % [1x1]double mean value of reading time distribution in
        % seconds
        meanReadingTime

        % lambda of the exponential distribution
        % [1x1]double lambda value of reading time distribution
        lambda

        % k of the truncated Pareto distribution
        % [1x1]double scale parameter of number of embedded files distribution
        k

        % alpha of the truncated Pareto distribution
        % [1x1]double shape parameter of number of embedded files distribution
        alpha

        % m of the truncated Pareto distribution
        % [1x1]double upper truncation value of the distribution of number of embedded files
        m

        % main packet size
        % [1x1]double main packet size in bits
        mainPacketSize

        % embedded packet size
        % [1x1]double embedded packet size in bits
        embPacketSize

        % Number of embedded files
        % [1x1]double embedded files number per web-page
        nEmbFiles

        % number of slots for main file generation
        % [1x1]double number of slots necessary to generate new main packet
        mainNoSlots

        % initial time for main file
        % [1x1]double random initial time for main file generation
        mainInitialTime
    end

    methods
        function obj = HTTP()
            % class constructor

            % call superclass constructor
            obj = obj@trafficModels.PacketProcessing();

            % set parameters
            obj.maxMainFile          = 2*10^6;
            obj.minMainFile          = 100;
            obj.sigmaMainFile        = 1.37;
            obj.meanMainFile         = 8.37;
            obj.maxEmbFile           = 2*10^6;
            obj.minEmbFile           = 50;
            obj.sigmaEmbFile         = 2.36;
            obj.meanEmbFile          = 6.17;
            obj.meanReadingTime      = 30;
            obj.m                    = 55;
            obj.alpha                = 1.1;
            obj.k                    = 2;
            obj.lambda = .033;

            %% set log normal distribution for main file size
            distribution = makedist('Lognormal', 'mu', obj.meanMainFile, 'sigma', obj.sigmaMainFile);
            truncDist    = truncate(distribution, obj.minMainFile, obj.maxMainFile);

            % set main packet size in bits
            obj.mainPacketSize = ceil(random(truncDist) * 8);

            %% set log normal distribution for embedded file size
            distribution = makedist('Lognormal', 'mu', obj.meanEmbFile, 'sigma', obj.sigmaEmbFile);
            truncDist    = truncate(distribution, obj.minEmbFile, obj.maxEmbFile);

            % set embedded packet size in bits
            obj.embPacketSize = ceil(random(truncDist) * 8);

            %% set Pareto distribution for number of embedded files per web-page
            distribution = makedist('GeneralizedPareto', 'k', 1/obj.alpha, 'sigma', obj.k/obj.alpha, 'theta', obj.k);
            truncDist    = truncate(distribution, obj.k, obj.m);

            % set number of embedded files
            obj.nEmbFiles = random(truncDist);

            %% set exponential distribution for reading time
            percentile   = 1/obj.lambda + 1/obj.lambda*10;
            distribution = makedist('Exponential', 'mu', obj.meanReadingTime);
            truncDist    = truncate(distribution, percentile/10000, percentile);

            % set reading time in msec, it is equal to
            % number of slots that are necessary for packet generation
            obj.mainNoSlots = ceil(random(truncDist) * 1e3);

            % set initial time
            obj.mainInitialTime = randi(obj.mainNoSlots);

            % check parameters
            obj.checkParametersHTTP;
        end

        function checkNewPacket(obj,iSlot)
            % check if new packet generation is necessary in the current slot
            %
            % input:
            %   iSlot:               [1x1]double index of current slot

            % generate main packet
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.mainPacketSize, obj.mainNoSlots, iSlot, obj.mainInitialTime);

            % set parameters
            embNoSlots     = 0;
            embInitialTime = iSlot;

            % generate embedded packets
            if iSlot == obj.mainInitialTime || ~mod(iSlot-obj.mainInitialTime, obj.mainNoSlots)
                if obj.nEmbFiles > 0
                    for ii = 1 : obj.nEmbFiles
                        checkNewPacket@trafficModels.PacketProcessing(obj,obj.embPacketSize, embNoSlots, iSlot, embInitialTime);
                    end
                end
            end
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

        function checkParametersHTTP(obj)
            % check parameters compability

            if obj.maxMainFile ~= 2*10^6
                warning("HTTP:MaxMainFileCompatibility", ...
                    "Maximum main file size must equal the default value.");
            end

            if obj.minMainFile ~= 100
                warning("HTTP:MinMainFileCompatibility", ...
                    "Minimum main file size must equal the default value.");
            end

            if obj.maxEmbFile ~= 2*10^6
                warning("HTTP:MaxEmbFileCompatibility", ...
                    "Maximum embedded file size must equal the default value.");
            end

            if obj.minEmbFile ~= 50
                warning("HTTP:MinEmbFileCompatibility", ...
                    "Minimum embedded file size must equal the default value.");
            end

            if obj.sigmaMainFile ~= 1.37
                warning("HTTP:MainFileSigmaCompatibility", ...
                    "Standard deviation of the log normal distribution of main file must equal the default value.");
            end

            if obj.sigmaEmbFile ~= 2.36
                warning("HTTP:EmbFileSigmaCompatibility", ...
                    "Standard deviation of the log normal distribution of embedded file must equal the default value.");
            end

            if obj.meanMainFile ~= 8.37
                warning("HTTP:MeanMainFileCompatibility", ...
                    "Mean of the log normal distribution of main file must equal the default value.");
            end

            if obj.meanEmbFile ~= 6.17
                warning("HTTP:MeanEmbFileCompatibility", ...
                    "Mean of the log normal distribution of embedded file must equal the default value.");
            end

            if obj.meanReadingTime ~= 30
                warning("HTTP:MeanReadingTimeCompatibility", ...
                    "Mean of the exponential distribution must equal the default value.");
            end

            if obj.lambda ~= 0.033
                warning("HTTP:LambdaCompatibility", ...
                    "Lambda of the exponential distribution must equal the default value.");
            end

            if obj.k ~= 2
                warning("HTTP:k_Compatibility", ...
                    "Scale parameter of the Pareto distribution must equal the default value.");
            end

            if obj.m ~= 55
                warning("HTTP:m_Compatibility", ...
                    "Upper truncation value of the Pareto distribution must equal the default value.");
            end

            if obj.alpha ~= 1.1
                warning("HTTP:AlphaCompatibility", ...
                    "Shape parameter of the Pareto distribution must equal the default value.");
            end
        end
    end
end

