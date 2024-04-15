function params = example()
% scenario to show all parameters with default values
% Contains all settings set to their default values. This example does
% not show dependent parameters or fixed parameters. This example does show
% additional parameters that have to be set if another parameter setting
% requires them.
% This scenario is meant to be used as a template. When creating your
% own scenario file copy the parameter settings you want to set to
% something other than the default value.
% Use built-in documentation for more information on the parameters: type
% 'doc parameters.Parameters.'parameterName'' in command line. Use
% auto-complete to help find the right classes and use the see also section
% to get more detailed information.
%
% initial author: Agnes Fastenbauer
% extended by: Christoph Buchner, Thomas Lipovec, Areen Shiyahin
%
% see also parameters.Parameters

%% default params
params = parameters.Parameters;

%% time
params.time.numberOfChunks              = 1;    % default value
params.time.slotDuration                = 1e-3; % default value
params.time.slotsPerChunk               = 10;   % default value
params.time.timeBetweenChunksInSlots	= 50;   % default value
params.time.feedbackDelay               = 3;    % default value

%% region of interest
params.regionOfInterest.interferenceRegionFactor	= 1;                                    % default value
params.regionOfInterest.interference                = parameters.setting.Interference.none; % default value
params.regionOfInterest.origin2D                    = [0; 0];                               % default value
params.regionOfInterest.xSpan                       = 1000;                                 % default value
params.regionOfInterest.ySpan                       = 1000;                                 % default value
params.regionOfInterest.zSpan                       = 1000;                                 % default value

%% ********************************************************************* %%
%% ******************************* users ******************************* %%
%% ********************************************************************* %%

%% users placed in cluster with Gaussian distribution
gaussUser = parameters.user.GaussCluster();
gaussUser.mu                = 0;	% default value
gaussUser.sigma             = 1;	% default value
gaussUser.density           = 1e-5;	% example value - default is 0
gaussUser.nElements         = 0;	% default value
gaussUser.clusterCenters    = [];	% default value
gaussUser.clusterRadius     = 10;	% example value - default is 0
gaussUser.clusterSize       = 0;	% default value
gaussUser.clusterDensity	= 2e-4;	% example value - default is 0
gaussUser.nClusterElements	= 0;	% default value
gaussUser.height            = 1.5;	% default value
gaussUser.withFemto         = true;	% default value
% femto antenna parameters
gaussUser.femtoParameters.antenna = parameters.basestation.antennas.Omnidirectional;	        % default value
gaussUser.femtoParameters.antenna.baseStationType   = parameters.setting.BaseStationType.femto; % default value
gaussUser.femtoParameters.antenna.nTX               = 1;                                        % default value
gaussUser.femtoParameters.antenna.height            = 30;                                       % default value
% more user parameters
gaussUser.nRX                       = 1;                                                    % default value
gaussUser.speed                     = 0;                                                    % default value
gaussUser.indoorDecision            = parameters.indoorDecision.Geometry;                   % default value
gaussUser.losDecision               = parameters.losDecision.Geometry;                      % default value
gaussUser.userMovement.type         = parameters.setting.UserMovementType.ConstPosition;    % default value
gaussUser.rxNoiseFiguredB           = 9;                                                    % default value
gaussUser.channelModel              = parameters.setting.ChannelModel.AWGN;                 % default value
gaussUser.trafficModelType          = parameters.setting.TrafficModelType.FullBuffer;       % default value
gaussUser.schedulingWeight          = 1;                                                    % default value
gaussUser.numerology                = 0;                                                    % default value
gaussUser.technology                = parameters.setting.NetworkElementTechnology.LTE;      % default value
params.userParameters('gaussClusterUser') = gaussUser;

%% users distributed in the interference region according to Poisson point process
interferenceUser = parameters.user.InterferenceRegion;
interferenceUser.nElements                          = 50;                                                   % default value
interferenceUser.height                             = 1.5;                                                  % default value
interferenceUser.nRX                                = 1;                                                    % default value
interferenceUser.nTX                                = 1;                                                    % default value
interferenceUser.speed                              = 0;                                                    % default value
interferenceUser.indoorDecision                     = parameters.indoorDecision.Random;                     % default value
interferenceUser.indoorDecision.indoorProbability   = 0.5;                                                  % default value
interferenceUser.losDecision                        = parameters.losDecision.Geometry;                      % default value
interferenceUser.userMovement.type                  = parameters.setting.UserMovementType.ConstPosition;    % default value
interferenceUser.transmitPower                      = 1;                                                    % default value
interferenceUser.rxNoiseFiguredB                    = 9;                                                    % default value
interferenceUser.channelModel                       = parameters.setting.ChannelModel.AWGN;                 % default value
interferenceUser.numerology                         = 0;                                                    % default value
interferenceUser.technology                         = parameters.setting.NetworkElementTechnology.LTE;      % default value
interferenceUser.trafficModelType                   = parameters.setting.TrafficModelType.FullBuffer;       % default value
interferenceUser.schedulingWeight                   = 1;                                                    % default value - ignored by scheduler
params.userParameters('interferenceUser') = interferenceUser;

