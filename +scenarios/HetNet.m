function params = HetNet(params)
% heterogeneous scenario consisting of various base station and user types
% Macro, pico, and femto base stations and pedestrian and car users are
% placed in the simulation region. The femto cells are favored for cell
% association adn NOMA is used for transmission. The macroscopic fading
% models are set individually for each link type. Indoor and LOS decisions
% for links are set per user type and PDP channel models are used for
% pedestrian and vehicular users and an AWGN channel is assumed for users
% in clusters around femto base stations. A weighted round robin scheduler
% favors vehicular users for scheduling.
%
% initial author: Fjolla Ademaj
%
% see also launcherFiles.launcherHetNet

%% General Configuration
% time config
params.time.slotsPerChunk = 10;
params.time.feedbackDelay = 1; % small feedback delay

% set NOMA parameters
params.noma.interferenceFactorSic	= 0; % no error propagation
params.noma.deltaPairdB             = 7;
params.noma.mustIdx                 = parameters.setting.MUSTIdx.Idx01;
% perform NOMA transmssion even if far user CQI is low - this will increase th number of failed transmissions
params.noma.abortLowCqi             = false;

% disable HARQ - not compatible with NOMA
params.useHARQ = false;

% define the region of interest & boundary region
params.regionOfInterest.xSpan = 300;
params.regionOfInterest.ySpan = 300;

% set carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2; % in GHz
params.transmissionParameters.DL.bandwidthHz    = 10e6; % in Hz

% associate users to cell with strongest receive power - favor femto cell association
params.cellAssociationStrategy                      = parameters.setting.CellAssociationStrategy.maxReceivePower;
params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 5];

% weighted round robin scheduler - scheduling weights are set at the user
params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;

% additional object that should be saved into simulation results
params.save.losMap          = true;
params.save.isIndoor        = true;

%% pathloss model container
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;
% macro base station models
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}    = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}   = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}    = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}   = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}.isLos = false;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isLos = false;
% pico base station models
pico = parameters.setting.BaseStationType.pico;
params.pathlossModelContainer.modelMap{pico,	indoor,     LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	indoor,     NLOS}   = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	NLOS}   = parameters.pathlossParameters.FreeSpace;
% femto base station models
femto = parameters.setting.BaseStationType.femto;
params.pathlossModelContainer.modelMap{femto,	indoor,     LOS}    =  parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,   indoor,     NLOS}   =  parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,	outdoor,    LOS}    = parameters.pathlossParameters.UrbanMicro5G;
params.pathlossModelContainer.modelMap{femto,	outdoor,	NLOS}   = parameters.pathlossParameters.UrbanMicro5G;
params.pathlossModelContainer.modelMap{femto,	outdoor,	LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{femto,	outdoor,	NLOS}.isLos = false;

%% Configuration of the Network Elements
% macro base stations
macroBS = parameters.basestation.HexGrid();
macroBS.interBSdistance         = 120;
macroBS.antenna                 = parameters.basestation.antennas.Omnidirectional;
macroBS.antenna.nTX             = 1;
macroBS.antenna.transmitPower   = 40;
macroBS.antenna.baseStationType = parameters.setting.BaseStationType.macro;
macroBS.antenna.height          = 25;
params.baseStationParameters('macro') = macroBS;

% pico base stations along a straight street
posPico    = [-145, -125, -100, -75, -50, -25, 0, 25, 50, 75, 100, 125, 145;...
    24, 36 ,24, 36, 24, 36, 24, 36, 24, 36, 24, 36, 24];
streetPicoBS = parameters.basestation.PredefinedPositions();
streetPicoBS.positions                  = posPico;
streetPicoBS.antenna                    = parameters.basestation.antennas.Omnidirectional;
streetPicoBS.antenna.nTX                = 1;
streetPicoBS.antenna.height             = 5;
streetPicoBS.antenna.baseStationType    = parameters.setting.BaseStationType.pico;
streetPicoBS.antenna.transmitPower      = 35;
params.baseStationParameters('pico') = streetPicoBS;

% clustered users with femto at cluster center
clusteredUser = parameters.user.UniformCluster;
clusteredUser.density           = 250e-6; % density of clusters
clusteredUser.clusterRadius     = 5;
clusteredUser.clusterDensity    = 10e-2; % density of users in a cluster
clusteredUser.nRX               = 1;
clusteredUser.speed             = 0; % static user
clusteredUser.userMovement.type	= parameters.setting.UserMovementType.ConstPosition;
clusteredUser.schedulingWeight  = 1; % do not favor this user type
clusteredUser.indoorDecision    = parameters.indoorDecision.Static(parameters.setting.Indoor.indoor);
clusteredUser.losDecision       = parameters.losDecision.UrbanMicro5G;
clusteredUser.channelModel      = parameters.setting.ChannelModel.AWGN;
clusteredUser.withFemto         = true;
clusteredUser.femtoParameters.antenna                   = parameters.basestation.antennas.Omnidirectional;
clusteredUser.femtoParameters.antenna.nTX               = 1;
clusteredUser.femtoParameters.antenna.height            = 1.5;
clusteredUser.femtoParameters.antenna.transmitPower     = 1;
clusteredUser.femtoParameters.antenna.baseStationType   = parameters.setting.BaseStationType.femto;
params.userParameters('clusterUser') = clusteredUser;

% pedestrian users
poissonPedestrians = parameters.user.Poisson2D();
poissonPedestrians.nElements            = 30; % number of users placed
poissonPedestrians.nRX                  = 1;
poissonPedestrians.speed                = 0; % static user
poissonPedestrians.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;
poissonPedestrians.schedulingWeight     = 10; % assign 10 resource blocks when scheduled
poissonPedestrians.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestrians.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestrians.channelModel         = parameters.setting.ChannelModel.PedA;
params.userParameters('poissonUserPedestrian') = poissonPedestrians;

% car user distributed through a Poisson point process
poissonCars                     = parameters.user.Poisson2D();
poissonCars.nElements           = 30;
poissonCars.nRX                 = 1;
poissonCars.speed               = 50;
poissonCars.userMovement.type   = parameters.setting.UserMovementType.RandConstDirection;
poissonCars.schedulingWeight    = 20; % assign 20 resource blocks when scheduled
poissonCars.indoorDecision      = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
poissonCars.losDecision         = parameters.losDecision.UrbanMacro5G;
poissonCars.channelModel        = parameters.setting.ChannelModel.VehB;
params.userParameters('poissonUserCar') = poissonCars;

% car users on the street served by pico base stations
width_y     = 8;
width_x     = 150;
nUser       = 30;
xRandom     =      width_x * rand(1, nUser) - width_x / 2;
yRandom     = 20 + width_y * rand(1, nUser) - width_y / 2;
posUser3    = [xRandom; yRandom; 1.5*ones(1,nUser)];
streetCars = parameters.user.PredefinedPositions();
streetCars.positions            = posUser3;
streetCars.nRX                  = 1;
streetCars.speed                = 100;
streetCars.userMovement.type    = parameters.setting.UserMovementType.RandConstDirection;
streetCars.schedulingWeight     = 20; % assign 20 resource blocks when scheduled
streetCars.indoorDecision       = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
streetCars.losDecision          = parameters.losDecision.Static;
streetCars.losDecision.isLos    = true;
streetCars.channelModel = parameters.setting.ChannelModel.VehA;
params.userParameters('vehicle')       = streetCars;
end

