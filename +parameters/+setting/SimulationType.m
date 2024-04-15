classdef SimulationType
    %SIMULATIONTYPE possibilities to run simulation (local, parallel,...)
    % Indicates how the simulation is run, for exaple in parallel on
    % several cores, or local on the local machine.
    %
    % initial author: Lukas Nagel
    %
    % see also simulate, simulationLauncher

    enumeration
        % local simulation run on the local machine
        % The simulation is run on the local machine without
        % parallelization.
        local

        % parallel simulation run with parallelization on the local machine
        % The simulation is run on the local machine with parallelization.
        % This simulation mode uses the matlab Parallel Computing Toolbox.
        parallel
    end
end