%% users distributed with a two dimensional Poisson point process
poissonUsers = parameters.user.Poisson2D();
poissonUsers.density            = 5e-5;                                                 % example value - default is 0
poissonUsers.nElements          = 0;                                                    % default value
poissonUsers.height             = 1.5;                                                  % default value
poissonUsers.nRX                = 1;                                                    % default value
poissonUsers.speed              = 0;                                                    % default value
poissonUsers.indoorDecision     = parameters.indoorDecision.Geometry;                   % default value
poissonUsers.losDecision        = parameters.losDecision.Geometry;                      % default value
poissonUsers.userMovement.type  = parameters.setting.UserMovementType.ConstPosition;    % default value
poissonUsers.rxNoiseFiguredB    = 9;                                                    % default value
poissonUsers.channelModel       = parameters.setting.ChannelModel.AWGN;                 % default value
poissonUsers.trafficModelType   = parameters.setting.TrafficModelType.FullBuffer;       % default value
poissonUsers.schedulingWeight   = 1;                                                    % default value
poissonUsers.numerology         = 0;                                                    % default value
poissonUsers.technology         = parameters.setting.NetworkElementTechnology.LTE;	    % default value
params.userParameters('poissonUser') = poissonUsers;

%% users placed in the streets of a Manhattan city
% make sure that the street system set in streetSystemName is created
manhattanUsers = parameters.user.PoissonStreets();
manhattanUsers.density              = 2e-4;                                                 % example value - default is 0
manhattanUsers.nElements            = 0;                                                    % default value
manhattanUsers.height               = 1.5;                                                  % default value
manhattanUsers.streetSystemName     = 'manhattan';                                          % example value - no default value
manhattanUsers.nRX                  = 1;                                                    % default value
manhattanUsers.speed                = 0;                                                    % default value
manhattanUsers.indoorDecision       = parameters.indoorDecision.Geometry;                   % default value
manhattanUsers.losDecision          = parameters.losDecision.Geometry;                       % default value
manhattanUsers.userMovement.type    = parameters.setting.UserMovementType.ConstPosition;    % default value
manhattanUsers.rxNoiseFiguredB      = 9;                                                    % default value
manhattanUsers.channelModel         = parameters.setting.ChannelModel.AWGN;                 % default value
manhattanUsers.trafficModelType     = parameters.setting.TrafficModelType.FullBuffer;       % default value
manhattanUsers.schedulingWeight     = 1;                                                    % default value
manhattanUsers.numerology           = 0;                                                    % default value
manhattanUsers.technology           = parameters.setting.NetworkElementTechnology.LTE;	    % default value
params.userParameters('manhattanusers') = manhattanUsers;

%% users with predefined positions
predefinedUsers = parameters.user.PredefinedPositions();
predefinedUsers.positions          	= [0; 0; 0];                                      	    % example value - no default value
predefinedUsers.nRX                	= 1;                                              	    % default value
predefinedUsers.speed            	= 0;                                              	    % default value
predefinedUsers.indoorDecision     	= parameters.indoorDecision.Geometry;             	    % default value
predefinedUsers.losDecision     	= parameters.losDecision.Geometry;             	        % default value
predefinedUsers.userMovement.type  	= parameters.setting.UserMovementType.ConstPosition;    % default value
predefinedUsers.rxNoiseFiguredB   	= 9;                                              	    % default value
predefinedUsers.channelModel        = parameters.setting.ChannelModel.AWGN;                 % default value
predefinedUsers.trafficModelType	= parameters.setting.TrafficModelType.FullBuffer;	    % default value
predefinedUsers.schedulingWeight    = 1;                                                    % default value
predefinedUsers.numerology       	= 0;                                                    % default value
predefinedUsers.technology        	= parameters.setting.NetworkElementTechnology.LTE;	    % default value
params.userParameters('predefUsers') = predefinedUsers;

