%% Simulation Time Launcher File
% launches a simulations with different parametrizations and saves the simulation time
% This launcher file sets different parameters to show their influence on
% the simulation time.
%
% initial author: Agnes Fastenbauer
%
% see also scenarios.simulationTime, simulation.results

% clear working space and close all figures
close all
clear all
clc

%% SISO %%
nAnt = 1;

%% 1 Baseline Scenario
disp('---------------- Start SISO Baseline Scenario 1 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;                                % {5, 10}
nSlotsPerChunk	= 20;                               % {20, 200, 10, 100}
nUsers          = 100;                              % {100, 1000}
bandwidthHz     = 3e6;                              % {3e6, 20e6, 100e6}
postprocessor	= simulation.postprocessing.FullPP;	% {simulation.postprocessing.FullPP, simulation.postprocessing.LiteNoNetwork}

resultBaseline = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Baseline Scenario 1 -----------------');


%% 2 Baseline Lite Scenario
disp('---------------- Start SISO Baseline Lite Scenario 2 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultBaselineLite = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Baseline Lite Scenario 2 -----------------');


%% 3 Large Scenario
disp('---------------- Start SISO Large Scenario 3 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                             % more users and base stations
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLarge = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Large Scenario 3 -----------------');


%% 4 Large Parallel Scenario
disp('---------------- Start SISO Large Parallel Scenario 4 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;	% lite simulation

resultLargeParallel = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Large Parallel Scenario 4 -----------------');


%% 5 Large Lite Scenario
disp('---------------- Start SISO Large Lite Scenario 5 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultLargeLite = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Large Lite Scenario 5 -----------------');


%% 6 Large Lite Parallel Scenario
disp('---------------- Start SISO Large Lite Parallel Scenario 6 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultLargeLiteParallel = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Large Lite Parallel Scenario 6 -----------------');


%% 7 Long Scenario
disp('---------------- Start SISO Long Scenario 7 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 200;                              % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLong = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Long Scenario 7 -----------------');


%% 8 Long Parallel Scenario
disp('---------------- Start SISO Long Parallel Scenario 8 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;	% parallel simulation
nChunks         = 5;
nSlotsPerChunk	= 200;                                          % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLongParallel = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Long Parallel Scenario 8 -----------------');


% 9 Long Chunks Scenario
disp('---------------- Start SISO Long Chunks Scenario 9 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 10;
nSlotsPerChunk	= 100;                                          % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;	% lite simulation

resultLongLite = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Long Chunks Scenario 9 -----------------');


%% 10 Long Chunks Parallel Scenario
disp('---------------- Start SISO Long Chunks Parallel Scenario 10 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 10;                                % more chunks
nSlotsPerChunk	= 100;                               % fewer slots per chunk, but still many slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLongMoreChunks = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO Long Chunks Parallel Scenario 10 -----------------');


%% 11 20 MHz Bandwidth Scenario
disp('---------------- Start SISO 20 MHz Bandwidth Scenario 11 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 20e6;                              % more bandwidth
postprocessor	= simulation.postprocessing.FullPP;

result20MhzBandwidth = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO 20 MHz Bandwidth Scenario 11 -----------------');


%% 12 20 MHz Bandwidth Scenario
disp('---------------- Start SISO 100 MHz Bandwidth Scenario 12 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 100e6;                            % more bandwidth
postprocessor	= simulation.postprocessing.FullPP;

result100MhzBandwidth = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End SISO 100 MHz Bandwidth Scenario 12 -----------------');

%% MIMO %%
nAnt = 4;

%% 1 Baseline Scenario
disp('---------------- Start MIMO Baseline Scenario 1 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;                                % {5, 10}
nSlotsPerChunk	= 20;                               % {20, 200, 10, 100}
nUsers          = 100;                              % {100, 1000}
bandwidthHz     = 3e6;                              % {3e6, 20e6, 100e6}
postprocessor	= simulation.postprocessing.FullPP;	% {simulation.postprocessing.FullPP, simulation.postprocessing.LiteNoNetwork}

resultBaselineMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Baseline Scenario 1 -----------------');


%% 2 Baseline Lite Scenario
disp('---------------- Start MIMO Baseline Lite Scenario 2 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultBaselineLiteMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Baseline Lite Scenario 2 -----------------');


%% 3 Large Scenario
disp('---------------- Start MIMO Large Scenario 3 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                             % more users and base stations
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLargeMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Large Scenario 3 -----------------');



%% 4 Large Parallel Scenario
disp('---------------- Start MIMO Large Parallel Scenario 4 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;	% lite simulation

resultLargeParallelMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Large Parallel Scenario 4 -----------------');


%% 5 Large Lite Scenario
disp('---------------- Start MIMO Large Lite Scenario 5 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultLargeLiteMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Large Lite Scenario 5 -----------------');


%% 6 Large Lite Parallel Scenario
disp('---------------- Start MIMO Large Lite Parallel Scenario 6 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 1000;                                         % more users
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.LiteNoNetworkPP;	% lite simulation

resultLargeLiteParallelMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Large Lite Parallel Scenario 6 -----------------');


%% 7 Long Scenario
disp('---------------- Start MIMO Long Scenario 7 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 200;                              % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLongMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Long Scenario 7 -----------------');


%% 8 Long Parallel Scenario
disp('---------------- Start MIMO Long Parallel Scenario 8 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;	% parallel simulation
nChunks         = 5;
nSlotsPerChunk	= 200;                                          % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLongParallelMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Long Parallel Scenario 8 -----------------');


%% 9 Long Chunks Scenario
disp('---------------- Start MIMO Long Chunks Scenario 9 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 10;
nSlotsPerChunk	= 100;                                          % more slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;	% lite simulation

resultLongLiteMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Long Chunks Scenario 9 -----------------');


%% 11 Long Chunks Parallel Scenario
disp('---------------- Start MIMO Long Chunks Parallel Scenario 10 ----------------');

simulationType	= parameters.setting.SimulationType.parallel;
nChunks         = 10;                                % more chunks
nSlotsPerChunk	= 100;                               % fewer slots per chunk, but still many slots
nUsers          = 100;
bandwidthHz     = 3e6;
postprocessor	= simulation.postprocessing.FullPP;

resultLongMoreChunksMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO Long Chunks Parallel Scenario 10 -----------------');


%% 11 20 MHz Bandwidth Scenario
disp('---------------- Start MIMO 20 MHz Bandwidth Scenario 11 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 20e6;                              % more bandwidth
postprocessor	= simulation.postprocessing.FullPP;

result20MhzBandwidthMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO 20 MHz Bandwidth Scenario 11 -----------------');


%% 12 20 MHz Bandwidth Scenario
disp('---------------- Start MIMO 100 MHz Bandwidth Scenario 12 ----------------');

simulationType	= parameters.setting.SimulationType.local;
nChunks         = 5;
nSlotsPerChunk	= 20;
nUsers          = 100;
bandwidthHz     = 100e6;                            % more bandwidth
postprocessor	= simulation.postprocessing.FullPP;

result100MhzBandwidthMIMO = simulate(@(params)scenarios.simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt), simulationType);

disp('----------------- End MIMO 100 MHz Bandwidth Scenario 12 -----------------');


