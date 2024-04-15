classdef VideoStreaming < trafficModels.PacketProcessing
    %VideoStreaming Class for video streaming traffic simulation.
    % Each frame of video data arrives at a regular interval.
    % The frame is decomposed into number of slices (packets). The video
    % encoder introduces inter-arrival times between the
    % slices of a frame
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing
    % networkElements.ue.User
    % parameters.user.Parameters

    properties
        % maximum slice size
        % [1x1]double upper truncation value of Pareto distribution
        % of slice size in bytes
        maxSlice

        % minimum slice size
        % [1x1]double scale parameter of Pareto distribution
        % of slice size in bytes
        minSlice

        % alpha of the truncated Pareto distribution
        % [1x1]double shape parameter of slice size distribution
        alpha_Slice

        % slice size
        % [1x1]double slice size in bits
        sliceSize

        % maximum inter-arrival time
        % [1x1]double upper truncation value of Pareto distribution
        % of inter-arrival time between slices in seconds
        maxArrivalTime

        % minimum inter-arrival time
        % [1x1]double scale parameter of Pareto distribution
        % of inter-arrival time between slices in seconds
        minArrivalTime

        % alpha of the truncated Pareto distribution
        % [1x1]double shape parameter of the distribution of inter-arrival
        % time between slices
        alpha_ArrivalTime

        % inter-arrival time
        % [1x1]double inter-arrival time between slices in a frame in milliseconds
        interArrivalTime

        % inter-arrival time between frames
        % [1x1]double inter-arrival time between the beginning of each
        % frame in milliseconds
        timeBetweenFrames

        % initial time
        % [1x1]double random initial time for first slice generation
        initialTime

        % number of slices
        % [1x1]double number of slices in a frame
        nSlices
    end

    methods
        function obj = VideoStreaming()
            % class constructor

            % call superclass constructor
            obj = obj@trafficModels.PacketProcessing();

            % set parameters
            obj.maxSlice          = 250;
            obj.minSlice          = 20;
            obj.alpha_Slice       = 1.2;
            obj.maxArrivalTime    = 12.5e-3;
            obj.minArrivalTime    = 2.5e-3;
            obj.alpha_ArrivalTime = 1.2;
            obj.timeBetweenFrames = 100;
            obj.nSlices           = 8;

            %% set Pareto distribution for slice size
            distribution = makedist('GeneralizedPareto', 'k', 1/obj.alpha_Slice , 'sigma', obj.minSlice/obj.alpha_Slice , 'theta', obj.minSlice);
            truncDist    = truncate(distribution, obj.minSlice, obj.maxSlice);

            % set slice size in bits
            obj.sliceSize = ceil(random(truncDist) * 8);

            %% set Pareto distribution for the inter-arrival time between slices in a frame
            distribution = makedist('GeneralizedPareto', 'k', 1/obj.alpha_ArrivalTime , 'sigma', obj.minArrivalTime/obj.alpha_ArrivalTime , 'theta', obj.minArrivalTime);
            truncDist    = truncate(distribution, obj.minArrivalTime, obj.maxArrivalTime);

            % set inter-arrival time in msec
            obj.interArrivalTime = ceil(random(truncDist) * 1e3);

            % set initial time
            obj.initialTime = randi(obj.timeBetweenFrames);

            % check parameters
            obj.checkParametersVideo;
        end

        function checkNewPacket(obj,iSlot)
            % check if new packet generation is necessary in the current slot
            %
            % input:
            %   iSlot:               [1x1]double index of current slot

            % generate first slice in a frame
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, obj.initialTime);

            % set initial times for other slices generation
            nextSliceTime = zeros(1,obj.nSlices-1);
            for ii = 1 : obj.nSlices-1
                nextSliceTime(ii) = obj.initialTime + (obj.interArrivalTime * ii);
            end

            % generate other slices in a frame
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(1));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(2));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(3));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(4));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(5));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(6));
            checkNewPacket@trafficModels.PacketProcessing(obj,obj.sliceSize, obj.timeBetweenFrames, iSlot, nextSliceTime(7));
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

        function checkParametersVideo(obj)
            % check parameters compability

            if obj.maxSlice ~=  250
                warning("VIDEO:MaxSliceCompatibility", ...
                    "Maximum slice size must equal the default value.");
            end

            if obj.minSlice ~=  20
                warning("VIDEO:MinSliceCompatibility", ...
                    "Minimum slice size must equal the default value.");
            end

            if obj.alpha_Slice ~= 1.2
                warning("VIDEO:AlphaCompatibility", ...
                    "Shape parameter of the Pareto distribution must equal the default value.");
            end

            if obj.maxArrivalTime ~= 12.5e-3
                warning("VIDEO:MaxArrivalCompatibility", ...
                    "Maximum inter-arrival time between slices must equal the default value.");
            end

            if obj.minArrivalTime ~= 2.5e-3
                warning("VIDEO:MinArrivalCompatibility", ...
                    "Minimum inter-arrival time between slices must equal the default value.");
            end

            if obj.alpha_ArrivalTime ~= 1.2
                warning("VIDEO:AlphaCompatibility", ...
                    "Shape parameter of the Pareto distribution must equal the default value.");
            end

            if obj.timeBetweenFrames ~= 100
                warning("VIDEO:FramesTimeCompatibility", ...
                    "Time between frames must equal the default value.");
            end

            if obj.nSlices ~= 8
                warning("VIDEO:NoSlicesCompatibility", ...
                    "Number of slices in a frame must equal the default value.");
            end
        end
    end
end