%% users placed in cluster with uniform distribution
uniformClusterUser = parameters.user.UniformCluster;
uniformClusterUser.density           	= 25e-6;                                                % example value - default is 0
uniformClusterUser.nElements            = 0;                                                    % default value
uniformClusterUser.clusterCenters       = [];                                                   % default value
uniformClusterUser.clusterRadius      	= 50;                                                   % example value - default is 0
uniformClusterUser.clusterSize          = 0;                                                    % default value
uniformClusterUser.clusterDensity     	= 2.5e-2;                                               % example value - default is 0
uniformClusterUser.nClusterElements     = 0;                                                    % default value
uniformClusterUser.height              	= 1.5;                                                  % default value
uniformClusterUser.nRX                 	= 1;                                                    % default value
uniformClusterUser.speed               	= 0;                                                    % default value
uniformClusterUser.indoorDecision     	= parameters.indoorDecision.Geometry;                   % default value
uniformClusterUser.losDecision       	= parameters.losDecision.Geometry;                      % default value
uniformClusterUser.userMovement.type	= parameters.setting.UserMovementType.ConstPosition;    % default value
uniformClusterUser.withFemto            = true;                                                 % default value
% femto antenna parameters
uniformClusterUser.femtoParameters.antenna = parameters.basestation.antennas.Omnidirectional;                	% default value
uniformClusterUser.femtoParameters.antenna.nTX                  = 1;                                            % default value
uniformClusterUser.femtoParameters.antenna.precoderAnalogType	= parameters.setting.PrecoderAnalogType.none;   % default value
uniformClusterUser.femtoParameters.antenna.height               = 30;                                           % default value
uniformClusterUser.femtoParameters.antenna.transmitPower        = NaN;                                          % default value
uniformClusterUser.femtoParameters.antenna.alwaysOn             = true;                                         % default value
uniformClusterUser.femtoParameters.antenna.rxNoiseFiguredB      = 9;                                            % default value
uniformClusterUser.femtoParameters.antenna.baseStationType	    = parameters.setting.BaseStationType.femto;     % default value
% more user parameters
uniformClusterUser.rxNoiseFiguredB  = 9;                                             	% default value
uniformClusterUser.channelModel     = parameters.setting.ChannelModel.AWGN;           	% default value
uniformClusterUser.trafficModelType = parameters.setting.TrafficModelType.FullBuffer;	% default value
uniformClusterUser.schedulingWeight = 1;                                                % default value
uniformClusterUser.numerology       = 0;                                              	% default value
uniformClusterUser.technology       = parameters.setting.NetworkElementTechnology.LTE;	% default value
params.userParameters('clusterUser') = uniformClusterUser;


%% user movement
% User movement can be combined with any user placment function.
% For example parameters.user.PredefinedPositions or parameters.user.GaussCluster

% moving into a random direction at constant speed
movingUsers = parameters.user.PredefinedPositions; % example user type - all user types are possible to combine with movement
movingUsers.positions        	= [10; 10; 1.5];                                   	        % example value - no default value
movingUsers.speed            	= 500;                                                      % make user move fast to see movement
movingUsers.userMovement.type	= parameters.setting.UserMovementType.RandConstDirection;   % choose movement type
params.userParameters('RandConstDirectionUser') = movingUsers;

% random walking pattern with constant speed
movingUsersWalk = parameters.user.PredefinedPositions;
movingUsersWalk.positions       	= [-10; -10; 1.5];                                     	    % example value - no default value
movingUsersWalk.speed            	= 500;                                                      % make user move fast to see movement
movingUsersWalk.userMovement.type	= parameters.setting.UserMovementType.ConstSpeedRandomWalk; % choose movement type
params.userParameters('ConstSpeedRandomWalkUser') = movingUsersWalk;

% predefined position for each slot
movingPredefinedUsers = parameters.user.PredefinedPositions;
movingPredefinedUsers.positions                 = [0; 0; 0]; %NOTE: this position will be overwritten by the movement positions
movingPredefinedUsers.userMovement.type         = parameters.setting.UserMovementType.Predefined; % choose movement type
movingPredefinedUsers.userMovement.positionList	= [0:9; 0:9; 1.5*ones(1, 10)]; % predefined positions: [3 x nSlotsTotal x nUser]double
params.userParameters('predefinedMovementUser') = movingPredefinedUsers;


%% user indoor decision

% random idoor/outdoor position
randomIndoorUsers = parameters.user.PredefinedPositions;
randomIndoorUsers.positions         = [20; 20; 1.5];	% example value - no default value
indoorDecision                      = 0.5;              % if no indoor decision probability is handed to the indoor decision a probability of 0.5 is used
randomIndoorUsers.indoorDecision	= parameters.indoorDecision.Random(indoorDecision);
params.userParameters('RandomIndoorDecisionUser') = randomIndoorUsers;

% static idoor/outdoor position
staticIndoorUsers = parameters.user.PredefinedPositions;
staticIndoorUsers.positions        	= [-20; -20; 1.5];	% example value - no default value
staticIndoorUsers.indoorDecision	= parameters.indoorDecision.Static(parameters.setting.Indoor.indoor);
params.userParameters('StaticIndoorDecisionUser') = staticIndoorUsers;


