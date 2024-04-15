function [params] = basicScenario(params)
% simulation scenario with Poissin point proces distributed base stations and moving users
% This scenario file shows how to set up a scenario with three sector
% antennas that are distributed through a Poisson point process and moving
% users of the three different movement types. A building is set up in the
% simulation scenario.
% This scenario also shows how tpo set up chunks for parallelization of the
% simulation.
%
% input:
%   params: [1x1]handleObject parameters.Parameters
%
% output:
%   params: [1x1]handleObject parameters.Parameters
%
% initial author: Lukas Nagel
% extended by: Agnes Fastenbauer
%
% see also launcherFiles.launcherExample, parameters.Parameters

%% General Parameters
% time config
params.time.numberOfChunks              = 10;   % a sufficently large number of chunks to achieve paralleization gain
params.time.feedbackDelay               = 3;    % number of slots it takes for feedback to reach base station
params.time.slotsPerChunk               = 20;	% the first 3 slots in a chunk are discarded, since no feedback is available
params.time.timeBetweenChunksInSlots    = 100;	% the chunks should be independent

% set the carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2;    % in GHz
params.transmissionParameters.DL.bandwidthHz    = 5e6;  % in Hz

% disable HARQ - is not implemented for a feedback delay larger than 1
params.useHARQ = false;

% define the region of interest
params.regionOfInterest.xSpan = 500; % the ROI will go from -250 m to 250 m
params.regionOfInterest.ySpan = 500;
params.regionOfInterest.zSpan = 100; % make sure ROI is high enough to include all base stations
params.regionOfInterest.interferenceRegionFactor = 1.5; % add interference region with additional radius of 0.5 of the ROI
params.regionOfInterest.interference = parameters.setting.Interference.regionIndependentUser; % no users will be placed in the interference region

% set channel trace length
% This should be large enough to get independent channel realizations for
% all users.
params.smallScaleParameters.traceLengthSlots = 50000;

% save additional results for results plots
params.save.losMap      = true;
params.save.isIndoor    = true;

% set path loss model for each link type
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;
% set path loss models for macro base station
macro = parameters.setting.BaseStationType.macro; % only macro base stations are generated, so only these models need to be set
model = parameters.pathlossParameters.UrbanMacro5G;
model.isLos = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}    = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}   = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}    = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isLos = true; % use LOS version of path loss model
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}   = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isLos = false; % use LOS version of path loss model

%% building
% add a building to the scenario
building = parameters.building.PredefinedPositions;
building.floorPlan  = 40*[1,0,0,1,1; 0,0,1,1,0]; % build a closed building: 1st corner = last corner
building.height     = 15;
building.loss       = 20; % links going through walls will be affected by this loss (in dB)
building.positions  = [-50;-50]; % move center of buidling
params.buildingParameters('predefBuildings') = building;

%% Base Stations
poissonStations = parameters.basestation.Poisson2D;
poissonStations.density     = 10e-6; % 10 base station per km^6
poissonStations.nSectors    = 3; % generate all three sectors of the three sector base station
poissonStations.antenna     = parameters.basestation.antennas.ThreeSector;
poissonStations.antenna.nTX = 4;
params.baseStationParameters('PoissonBS') = poissonStations; % save base station in parameter list

%% Users with movement
% random walk
randomWalkUser = parameters.user.Poisson2D;
randomWalkUser.density              = 20e-6; % 20 users per km^2 - small for fast simulation
randomWalkUser.nRX                  = 2;
randomWalkUser.speed                = 500/3.6; % select high speed to see more movement
randomWalkUser.indoorDecision       = parameters.indoorDecision.Geometry; % decide depending on building
randomWalkUser.losDecision          = parameters.losDecision.UrbanMacro5G; % match random LOS decision with path loss model
randomWalkUser.userMovement.type    = parameters.setting.UserMovementType.ConstSpeedRandomWalk;
randomWalkUser.channelModel         = parameters.setting.ChannelModel.VehA;
params.userParameters('randomWalkUser') = randomWalkUser; % add user to parameter list

% moving into one direction at constant speed
randDirectionUser = parameters.user.Poisson2D;
randDirectionUser.density           = 20e-6; % 20 users per km^2 - small for fast simulation
randDirectionUser.nRX               = 2;
randDirectionUser.speed             = 500/3.6; % make user move fast to see movement
randDirectionUser.indoorDecision    = parameters.indoorDecision.Geometry;
randDirectionUser.losDecision       = parameters.losDecision.UrbanMacro5G; % match random LOS decision with path loss model
randDirectionUser.userMovement.type = parameters.setting.UserMovementType.RandConstDirection;	% choose movement type
randDirectionUser.channelModel      = parameters.setting.ChannelModel.VehA;
params.userParameters('randDirectionUser') = randDirectionUser; % add user to parameter list

% predefined position for each slot
% [3 x nSlotsTotal x nUser]double
positions = [(0:(params.time.nSlotsTotal-1))-100; ((0:params.time.nSlotsTotal-1))-100; 1.5*ones(1, params.time.nSlotsTotal)];
predefinedUser = parameters.user.PredefinedPositions;
predefinedUser.positions                    = [0; 0; 0]; % this position will be overwritten by the movement positions
predefinedUser.nRX                          = 2;
predefinedUser.speed                        = 500/3.6; % this speed will only affect the Doppler shift in the channel model
predefinedUser.indoorDecision               = parameters.indoorDecision.Geometry;
predefinedUser.losDecision                  = parameters.losDecision.UrbanMacro5G; % match random LOS decision with path loss model
predefinedUser.userMovement.type            = parameters.setting.UserMovementType.Predefined;
predefinedUser.userMovement.positionList    = positions;
predefinedUser.channelModel                 = parameters.setting.ChannelModel.VehB;
params.userParameters('predefinedMovementUser') = predefinedUser; % add user to parameter list
end

