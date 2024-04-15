classdef ParallelSimulation < tools.HiddenHandle
    % ParallelSimulation runs parallelsized
    % This class runs the simulation for each chunk in a parallel loop.
    % Using this requires the Parallel Computing Toolbox
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.LocalSimulation

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
    end

    methods
        function obj = ParallelSimulation(params)
            % class constructor - sets and checks parameters

            % set parameters
            obj.params = params;
            % check parameters
            obj.params.checkParameters();
        end

        function setup(obj)
            % sets up the simulation
            % This function sets the simulation parameters, creates all
            % network elements and checks parameter compatability.

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
            % run simulations in a parrallel loop
            % This function prepares a list of chunk simulation, then runs
            % the simulation for each chunk in a parfor loop and then
            % processes the results of the chunk simulations.

            % prepare chunk simulation list
            chunkSimulationList = [];
            for ii = 1:obj.params.time.numberOfChunks
                chunkSimulationList = [chunkSimulationList, simulation.ChunkSimulation(obj.simulationSetup.chunkConfigList(ii))];
            end

            % run simulations for all chunks
            parfor ii = 1:obj.params.time.numberOfChunks
                fprintf('simulating chunk %d...\n', ii);
                % run chunk simulation
                chunkResultList(ii) = chunkSimulationList(ii).runSimulation();
            end

            % postprocessing of the results
            obj.simulationResult = obj.params.postprocessor.combineResults(chunkResultList);
            fprintf('Simulation done. (elapsed time: %d s)\n', toc(obj.simulationTimer));
        end
    end
end