%% user LOS decision
% LOS decision based on geometry
geometryLOSuser = parameters.user.PredefinedPositions;
geometryLOSuser.positions   = [20; 20; 1.5]; % example value - no default value
geometryLOSuser.losDecision = parameters.losDecision.Geometry; % default value - no additional parameters to set
params.userParameters('geometryLOSuser') = geometryLOSuser;

% random LOS decision
randomLOSuser = parameters.user.PredefinedPositions;
randomLOSuser.positions                     = [20; 20; 1.5]; % example value - no default value
randomLOSuser.losDecision                   = parameters.losDecision.Random;
randomLOSuser.losDecision.losProbability    = 0.5; % default value
params.userParameters('randomLOSuser') = randomLOSuser;

% static LOS decision
staticLOSuser = parameters.user.PredefinedPositions;
staticLOSuser.positions                     = [20; 20; 1.5]; % example value - no default value
staticLOSuser.losDecision                   = parameters.losDecision.Static;
staticLOSuser.losDecision.isLos             = false; % default value
params.userParameters('staticLOSuser') = staticLOSuser;

% LOS decision based on rural model probability
ruralLOSuser = parameters.user.PredefinedPositions;
ruralLOSuser.positions      = [20; 20; 1.5]; % example value - no default value
ruralLOSuser.losDecision    = parameters.losDecision.RuralMacro5G; % default value - no additional parameters to set
params.userParameters('ruralLOSuser') = ruralLOSuser;

% LOS decision based on urban macro 3D model probability
urban3DLOSuser = parameters.user.PredefinedPositions;
urban3DLOSuser.positions    = [20; 20; 1.5]; % example value - no default value
urban3DLOSuser.losDecision  = parameters.losDecision.UrbanMacro3D; % default value - no additional parameters to set
params.userParameters('urban3DLOSuser') = urban3DLOSuser;

% LOS decision based on urban macro 5G model probability
urban5GLOSuser = parameters.user.PredefinedPositions;
urban5GLOSuser.positions    = [20; 20; 1.5]; % example value - no default value
urban5GLOSuser.losDecision  = parameters.losDecision.UrbanMacro5G; % default value - no additional parameters to set
params.userParameters('urban5GLOSuser') = urban5GLOSuser;

% LOS decision based on urban micro 3D model probability
micro3DLOSuser = parameters.user.PredefinedPositions;
micro3DLOSuser.positions    = [20; 20; 1.5]; % example value - no default value
micro3DLOSuser.losDecision  = parameters.losDecision.UrbanMicro3D; % default value - no additional parameters to set
params.userParameters('micro3DLOSuser') = micro3DLOSuser;

% LOS decision based on urban micro 5G model probability
micro5GLOSuser = parameters.user.PredefinedPositions;
micro5GLOSuser.positions    = [20; 20; 1.5]; % example value - no default value
micro5GLOSuser.losDecision  = parameters.losDecision.UrbanMicro5G; % default value - no additional parameters to set
params.userParameters('micro5GLOSuser') = micro5GLOSuser;


%% user traffic model

% full buffer traffic model
poissonUsers = parameters.user.Poisson2D();
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.FullBuffer;    % defualt traffic model

% constant rate traffic model
poissonUsers.trafficModelType           = parameters.setting.TrafficModelType.ConstantRate; % example traffic model
poissonUsers.trafficModel.numSlots      = 1;                                                % default value
poissonUsers.trafficModel.size          = 94;                                               % default value
poissonUsers.trafficModel.initialTime   = 0;                                                % default value

% FTP traffic model
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.FTP;           % example traffic model

% HTTP traffic model
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.HTTP;          % example traffic model

% video streaming traffic model
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.Video;         % example traffic model

% gaming traffic model
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.Gaming;        % example traffic model

% VoIP traffic model
poissonUsers.trafficModelType          = parameters.setting.TrafficModelType.VoIP;          % example traffic model


%% ********************************************************************* %%
%% *************************** base stations *************************** %%
%% ********************************************************************* %%

%% Antennas
% antenna array
antennaArray = parameters.basestation.antennas.AntennaArray;
antennaArray.nV                     = 2;                                                % default value
antennaArray.nH                     = 1;                                                % default value
antennaArray.nPV                    = 2;                                                % default value
antennaArray.nPH                    = 1;                                                % default value
antennaArray.dV                     = 0.5;                                              % default value
antennaArray.dH                     = 0.5;                                              % default value
antennaArray.dPV                    = 2;                                                % default value
antennaArray.dPH                    = 2;                                                % default value
antennaArray.nTX                    = 1;                                                % default value
antennaArray.baseStationType        = parameters.setting.BaseStationType.macro;         % default value
antennaArray.precoderAnalogType     = parameters.setting.PrecoderAnalogType.MIMO;       % default value
antennaArray.height                 = 30;                                               % default value
antennaArray.transmitPower          = NaN;                                              % default value - transmit power will be chosen according to base station type
antennaArray.alwaysOn               = true;                                             % default value
antennaArray.rxNoiseFiguredB        = 9;                                                % default value
antennaArray.azimuth                = 0;                                                % default value
antennaArray.elevation              = 90;                                               % default value
antennaArray.numerology            	= 0;                                                % default value
antennaArray.technology          	= parameters.setting.NetworkElementTechnology.LTE;	% default value

