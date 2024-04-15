classdef Time < tools.HiddenHandle
    % TIME parameters needed to define the timeline
    %   The time line is partitioned into chunks, segments and slots.
    %   A chunk is a (in the scenario file) defined number of time slots,
    % two chunks can be at different, non-consecutive moments in time. They
    % serve on one hand to only simulate time instants that are of interest
    % for the results (e.g. for bursts of user activity) and on the other
    % hand, the simulation can be parallelized over chunks.
    %   A segment is a number of consecutive time slots. Over the course of
    % a segment all large scale fading parameters (e.g. path loss, wall
    % loss, ...) stay constant. The segments are defined through the
    % maximum correlation parameters.Parameters.maximumCorrelationDistance.
    % If a user moves further than this distance, a new segment is started.
    %   A time slot is the shortest time unit considered in the simulation,
    % small scale fading parameters are assumed constant for the duration
    % of a time slot. Scheduling and post equalization SINR calculations
    % are performed for the time granularity of a slot.
    %
    % initial author: Lukas Nagel

    properties
        % overall time chunks to be simulated
        % [1x1]integer number of chunks simulated
        % This setting can be used to simulate only specific time instants
        % and this setting can be used to parallelize the simulation.
        %
        % see also parameters.Time.timeBetweenChunksInSlots,
        % parameters.setting.SimulationType.parallel
        numberOfChunks = 1;

        % duration of a slot in seconds
        % [1x1]double duration of a slot in seconds
        slotDuration = 1e-3;

        % each chunk consists of that many slots
        % [1x1]integer number of slots in a chunk
        %
        %NOTE: The default value is set to a small number of slots, so that
        %trying simulations settings leads to results quickly. For
        %meaningful simulations the number of slots has to be increased.
        %For long simulations also remember to increase the channel trace
        %length.
        %
        % see also parameters.SmallScaleParameters.traceLengthSlots
        slotsPerChunk = 10;

        % timespan between two simulated time chunks
        % [1x1]integer number of slots between two simulated chunks
        % This parmaeter can be set to 0 to simulate a continuous timeline,
        % or to a bigger value to simulate specific time instants.
        timeBetweenChunksInSlots = 50;

        % feedback delay in multiples of slots
        % [1x1]integer feedback delay in slots
        feedbackDelay = 3;
    end

    properties (Dependent)
        % total number of slots in the simulation
        % [1x1]integer total number of slots in simulation
        nSlotsTotal
    end

    methods
        function timeMatrix = generateTimeMatrix(obj)
            % generateTimeMatrix returns the timeline in matrix form
            % Returns a matrix that indicates the simulation time in
            % seconds for each slot in each chunk.
            %
            % output:
            %   timeMatrix: [numberOfChunks x slotsPerChunk]double with time in seconds
            %
            %NOTE: this is not in the class constructor, so that the
            %property values from the scenario file are used.

            % get time between two chunks in seconds
            timeBetweenChunks	= obj.slotDuration * obj.timeBetweenChunksInSlots;

            % create time matrix
            tmpTimeMatrix       = repmat( (0:obj.numberOfChunks-1).' * (timeBetweenChunks + obj.slotDuration * obj.slotsPerChunk), 1, obj.slotsPerChunk);
            timeMatrix          = tmpTimeMatrix + repmat((0:obj.slotsPerChunk-1)*obj.slotDuration, obj.numberOfChunks, 1);
        end

        function nSlotsTotal = get.nSlotsTotal(obj)
            % gets the total number of slots in simulation
            %
            % output:
            %   nSlotsTotal:    [1x1]integer total number of slots in the whole simulation

            % The total number of slots is the total number of chunks
            % multiplied with the number of slots per chunk.
            nSlotsTotal = obj.numberOfChunks * obj.slotsPerChunk;
        end

        function checkParameters(obj)
            % checks parameter compability
            % Checks if time is always positive and in general bigger than
            % zero.

            % check number of chunks
            if obj.numberOfChunks <= 0
                error('params:incompatible_parameters', 'At least one chunk has to be simulated.');
            end

            % check number of slots per chunk
            if obj.slotsPerChunk <= 0
                error('params:incompatible_parameters', 'At least one slot per chunk has to be simulated.');
            end

            % check number of slots per chunk
            if obj.slotDuration <= 0
                error('params:incompatible_parameters', 'The duration of a slot has to be strictly positive.');
            end

            % check feedback delay
            if obj.feedbackDelay <= 0
                error('params:incompatible_parameters', 'Feedback Delay must be > 0 at the moment.');
            end
        end
    end
end

