function [BSs, UE, antennaBSmapper] = example()
% sets up network elements for a basic simulation scenario
% This function is to enable quick use for examples and testing. It sets up
% a general network element setup for downlink.
%
% output:
%   BSs:                [1 x nBS]handleObject array with BSs with generic properties
%   UEs:                [1 x nUE]handleObject array with users with gerneric properties
%   antennaBSmapper:    [1x1]handleObject tools.AntennaBsMapper
%
% initial auhtor: Agnes Fastenbauer

%% set number of elements for each type
CC(1) = parameters.Carrier();
BSs(3) = networkElements.bs.BaseStation();
% dummy positions
positionList = [0;0;0];
antennaParameters = parameters.basestation.antennas.Omnidirectional;
antennaParameters.transmitPower = 10;
UE(1)  = networkElements.ue.User();
% dummy parameters object
params = parameters.Parameters;
params.setDependentParameters();

%% carrier
CC(1).centerFrequencyGHz	= 2.14;
CC(1).bandwidthHz           = 1.4e6;
CC(1).carrierNo             = 1;

%% User
UE(1).nRX               = 1;
UE(1).channelModel      = parameters.setting.ChannelModel.PedA;
UE(1).id                = 1;
UE(1).thermalNoisedB    = 0.1;
UE(1).schedulingWeight  = 1;

%% Base stations
BSs(1).attachedUsers        = UE(1);
parameters.basestation.antennas.Omnidirectional.createAntenna(antennaParameters, positionList, BSs(1), params);
BSs(1).antennaList.id    	= 1;
BSs(1).antennaList.usedCCs	= CC(1);

BSs(2).attachedUsers    	= [];
parameters.basestation.antennas.Omnidirectional.createAntenna(antennaParameters, positionList, BSs(2), params);
BSs(2).antennaList.id       = 2;
BSs(2).antennaList.usedCCs	= CC(1);

BSs(3).attachedUsers        = [];
parameters.basestation.antennas.Omnidirectional.createAntenna(antennaParameters, positionList, BSs(3), params);
BSs(3).antennaList.id    	= 3;
BSs(3).antennaList.usedCCs  = CC(1);

antennaBSmapper = tools.AntennaBsMapper(BSs);
end