% omnidirectional antenna
antennaOmni = parameters.basestation.antennas.Omnidirectional;
antennaOmni.nTX                     = 1;                                                % default value
antennaOmni.baseStationType         = parameters.setting.BaseStationType.macro;         % default value
antennaOmni.precoderAnalogType      = parameters.setting.PrecoderAnalogType.none;       % default value
antennaOmni.height                  = 30;                                               % default value
antennaOmni.transmitPower           = NaN;                                              % default value - transmit power will be chosen according to base station type
antennaOmni.alwaysOn                = true;                                             % default value
antennaOmni.rxNoiseFiguredB         = 9;                                                % default value
antennaOmni.numerology              = 0;                                                % default value
antennaOmni.technology              = parameters.setting.NetworkElementTechnology.LTE;	% default value

% six sector
antennaSixSector = parameters.basestation.antennas.SixSector;
antennaSixSector.nTX                    = 1;                                                % default value
antennaSixSector.baseStationType        = parameters.setting.BaseStationType.macro;         % default value
antennaSixSector.precoderAnalogType     = parameters.setting.PrecoderAnalogType.none;       % default value
antennaSixSector.height                 = 30;                                               % default value
antennaSixSector.transmitPower          = NaN;                                              % default value - transmit power will be chosen according to base station type
antennaSixSector.alwaysOn               = true;                                             % default value
antennaSixSector.rxNoiseFiguredB        = 9;                                                % default value
antennaSixSector.azimuth              	= 0;                                                % default value
antennaSixSector.elevation           	= 90;                                               % default value
antennaSixSector.numerology            	= 0;                                                % default value
antennaSixSector.technology          	= parameters.setting.NetworkElementTechnology.LTE;	% default value

% three sector
antennaThreeSector = parameters.basestation.antennas.ThreeSector;
antennaThreeSector.nTX                      = 1;                                                % default value
antennaThreeSector.baseStationType          = parameters.setting.BaseStationType.macro;         % default value
antennaThreeSector.precoderAnalogType       = parameters.setting.PrecoderAnalogType.none;       % default value
antennaThreeSector.height                   = 30;                                               % default value
antennaThreeSector.transmitPower            = NaN;                                              % default value - transmit power will be chosen according to base station type
antennaThreeSector.alwaysOn                 = true;                                             % default value
antennaThreeSector.rxNoiseFiguredB          = 9;                                                % default value
antennaThreeSector.azimuth              	= 0;                                                % default value
antennaThreeSector.elevation              	= 90;                                               % default value
antennaThreeSector.numerology            	= 0;                                                % default value
antennaThreeSector.technology               = parameters.setting.NetworkElementTechnology.LTE;	% default value

% three sector Berger
antennaBerger = parameters.basestation.antennas.ThreeSectorBerger;
antennaBerger.nTX                       = 1;                                                % default value
antennaBerger.baseStationType           = parameters.setting.BaseStationType.macro;         % default value
antennaBerger.precoderAnalogType        = parameters.setting.PrecoderAnalogType.none;       % default value
antennaBerger.height                    = 30;                                               % default value
antennaBerger.transmitPower             = NaN;                                              % default value - transmit power will be chosen according to base station type
antennaBerger.alwaysOn                  = true;                                             % default value
antennaBerger.rxNoiseFiguredB           = 9;                                                % default value
antennaBerger.azimuth                	= 0;                                                % default value
antennaBerger.elevation                	= 90;                                               % default value
antennaBerger.numerology             	= 0;                                                % default value
antennaBerger.technology              	= parameters.setting.NetworkElementTechnology.LTE;	% default value


%% Precoders

% LTE DL precoder
precoderLteDL = parameters.precoders.LteDL;

% random precoder
precoderRandom = parameters.precoders.Random;

% 5G downlink precoder
precoder5G = parameters.precoders.Precoder5G;

% Kronecker product based precoder
precoderKronecker = parameters.precoders.Kronecker;
precoderKronecker.beta = 1;                    % default value
precoderKronecker.maxLayer = 8;                % default value
precoderKronecker.horizontalOversampling = 4;  % default value
precoderKronecker.verticalOversampling   = 4;  % default value

