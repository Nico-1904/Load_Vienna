function [params] = basicLiteScenario(params)
% simple simulationscenario with lite simulation mode
% Creates a sceanrio with base stations position in rings of a hexagonal
% grid and Poisson point process distributed users and a large wall.
%
% see also launcherFiles.launcherLiteSimulation

%% General Configuration
params.time.slotsPerChunk = 10;

% postprocessing
params.postprocessor = simulation.postprocessing.LiteWithNetworkPP;

% define the region of interest & interference region
params.regionOfInterest.xSpan = 600;
params.regionOfInterest.ySpan = 600;
params.regionOfInterest.zSpan = 150;
params.regionOfInterest.interference = parameters.setting.Interference.regionIndependentUser;
params.regionOfInterest.interferenceRegionFactor = 1.5;

% path loss
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;
% set path loss models
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}    = parameters.pathlossParameters.UrbanMacro3D;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}   = parameters.pathlossParameters.UrbanMacro3D;
params.pathlossModelContainer.modelMap{macro,	outdoor,    LOS}    = parameters.pathlossParameters.UrbanMacro3D;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}   = parameters.pathlossParameters.UrbanMacro3D;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}.isIndoor = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}.isIndoor = true;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isIndoor = false;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isIndoor = false;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}.isLos = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}.isLos = false;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isLos = true;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isLos = false;

%% Netowrk Geometry
% wall
wall = parameters.wallBlockage.PredefinedPositions;
wall.cornerList = 200*[0,0,1,1,0; 0,0,1,1,0; 0,0.5,0.5,0,0];
wall.loss       = 10;
wall.positions  = [-250; -250; 0];
params.wallParameters('predefWall') = wall;

% base stations
hexRing = parameters.basestation.HexRing;
hexRing.interBSdistance = 150;
hexRing.nRing           = 3;
params.baseStationParameters('hexRing') = hexRing;

% users
poissonUsersSISO = parameters.user.Poisson2D;
poissonUsersSISO.density                    = 200e-6;
poissonUsersSISO.nRX                        = 1;
poissonUsersSISO.nTX                        = 1;
poissonUsersSISO.indoorDecision             = parameters.indoorDecision.Random(0.1);
poissonUsersSISO.losDecision                = parameters.losDecision.Geometry;
poissonUsersSISO.transmitPower              = 1;
poissonUsersSISO.channelModel               = parameters.setting.ChannelModel.TU;
params.userParameters('poissonUser')    = poissonUsersSISO;

% interference region users
interferenceUser = parameters.user.InterferenceRegion;
interferenceUser.nElements                          = 30;
interferenceUser.nRX                                = 1;
interferenceUser.nTX                                = 1;
interferenceUser.indoorDecision                     = parameters.indoorDecision.Random(0.5);
interferenceUser.losDecision                        = parameters.losDecision.Random;
interferenceUser.losDecision.losProbability         = 0.5;
interferenceUser.transmitPower                      = 1;
interferenceUser.channelModel                       = parameters.setting.ChannelModel.PedA;
params.userParameters('interferenceUser') = interferenceUser;
end

