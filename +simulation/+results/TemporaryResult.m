classdef TemporaryResult
    %TEMPORARYRESULT temporary slot results
    % In this class all simulation results of a slot are saved. This class
    % is handed to the postprocessor.createTraceResult, which selects the
    % desired results depending on the chosen postprocessor. The rest of
    % the slot results are discarded to save memory.
    %
    % initial author: Agnes Fastenbauer
    %
    % See also simulation.ChunkSimulation,
    % simulation.postprocessing.PostprocessorSuperclass

    properties
        % throughputUser - User Throughput
        % [nUser x 1]struct with throughput
        %	-DL:	[nUser x 1]double downlink throughput of each user
        %           %NOTE: this is empty, but still there if the user is a
        %           interference region user
        throughputUser

        % effectiveSinr - SINR used
        % [1x1]struct with up- and downlink effective SINR for each user
        %	-DL:    [nUser x 1]double
        effectiveSinr

        % preliminary downlink BLER
        % [nUser x 1]double downlink BLER for each user
        BLER

        %% additional results

        % feedback - Feedback
        % [1x1]struct with up- and downlink feedback for each user
        %	-DL:    [nUser x 1]cell
        feedback = 0;

        % userScheduling - Scheduler signaling at the user
        % [1x1]struct with up- and downlink scheduler signaling for each user
        %	-DL:    [nUser x 1]cell
        userScheduling = 0;
    end

    methods
        function obj = TemporaryResult(ChunkSimulationObject)
            %TEMPORARYRESULT initializes a temporary result for this ChunkSimulationObject
            %
            % input:
            %   ChunkSimulationObject:	[1x1]handleObject simulation.ChunkSimulation

            % initialize properties
            obj.BLER.DL                     = NaN(ChunkSimulationObject.nUsers, 1);
            obj.throughputUser.DL           = NaN(ChunkSimulationObject.nUsers, 1);
            obj.throughputUser.DLBestCQI    = NaN(ChunkSimulationObject.nUsers, 1);
            obj.effectiveSinr.DL            = NaN(ChunkSimulationObject.nUsers, 1);

            % feedback
            if ChunkSimulationObject.chunkConfig.params.save.feedback
                obj.feedback = struct;
                obj.feedback.DL = cell(ChunkSimulationObject.nUsers, 1);
            end

            % scheduler signaling
            if ChunkSimulationObject.chunkConfig.params.save.userScheduling
                obj.userScheduling = struct;
                obj.userScheduling.DL = cell(ChunkSimulationObject.nUsers, 1);
            end
        end

        function structResult = toStruct(obj)
            % write temporary result into struct
            %
            % output:
            %   structResult:   [1x1]struct with class properties as field
            %
            % see also simulation.results.TemporaryResult

            % create struct and fill with property values
            structResult = struct;
            structResult.throughputUser = obj.throughputUser;
            structResult.effectiveSinr  = obj.effectiveSinr;
            structResult.BLER           = obj.BLER;
            structResult.feedback       = obj.feedback;
            structResult.userScheduling = obj.userScheduling;
        end

        function obj = setTemporarySlotResult(obj, ChunkSimulationObject)
            %setTemporarySlotResult sets the temporary result for this slot for all users
            % Copies the results from this slot in
            % simulation.ChunkSimuation.runSimulation to the temporary
            % results.
            %
            % input:
            %   ChunkSimulationObject:	[1x1]handleObject simulation.ChunkSimulation

            % get necessary parameters
            feedbackDelay	= ChunkSimulationObject.chunkConfig.params.time.feedbackDelay;

            % set result for this slot for all users
            for iUE = 1:ChunkSimulationObject.nUsers
                % save feedback (additional result)
                if ChunkSimulationObject.chunkConfig.params.save.feedback
                    obj.feedback.DL{iUE} = ChunkSimulationObject.users(iUE).userFeedback.DL.getFeedback(feedbackDelay).toStruct;
                end

                % save userScheduling (additional result)
                if ChunkSimulationObject.chunkConfig.params.save.userScheduling
                    obj.userScheduling.DL{iUE}	= ChunkSimulationObject.users(iUE).scheduling.toStruct;
                end
            end % for all users
        end
    end
end