% technology precoder - for base stations with multiple technologies
% see also the base station section for an example on how to use this
% precoder
precoderTechnology = parameters.precoders.Technology();
precoderTechnology.setTechPrecoder(parameters.setting.NetworkElementTechnology.LTE,     precoderLteDL);  % default value
precoderTechnology.setTechPrecoder(parameters.setting.NetworkElementTechnology.NRMN_5G, precoder5G);     % default value


%% Base Station

% base station placed in a hexagonal grid filling the simulation region
hexGrid = parameters.basestation.HexGrid();
hexGrid.interBSdistance	= 400;                                                  % example value - no default value
hexGrid.nSectors        = 1;                                                    % default value
hexGrid.antenna         = antennaOmni;                                          % default value
hexGrid.precoder.DL     = precoderLteDL;                                        % default value
params.baseStationParameters('hexGrid') = hexGrid;

% base station placed in rings of a hexagonal grid
hexRing = parameters.basestation.HexRing;
hexRing.interBSdistance     = 150;                                              % default value
hexRing.nRing               = 1;                                                % default value
hexRing.nSectors            = 6;                                                % example value - default is 1
hexRing.antenna             = antennaSixSector;                                 % example value - default is Omnidirectional
hexRing.precoder.DL         = precoderRandom;                                   % example value - default is LTE DL
params.baseStationParameters('hexRing') = hexRing;

% base stations positioned on each buildings with a certain probability
macroOnBuildings = parameters.basestation.MacroOnBuildings;
macroOnBuildings.antennaHeight          = 2;                                       	% example value - no default value
macroOnBuildings.occupationProbability	= 0.5;                                   	% example value - no default value
macroOnBuildings.margin                 = 8;                                       	% example value - no default value
macroOnBuildings.nSectors               = 3;                                       	% example value - default is 1
macroOnBuildings.antenna                = antennaThreeSector;                      	% example value - default is Omnidirectional
macroOnBuildings.precoder.DL            = parameters.precoders.LteDL;               % default value
params.baseStationParameters('macroOnBuildings') = macroOnBuildings;

% base stations placed according to a Poisson point process
poissonBS = parameters.basestation.Poisson2D;
poissonBS.density	  = 2e-5;                                     	% example value - default is 0
poissonBS.nElements	  = 0;                                       	% default value
poissonBS.nSectors    = 3;                                      	% example value - default is 1
poissonBS.antenna	  = antennaBerger;                          	% example value - default is Omnidirectional
poissonBS.precoder.DL = precoder5G;                                 % example value - default is LTE DL
params.baseStationParameters('poissonBS') = poissonBS;

% base stations placed according to predefined positions
predefinedBS = parameters.basestation.PredefinedPositions;
predefinedBS.positions	 = [10; 4];                                 	% example value - no default value
predefinedBS.nSectors    = 3;                                      	    % example value - default is 1
predefinedBS.antenna	 = antennaBerger;                          	    % example value - default is Omnidirectional
predefinedBS.precoder.DL = precoderKronecker;                           % example value - default is LTE DL
params.baseStationParameters('predefBS') = predefinedBS;

% base stations placed in the interference region
interferenceBS = parameters.basestation.InterferenceRegion;
interferenceBS.density      = 2;                                        % default value - in BS per km^2
interferenceBS.nElements    = 0;                                       	% default value
interferenceBS.nSectors     = 1;                                        % default value
interferenceBS.antenna      = antennaOmni;                              % default value
interferenceBS.precoder.DL  = precoderLteDL;                            % default value
params.baseStationParameters('interferenceBS') = interferenceBS;

% base stations with a technology precoder
% see also technology section on how to define the precoder
antennaLte = parameters.basestation.antennas.Omnidirectional;               % define LTE antenna
antennaLte.technology = parameters.setting.NetworkElementTechnology.LTE;
antenna5g = parameters.basestation.antennas.Omnidirectional;                % define 5G antenna
antenna5g.technology = parameters.setting.NetworkElementTechnology.NRMN_5G;
basestation = parameters.basestation.PredefinedPositions;
basestation.positions	= [10; 4];                                          % example value - no default value
basestation.antenna	    = [antennaLte, antenna5g];                          % example value - default is Omnidirectional - pass as array
basestation.precoder.DL = precoderTechnology;                               % example value - default is LTE DL
params.baseStationParameters('techBs') = basestation;


%% city - buildings and streets

% Manhattan
manhattanCity = parameters.city.Manhattan;
manhattanCity.ySize             = 600;                     	% example value - no default value
manhattanCity.xSize             = 400;                      % example value - no default value
manhattanCity.streetWidth       = 350;                      % example value - no default value
manhattanCity.minBuildingHeight	= 40;                       % example value - no default value
manhattanCity.maxBuildingHeight	= 80;                       % example value - no default value
manhattanCity.heightRandomSeed  = 'shuffle';                % default value
manhattanCity.wallLossdB        = 10;                       % example value - no default value
manhattanCity.saveFile          = "manhattan_city.json";	% example value - default empty
manhattanCity.loadFile          = "manhattan_city.json";    % example value - default empty
params.cityParameters('manhattan') = manhattanCity;

