classdef LocalSimulation < tools.HiddenHandle
    % LocalSimulation runs one simulation on the local machine
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.ParallelSimulation

    properties
        % simulation result object
        % [1x1]handleObject simulation.results.ResultsSuperclass
        simulationResult

        % simulation timer
        % [1x1]double starting time of simulation
        % see also tic
        simulationTimer

        % simulation setup object - creates network elements and checks parameters
        % [1x1]handleObject simulation.SimulationSetup
        simulationSetup

        % simulation parameters
        % [1x1]handleObject parameters.Parameters
        params

        % list of chunk simulations
        % [1 x nChunks]handleObject simulation.ChunkSimulation
        chunkSimulationList
    end

    methods
        function obj = LocalSimulation(params)
            % class constructor - sets and checks parameters

            % set parameters
            obj.params = params;
            % check parameters
            obj.params.checkParameters;
        end

        function setup(obj)
            % sets up the simulation
            % This function sets the simulation parameters, creates all
            % network elements and checks parameter compability.

            % start simulation timer
            obj.simulationTimer = tic;
            % creates SimulationSetup object and sets parameters
            obj.simulationSetup = simulation.SimulationSetup(obj.params);
            % creates network elements in the right order
            obj.simulationSetup.prepareSimulation();
            % checks parameter compability
            obj.simulationSetup.checkCompatibility();
        end

        function run(obj)
            % run simulations
            % Runs simulations for all chunks.

            % initialitze chunk result list
            chunkResultList(obj.params.time.numberOfChunks) = simulation.ChunkResult;

            % run simulation for each chunk
            for ii = 1:obj.params.time.numberOfChunks
                fprintf('simulating chunk %d...\n', ii);
                obj.chunkSimulationList = [obj.chunkSimulationList, simulation.ChunkSimulation(obj.simulationSetup.chunkConfigList(ii))];
                chunkResultList(ii) = obj.chunkSimulationList(ii).runSimulation();
            end

            % postprocessing of the results
            obj.simulationResult = obj.params.postprocessor.combineResults(chunkResultList);
            simTime =  toc(obj.simulationTimer);
            fprintf('Simulation done. (elapsed time: %d s)\n', simTime);
            obj.simulationResult.simulationTime = simTime;
        end
    end
end

