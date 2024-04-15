function params = ManhattanQuadriga(params)
% Manhattan grid scenario with streets and blockages
% Base stations are placed on top of buildings and users are distributed
% according to a Poisson Point Process on streets and in whole simulation
% region. Quadriga channel model is used with antenna arrays and HARQ is
% used.
%
% initial author: Armand Nabavi
%
% see also launcherFiles.launcherManhattanQuadriga

%% General Configuration
% time config
params.time.slotsPerChunk = 10;

% enable HARQ
params.useHARQ = true;
params.noma.mustIdx                                 = parameters.setting.MUSTIdx.Idx00;	% disable for HARQ use
params.transmissionParameters.DL.cqiParameterType   = parameters.setting.CqiParameterType.Cqi64QAM;
params.time.feedbackDelay                           = 1; % necessray for using HARQ

% define the region of interest & boundary region
params.regionOfInterest.xSpan = 300;
params.regionOfInterest.ySpan = 300;
params.regionOfInterest.zSpan = 100;

% use best CQI scheduler
params.schedulerParameters.type = parameters.setting.SchedulerType.bestCqi;

% additional object that should be saved into simulation results
params.save.losMap          = true; % save to plot LOS connections
params.save.isIndoor        = true; % save to plot indoor/outdoor users

% set pathloss model
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro, indoor,	LOS} = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro, indoor,	NLOS} = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro, outdoor,	LOS} = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro, outdoor,	NLOS} = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro, indoor,	LOS}.isLos = true;
params.pathlossModelContainer.modelMap{macro, indoor,	NLOS}.isLos = false;
params.pathlossModelContainer.modelMap{macro, outdoor,	LOS}.isLos = true;
params.pathlossModelContainer.modelMap{macro, outdoor,	NLOS}.isLos = false;

%% Configuration of the Network Elements
% Manhattan city
manhattanCity = parameters.city.Manhattan();
manhattanCity.ySize             = 60;
manhattanCity.xSize             = 60;
manhattanCity.streetWidth       = 25;
manhattanCity.minBuildingHeight	= 20;
manhattanCity.maxBuildingHeight	= 60;
manhattanCity.heightRandomSeed  = 'shuffle';
manhattanCity.wallLossdB        = 10;
manhattanCity.saveFile          = [];
manhattanCity.loadFile          = [];
params.cityParameters('manhattan') = manhattanCity;

% Base Stations
nAntElement = 4; % corresponds to 4x4
% see parameters.basestation.antennas.Parameters for more information on the settings
antenna = parameters.basestation.antennas.AntennaArray;
% number of antenna elements per panel in horizontal and vertical direction
antenna.nH                      = nAntElement;
antenna.nV                      = nAntElement;
% number of panels in horizontal and vertical direction
antenna.nPH                     = 1; % single panel
antenna.nPV                     = 1; % single panel
% number of transmit RF chains
antenna.nTX                     = nAntElement^2;
% horizontal tx chains
antenna.N1                      = nAntElement;
% vertical tx chains
antenna.N2                      = nAntElement;
% horizontal element spacing
antenna.dH                      = 0.5;
% vertical element spacing
antenna.dV                      = 0.5;
antenna.precoderAnalogType      = parameters.setting.PrecoderAnalogType.none; % disable analog precoder
antenna.height                  = 30;
antenna.transmitPower           = 40;
antenna.numerology            	= 0; % same technology and numerology for HARQ use
antenna.technology          	= parameters.setting.NetworkElementTechnology.LTE; % same technology and numerology for HARQ use

% base station defined as macro base stations placed on top of buildings
macroOnBuildings = parameters.basestation.MacroOnBuildings();
macroOnBuildings.occupationProbability	= 0.5; % probability of buildings occoupied with base stations
macroOnBuildings.margin                 = 2;
macroOnBuildings.antennaHeight          = 4;
macroOnBuildings.antenna                = antenna;
macroOnBuildings.precoder.DL = parameters.precoders.Kronecker();
macroOnBuildings.precoder.DL.horizontalOversampling	= 1; % lower resolution for smaller simulation time
macroOnBuildings.precoder.DL.verticalOversampling	= 1; % lower resolution for smaller simulation time
params.baseStationParameters('macroOnBuildings') = macroOnBuildings;

% users
poissonUsers= parameters.user.Poisson2D;
poissonUsers.nRX            = 1;
poissonUsers.density        = 800e-6;
poissonUsers.height         = 1.8;
poissonUsers.speed          = 5/3.6;
poissonUsers.channelModel   = parameters.setting.ChannelModel.Quadriga;
poissonUsers.numerology     = 0; % same technology and numerology for HARQ use
poissonUsers.technology     = parameters.setting.NetworkElementTechnology.LTE; % same technology and numerology for HARQ use
params.userParameters('poissonUser') = poissonUsers;

% street users
manhattanUsers = parameters.user.PoissonStreets;
manhattanUsers.density          = 800e-6;
manhattanUsers.height           = 1.8;
manhattanUsers.streetSystemName = 'manhattan';
manhattanUsers.nRX              = 1;
manhattanUsers.speed            = 5/3.6;
manhattanUsers.channelModel     = parameters.setting.ChannelModel.Quadriga;
manhattanUsers.numerology       = 0; % same technology and numerology for HARQ use
manhattanUsers.technology       = parameters.setting.NetworkElementTechnology.LTE; % same technology and numerology for HARQ use
params.userParameters('manhattanusers') = manhattanUsers;
end