% Open Street Map
openStreetMapCity = parameters.city.OpenStreetMap();
openStreetMapCity.latitude          = [48.1955904, 48.1973271];	% example value - no default value
openStreetMapCity.longitude         = [16.3690209, 16.3718059];	% example value - no default value
openStreetMapCity.streetWidth       = 5;                      	% example value - no default value
openStreetMapCity.minBuildingHeight	= 10;                       % example value - no default value
openStreetMapCity.maxBuildingHeight	= 25;                       % example value - no default value
openStreetMapCity.heightRandomSeed  = 'shuffle';                % default value
openStreetMapCity.wallLossdB        = 10;                       % example value - no default value
openStreetMapCity.saveFile          = "OSM_city.json";          % example value - default empty
openStreetMapCity.loadFile          = "OSM_city.json";          % example value - default empty
params.cityParameters('OSMCity') = openStreetMapCity;

%% building
predefBuildings = parameters.building.PredefinedPositions;
predefBuildings.floorPlan   = 40*[1,0,0,1,1;0,0,1,1,0];    % example value - no default value
predefBuildings.height      = 10;                          % example value - no default value
predefBuildings.loss        = 10;                          % example value - no default value
predefBuildings.positions	= [-500;-500];                 % example value - no default value
params.buildingParameters('predefBuildings') = predefBuildings;

%% wall
wall = parameters.wallBlockage.PredefinedPositions;
wall.cornerList = 50*[0,0,1,1,0; 0,0,0,0,0; 0,1,1,0,0]; % example value - no default value
wall.loss       = 20;                                   % example value - no default value
wall.positions  = [-300;-300;0];                        % example value - no default value
params.wallParameters('predefWall') = wall;

%% pathloss model container
% general path loss parameters
params.pathlossModelContainer.minimumCouplingLossdB = [70, 53, 45]; % default value
params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 0];    % default value

% path loss models and their respective parameters
% fixed path loss
fixed = parameters.pathlossParameters.Fixed;
fixed.fixedPathLossdB = 50; % default value
% free space path loss
freeSpace = parameters.pathlossParameters.FreeSpace;
freeSpace.alpha = 2; % default value
% indoor path loss
indoorModel = parameters.pathlossParameters.Indoor;
% rural
rural = parameters.pathlossParameters.Rural;
% rural 5G
rural5G = parameters.pathlossParameters.RuralMacro5G;
rural5G.isLos = false; % default value
rural5G.avgStreetWidth = 20; % default value
rural5G.avgBuildingHeight = 5; % default value
% suburban
suburban = parameters.pathlossParameters.SuburbanMacroCost;
% urban
urban = parameters.pathlossParameters.Urban;
urban.avgBuildingHeight = 20; % default value
% urban 3D
urban3D = parameters.pathlossParameters.UrbanMacro3D;
urban3D.isLos = false; % default value
urban3D.isIndoor = true; % default value
urban3D.avgStreetWidth = 20; % default value
urban3D.avgBuildingHeight = 20; % default value
% urban 5G
urban5G = parameters.pathlossParameters.UrbanMacro5G;
urban5G.isLos = false; % default value
% urban COST
urbanCost = parameters.pathlossParameters.UrbanMacroCost;
% micro 3D
micro3D = parameters.pathlossParameters.UrbanMicro3D;
micro3D.isLos = false; % default value
micro3D.isIndoor = false; % default value
% micro 5G
micro5G = parameters.pathlossParameters.UrbanMicro5G;
micro5G.isLos = false; % default value
% micro COST
microCost = parameters.pathlossParameters.UrbanMicroCost;
microCost.isLos = false; % default value

% path loss model container setting - default model is free space for all link types
%NOTE: the path loss models are set randomly to show to set them, choose an
%appropriate model for each link type used in a simulation
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;
% set path loss models for macro base station
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}    = freeSpace;	% default value
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}   = indoorModel;  % example value
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}    = fixed;        % example value
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}   = rural5G;      % example value
% set path loss models for pico base station
pico = parameters.setting.BaseStationType.pico;
params.pathlossModelContainer.modelMap{pico,	indoor,     LOS}    = rural;        % example value
params.pathlossModelContainer.modelMap{pico,	indoor,     NLOS}   = urban3D;      % example value
params.pathlossModelContainer.modelMap{pico,	outdoor,	LOS}    = suburban;     % example value
params.pathlossModelContainer.modelMap{pico,	outdoor,	NLOS}   = urban5G;      % example value
% set path loss models for femto base station
femto = parameters.setting.BaseStationType.femto;
params.pathlossModelContainer.modelMap{femto,	indoor,     LOS}    = urban;        % example value
params.pathlossModelContainer.modelMap{femto,   indoor,   NLOS}     = micro3D;      % example value
params.pathlossModelContainer.modelMap{femto,	outdoor,    LOS}    = urbanCost;    % example value
params.pathlossModelContainer.modelMap{femto,	outdoor,	NLOS}   = micro5G;      % example value


