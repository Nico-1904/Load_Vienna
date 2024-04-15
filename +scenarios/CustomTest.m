function params = CustomTest(params)

%% General Configuration
% time config
params.time.slotsPerChunk = 10;
params.time.feedbackDelay = 1; % small feedback delay

% define the region of interest & boundary region
params.regionOfInterest.xSpan = 400;
params.regionOfInterest.ySpan = 800;

% set carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2; % in GHz
params.transmissionParameters.DL.bandwidthHz    = 20e6; % in Hz

% associate users to cell with strongest receive power - favor femto cell association
params.cellAssociationStrategy                      = parameters.setting.CellAssociationStrategy.maxReceivePower;
%params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 2];

% weighted round robin scheduler - scheduling weights are set at the user
params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;

% precoderLteDL = parameters.precoders.LteDL;
% precoderTechnology = parameters.precoders.Technology();
% precoderTechnology.setTechPrecoder(parameters.setting.NetworkElementTechnology.LTE,     precoderLteDL);

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

posMacro    = [-100, 0, 0, 100;...
                100, 50, -100, -50];
%             posMacro    = [-150, 0, 150, -150, 0, 150, -150, 0, 150;...
%     200, 200 , 200, 0, 0, 0, -200, -200, -200];

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
% posFemto    = [-25;...
%                25];
posFemto    = [-40, -125, -25, 25, 100;...
               150, 0, 25, -25, 80];
% posFemto    = [-175, -125, -25, 25, 125, 175, -175, -125, -25, 25, 125, 175, -175, -125, -25, 25, 125, 175;...
%     225, 175 , 225, 175, 225, 175, 25, -25, 25, -25, 25, -25, -175, -225, -175, -225, -175, -225];
% 
femtoBS = parameters.basestation.PredefinedPositions();
femtoBS.positions                  = posFemto;
femtoBS.antenna                    = parameters.basestation.antennas.Omnidirectional;
femtoBS.antenna.nTX                = 2;
femtoBS.antenna.nRX                = 2;
femtoBS.antenna.height             = 5;
femtoBS.antenna.baseStationType    = parameters.setting.BaseStationType.femto;
femtoBS.antenna.transmitPower      = 1;
params.baseStationParameters('femto') = femtoBS;

%user fixed1
poissonNoUser = parameters.user.PredefinedPositions();

seed = 42;
rng(seed);
nombreDePoints = 90;
plageX = 170;
plageY = 200;
valeurZ = 1.5;
coordonnees = rand(3, nombreDePoints);
coordonnees(1, :) = (coordonnees(1, :) - 0.5) * 2 * plageX;
coordonnees(2, :) = (coordonnees(2, :) - 0.5) * 2 * plageY;
coordonnees(3, :) = ones(1, nombreDePoints) * valeurZ;


posUser = coordonnees;
% posUser = [-22.5460, 33.1994,  -44.3981,  -54.1916,   20.1115,  -57.9416, 43.2443, -41.8175, -29.5758, -16.8055, -12.5460, 23.1994,  -34.3981,  -44.1916,   10.1115,  -47.9416, 33.2443, -31.8175, -19.5758, -6.8055, 11.1853, -20.7855, -4.3930, -30.0326, 9.2415, 10.7545, -43.4948, 46.5632, -19.5386, 18.4233, 21.1853, -30.7855, -14.3930, -40.0326, 19.2415, 20.7545, -53.4948, 56.5632, -29.5386, 28.4233;...
%    100.1429, 29.7317, -78.8011, 83.2352, 51.6145, 103.9820, -67.5322, -73.3191, 14.9513, -51.7542, 90.1429, 19.7317, -68.8011, 73.2352, 41.6145, 93.9820, -57.5322, -63.3191, 4.9513, -41.7542, -72.1012, -26.7276, 57.0352, 2.8469, -90.7099, -65.8952, 89.7771, 61.6795, -80.4656, -11.9695, -82.1012, -36.7276, 67.0352, 12.8469, -100.7099, -75.8952, 99.7771, 71.6795, -90.4656, -21.9695;...
%    1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5];

poissonNoUser.positions            = posUser;
poissonNoUser.nRX                  = 1;
poissonNoUser.speed                = 0; % static user
poissonNoUser.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;
poissonNoUser.trafficModelType = parameters.setting.TrafficModelType.FullBuffer;
poissonNoUser.schedulingWeight     = 100; % assign 10 resource blocks when scheduled
poissonNoUser.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonNoUser.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonNoUser.channelModel         = parameters.setting.ChannelModel.PedA;
params.userParameters('poissonUserFixed') = poissonNoUser;

% car user distributed through a Poisson point process

% car users on the street served by pico base stations

end

