function params = Custom(params)

%% General Configuration
% time config
params.time.slotsPerChunk = 10;
params.time.feedbackDelay = 1; % small feedback delay

% disable HARQ - not compatible with NOMA
%params.useHARQ = false;

% define the region of interest & boundary region
params.regionOfInterest.xSpan = 350;
params.regionOfInterest.ySpan = 800;

% set carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2; % in GHz
params.transmissionParameters.DL.bandwidthHz    = 20e6; % in Hz

% associate users to cell with strongest receive power - favor femto cell association
params.cellAssociationStrategy                      = parameters.setting.CellAssociationStrategy.maxReceivePower;
%params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 2];

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

posMacro    = [-150, 0, 150, -150, 0, 150, -150, 0, 150;...
    200, 200 , 200, 0, 0, 0, -200, -200, -200];

macroBS = parameters.basestation.PredefinedPositions();
macroBS.positions                  = posMacro;
macroBS.antenna                    = parameters.basestation.antennas.ThreeSector;
macroBS.antenna.nTX                = 2;
macroBS.antenna.nRX                = 2;
macroBS.antenna.height             = 30;
macroBS.antenna.baseStationType    = parameters.setting.BaseStationType.macro;
macroBS.antenna.transmitPower      = 40;
params.baseStationParameters('macro') = macroBS;

% femto base stations
posFemto    = [-175, -125, -25, 25, 125, 175, -175, -125, -25, 25, 125, 175, -175, -125, -25, 25, 125, 175;...
    225, 175 , 225, 175, 225, 175, 25, -25, 25, -25, 25, -25, -175, -225, -175, -225, -175, -225];

% posFemto    = [-123, -125, -100, -29, -50, -25, 0, 25, 65, 75, 100, 125, 145, -20, 120, 60, 64, -40;...
%     121, 36 ,-100, 130, -30, 60, 24, 100, -120, 0, -35, 140, 24, -120, -70, -43, 94, -46];
femtoBS = parameters.basestation.PredefinedPositions();
femtoBS.positions                  = posFemto;
femtoBS.antenna                    = parameters.basestation.antennas.Omnidirectional;
femtoBS.antenna.nTX                = 2;
femtoBS.antenna.nRX                = 2;
femtoBS.antenna.height             = 5;
femtoBS.antenna.baseStationType    = parameters.setting.BaseStationType.femto;
femtoBS.antenna.transmitPower      = 1;
params.baseStationParameters('femto') = femtoBS;


% pedestrian users
% poissonPedestrians = parameters.user.Poisson2D();
% poissonPedestrians.nElements            = 90; % number of users placed
% poissonPedestrians.nRX                  = 2;
% poissonPedestrians.speed                = 0; % static user
% poissonPedestrians.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;
% poissonPedestrians.trafficModelType     = parameters.setting.TrafficModelType.FullBuffer;
% poissonPedestrians.schedulingWeight     = 10; % assign 10 resource blocks when scheduled
% poissonPedestrians.indoorDecision       = parameters.indoorDecision.Random(0.5);
% poissonPedestrians.losDecision          = parameters.losDecision.UrbanMacro5G;
% poissonPedestrians.channelModel         = parameters.setting.ChannelModel.PedA;
% params.userParameters('poissonUserPedestrian') = poissonPedestrians;
% 
% %user no served
% poissonNoUser = parameters.user.Poisson2D();
% poissonNoUser.nElements            = 180; % number of users placed
% poissonNoUser.nRX                  = 2;
% poissonNoUser.speed                = 0; % static user
% poissonNoUser.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;
% poissonPedestrians.trafficModelType = parameters.setting.TrafficModelType.FullBuffer;
% poissonNoUser.schedulingWeight     = 10; % assign 10 resource blocks when scheduled
% poissonNoUser.indoorDecision       = parameters.indoorDecision.Random(0.5);
% poissonNoUser.losDecision          = parameters.losDecision.UrbanMacro5G;
% poissonNoUser.channelModel         = parameters.setting.ChannelModel.PedA;
% params.userParameters('poissonUserNoServed') = poissonNoUser;

%user fixed1
poissonNoUser = parameters.user.PredefinedPositions();

seed = 42;
rng(seed);
nombreDePoints = 270;
plageX = 175;
plageY = 400;
valeurZ = 1.5;
coordonnees = rand(3, nombreDePoints);
coordonnees(1, :) = (coordonnees(1, :) - 0.5) * 2 * plageX;
coordonnees(2, :) = (coordonnees(2, :) - 0.5) * 2 * plageY;
coordonnees(3, :) = ones(1, nombreDePoints) * valeurZ;
posUser = coordonnees;
% posUser    = [-172, -165, -158, -137, -124, -151, -142, -109, -110, -92, -84, -130, 125, 175, -175, -125, -25, 25, 125, 175, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2;...
%     276, 190 , 186, 179, 273, 279, 210, 194, 153, 170, 178, 196, 25, -25, -175, -225, -175, -225, -175, -225, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];

poissonNoUser.positions            = posUser;
poissonNoUser.nRX                  = 1;
poissonNoUser.speed                = 0; % static user
poissonNoUser.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;
poissonNoUser.rxNoiseFiguredB   	= 9;   
poissonNoUser.trafficModelType = parameters.setting.TrafficModelType.FullBuffer;
poissonNoUser.schedulingWeight     = 100; % assign 10 resource blocks when scheduled
poissonNoUser.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonNoUser.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonNoUser.channelModel         = parameters.setting.ChannelModel.PedA;
params.userParameters('poissonUserFixed') = poissonNoUser;

% car user distributed through a Poisson point process

% car users on the street served by pico base stations

end