%% carrier
% the following settings are default settings
params.carrierDL.centerFrequencyGHz	= 2;    % default value
params.carrierDL.carrierNo          = 1;    % example value - default is 0

%% cell association strategy
params.cellAssociationStrategy = parameters.setting.CellAssociationStrategy.maxSINR;    % default value

%% shadow fading
params.shadowFading.on          = false;        % default value
params.shadowFading.resolution	= 5;            % default value
params.shadowFading.mapCorr     = 0.5;          % default value
params.shadowFading.meanSFV     = 0;            % default value
params.shadowFading.stdDevSFV	= 1;            % default value
params.shadowFading.decorrDist	= log(2)*20;    % default value

%% scheduler
params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;  % default value

%% spectrumScheduler
params.spectrumSchedulerParameters.type = parameters.setting.SpectrumSchedulerType.static;  % default value
params.spectrumSchedulerParameters.weigths('LTE:0')     = 1;                                % default value
params.spectrumSchedulerParameters.weigths('NRMN_5G:0') = 1;                                % default value

%% transmission parameters
params.transmissionParameters.DL.txModeIndex                = 4;                                            % default value
params.transmissionParameters.DL.bandwidthHz                = 5e6;                                          % default value
params.transmissionParameters.DL.cqiParameterType           = parameters.setting.CqiParameterType.Cqi64QAM; % default value
params.transmissionParameters.DL.redundancyVersion          = [0 1 2 3];                                    % default value
params.transmissionParameters.DL.layerMappingType           = parameters.setting.LayerMappingType.TS36211;  % default value
params.transmissionParameters.DL.resourceGridType           = parameters.setting.ResourceGrid.LTE;          % default value
params.transmissionParameters.DL.feedbackType               = parameters.setting.FeedbackType.LTEDL;        % default value
params.transmissionParameters.DL.nCRCBits                   = 24;                                           % default value
params.transmissionParameters.DL.maxNCodewords              = 2;                                            % default value
params.transmissionParameters.DL.maxNLayer                  = 4;                                            % default value
params.transmissionParameters.DL.fastBlerMapping            = true;                                         % default value
params.transmissionParameters.DL.mapperBlerThreshold	    = 0.1;                                          % default value
params.transmissionParameters.DL.synchronizationSignalLTE   = true;                                         % default value
params.transmissionParameters.DL.referenceSignalLTE         = true;                                         % default value

%% NOMA parameters
params.noma.interferenceFactorSic	= 0;                                % default value
params.noma.deltaPairdB             = Inf;                              % default value
params.noma.mustIdx                 = parameters.setting.MUSTIdx.Idx00;	% default value
params.noma.abortLowCqi             = false;                            % default value

%% small scale fading parameters
params.smallScaleParameters.correlatedFading        = true;                         % default value
params.smallScaleParameters.traceLengthSlots        = 2000;                         % default value - for large scenarios, increase value
params.smallScaleParameters.regenerateChannelTrace	= false;                        % default value
params.smallScaleParameters.verbosityLevel          = 1;                            % default value
params.smallScaleParameters.pregenFFfileName        = 'dataFiles/channelTraces/';	% default value

%% save additional results
params.save.losMap                  = false;    % default value
params.save.isIndoor                = false;    % default value
params.save.antennaBsMapper         = false;    % default value
params.save.macroscopicFading       = false;    % default value
params.save.wallLoss                = false;    % default value
params.save.shadowFading            = false;    % default value
params.save.antennaGain             = false;    % default value
params.save.pathlossTable           = false;    % default value

%% filename
params.filename = 'myFilename';	% example value - default is set according to current date and time

%% postprocessor
params.postprocessor                = simulation.postprocessing.FullPP;	% default value

%% fastAveraging
params.fastAveraging                = true;                             % default value

%% bernoulli experiment
params.bernoulliExperiment          = true;                             % default value

%% maximum correlation distance
params.maximumCorrelationDistance	= 1;                                % default value

%% use feedback
params.useFeedback                  = true;                             % default value

%% calculate inter-numerology interference
params.calculateIni                 = false;                            % default value
params.iniOversampling              = 1;                                % default value

%% HARQ
params.useHARQ                      = true;                             % default value

end

