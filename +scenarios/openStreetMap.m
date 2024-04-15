function params = openStreetMap(params)
% configures scenario with streets and blockages based on data from OpenStreetMap
% Base stations are placed with predefined positions and users are
% distributed randomly. Each base station is equipped with a 5G and an LTE
% antenna and an equal number of 5G and LTE users are in the network, the
% 5G users have a higher data rate. The dynamic spectrum scheduler
% allocates spectrum according to the user traffic. Modulation scheme up to
% 1024-QAM are used for transmission.
%
% input:
%   params:	[1x1]handleObject parameters.Parameters
%
% output:
%   params:	[1x1]handleObject parameters.Parameters with scenario parameters set
%
% initial author: Christoph Buchner
% extended by: Thomas Lipovec, Jan Nausner
%
% see also launcherFiles.launcherOpenStreetMap

%% General Configuration
% time config
params.time.slotDuration    = 1e-3;
params.time.slotsPerChunk   = 15;

% Scheduler type
params.spectrumSchedulerParameters.type = parameters.setting.SpectrumSchedulerType.dynamicTraffic;

% enable/disable ini
params.calculateIni = true;
params.iniOversampling = 2;

% define the region of interest and interfeernce region
params.regionOfInterest.xSpan = 400;
params.regionOfInterest.ySpan = 300;
params.regionOfInterest.zSpan = 50;

% transmission parameters
params.carrierDL.centerFrequencyGHz	= 2;
params.transmissionParameters.DL.bandwidthHz = 10e6;
params.transmissionParameters.DL.cqiParameterType = parameters.setting.CqiParameterType.Cqi1024QAM;

% disable HARQ
params.useHARQ = false; % not compatible with dynamic spectrum scheduling

%% Configuration of the Network Elements
%% Blockages
% The following parameters describe the specification of an OpenStreetMap
% city. The desired real-world area is specified via latitudes and
% longitudes, which can easily be obtained from openstreetmap.com via the
% "Export" feature.
openStreetMapCity = parameters.city.OpenStreetMap;
openStreetMapCity.latitude          = [48.1955904, 48.1973271];
openStreetMapCity.longitude         = [16.3690209, 16.3718059];
openStreetMapCity.streetWidth       = 5;
% All buildings have random heights, which are sampled from a uniform
% distribution bounded by the minimum and maximum building height. For
% reproducibility it is possible to specify an integer seed for the height
% random number generator.
openStreetMapCity.minBuildingHeight	= 10;
openStreetMapCity.maxBuildingHeight	= 25;
openStreetMapCity.heightRandomSeed  = 'shuffle';
openStreetMapCity.wallLossdB        = 10;
% The configuration of a city can be stored to and loaded from JSON files.
% This also allows for manually setting building heights and wall loss.
openStreetMapCity.saveFile          = [];
openStreetMapCity.loadFile          = [];
params.cityParameters('OSMCity') = openStreetMapCity;

%% Base Stations
% antennas
antennaLTE = parameters.basestation.antennas.ThreeSector;
antennaLTE.nTX             = 4;
antennaLTE.numerology      = 0;    % assign numerology 0
antennaLTE.technology      = parameters.setting.NetworkElementTechnology.LTE;
antennaLTE.alwaysOn        = false;
antenna5G = parameters.basestation.antennas.ThreeSector;
antenna5G.nTX             = 4;
antenna5G.numerology      = 1;     % assign numerology 1
antenna5G.technology      = parameters.setting.NetworkElementTechnology.NRMN_5G;
antenna5G.alwaysOn        = false;
% precoders
precoderTechnology = parameters.precoders.Technology();
precoderTechnology.setTechPrecoder(parameters.setting.NetworkElementTechnology.LTE,     parameters.precoders.LteDL);
precoderTechnology.setTechPrecoder(parameters.setting.NetworkElementTechnology.NRMN_5G, parameters.precoders.LteDL);
% First Base Station
BS1 = parameters.basestation.PredefinedPositions;
BS1.positions   = [-139.815; -18.1125]; % [x;y] coordinate in the OSM city
BS1.nSectors    = 3;
BS1.antenna     = [antennaLTE, antenna5G];
BS1.precoder.DL = precoderTechnology;
params.baseStationParameters('BS1') = BS1;
% Second Base Station
BS2 = parameters.basestation.PredefinedPositions;
BS2.positions   = [70; 92.355]; % [x;y] coordinate in the OSM city
BS2.nSectors    = 3;
BS2.antenna     = [antennaLTE, antenna5G];
BS2.precoder.DL = precoderTechnology;
params.baseStationParameters('BS2') = BS2;

%% Users
% LTE users
UsersLTE = parameters.user.Poisson2D;
UsersLTE.nElements              = 50;
UsersLTE.nRX                    = 1;
UsersLTE.channelModel           = parameters.setting.ChannelModel.PedB;
UsersLTE.trafficModelType       = parameters.setting.TrafficModelType.ConstantRate;
UsersLTE.trafficModel.size      = 94;
UsersLTE.trafficModel.numSlots  = 2;
UsersLTE.numerology             = 0;
UsersLTE.technology             = parameters.setting.NetworkElementTechnology.LTE;
params.userParameters('LTE') = UsersLTE;
% 5G users
Users5G = parameters.user.Poisson2D;
Users5G.nElements               = 50;
Users5G.nRX                     = 1;
Users5G.channelModel            = parameters.setting.ChannelModel.PedB;
Users5G.trafficModelType        = parameters.setting.TrafficModelType.ConstantRate;
Users5G.trafficModel.size       = 94*5;
Users5G.trafficModel.numSlots   = 2;
Users5G.numerology              = 1;
Users5G.technology              = parameters.setting.NetworkElementTechnology.NRMN_5G;
params.userParameters('5G') = Users5G;
end

