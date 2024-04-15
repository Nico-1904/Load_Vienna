function params = simulationTime(params, nChunks, nSlotsPerChunk, nUsers, bandwidthHz, postprocessor, nAnt)
%SIMULATIONTIME Scenario to show influence of different parameters on simulation duration
%
% input:
%   params:         [1x1]handleObject parameters.Parameters
%   nChunks:        [1x1]integer number of chunks
%   nSlotsPerChunk: [1x1]integer number of slots per chunk
%   nUsers:         [1x1]integer number of users, also 10*nBaseStations
%   bandwidthHz:    [1x1]integer bandwidth in Hertz
%   postprocessor:  [1x1]handleObject simulation.postprcessing.PostProcessorSuperclass
%
% initial author: Agnes Fastenbauer
%
% see also launcherFiles.launcherSimulationTime

%% time
params.time.numberOfChunks	= nChunks;
params.time.slotsPerChunk	= nSlotsPerChunk;

%% users

% add user with movement to set a fixed number of segments
positions = repmat([repmat([0;0;1.5], 1, nSlotsPerChunk/2), repmat([10;10;1.5], 1, nSlotsPerChunk/2)], 1, nChunks);
movingPredefinedUsers = parameters.user.PredefinedPositions();
movingPredefinedUsers.nRX = nAnt;
movingPredefinedUsers.channelModel              = parameters.setting.ChannelModel.PedA;
movingPredefinedUsers.positions                 = [0; 0; 0];                                %NOTE: this position will be overwritten by the movement positions
movingPredefinedUsers.userMovement.type         = parameters.setting.UserMovementType.Predefined;	% choose movement type
movingPredefinedUsers.userMovement.positionList	= positions;                                % predefined positions: [3 x nSlotsTotal x nUser]double
movingPredefinedUsers.trafficModelType          = parameters.setting.TrafficModelType.FullBuffer;
params.userParameters('predefinedMovementUser') = movingPredefinedUsers;

% add randomly distributed users
poissonUsers = parameters.user.Poisson2D();
poissonUsers.nElements              = nUsers - 1; % one user has predefined positions
poissonUsers.nRX                    = nAnt;
poissonUsers.userMovement.type      = parameters.setting.UserMovementType.ConstPosition;
poissonUsers.channelModel           = parameters.setting.ChannelModel.PedA;
poissonUsers.trafficModelType       = parameters.setting.TrafficModelType.FullBuffer;
params.userParameters('poissonUser') = poissonUsers;


%% base stations
nBaseStation = nUsers/10;
antennaOmni = parameters.basestation.antennas.Omnidirectional;
antennaOmni.nTX	= nAnt;
poissonBS = parameters.basestation.Poisson2D;
poissonBS.nElements	= nBaseStation;
poissonBS.antenna	= antennaOmni;
params.baseStationParameters('poissonBS') = poissonBS;

%% transmission parameters
params.transmissionParameters.DL.bandwidthHz = bandwidthHz;
params.transmissionParameters.DL.txModeIndex = nAnt;

%% postprocessor
params.postprocessor = postprocessor;

%% maximum correlation distance - set by moving user such that we have 2 segments per chunk
params.maximumCorrelationDistance = 1;

end

