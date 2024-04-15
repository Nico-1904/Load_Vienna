function [Container, channel] = example()
% generation of desired and interfering channel traces for all antenna configurations set in this function
%
%output:
%   Container:	[1x1]handleObject smallScaleFading.PDPcontainer
%       -PDPtraces:     [max(nRX) x max(nTX) x max(carrierNo) x max(channelModel)]
%                   for max(channelModel) see also parameters.setting.ChannelModel
%                   [nRX x nTX x nTimeSamples x traceLengthSlots x nSubcarrierSlot/fftSamplingInterval]complex channel matrix
%   channelDL:	[1 x nAnt]struct channel for link quality model
%       -H: [nRX x nTX x nTimeSamples x nFreqSamples]complex channel matrix
%
% see also smallScaleFading.PDPcontainer, smallScaleFading.ChannelFactory,
% smallScaleFading.PDPchannelFactory, parameters.setting.ChannelModel
%
% initial author: Agnes Fastenbauer
%
%NOTE: for correlatedFading the doppler frequency is used to generate the
%Rosa Zheng parameters, only one speed per channel model can be used in a
%simulation

%% setting of parameters
%NOTE: here all configurations necessary for the creation of a PDP channel
%trace are set. Use this file as reference for variable naming.
CCs(3) = parameters.Carrier();
BSs(3) = networkElements.bs.BaseStation();
UEs(5) = networkElements.ue.User();

CCs(1).centerFrequencyGHz	= 2.14;
CCs(1).bandwidthHz          = 10e6;
CCs(1).carrierNo            = 1;
CCs(2).centerFrequencyGHz	= 2.15;
CCs(2).bandwidthHz          = 1.4e6;
CCs(2).carrierNo            = 2;
CCs(3).centerFrequencyGHz	= 2.14;
CCs(3).bandwidthHz          = 2e6;
CCs(3).carrierNo            = 3;

UEs(1).nRX = 1;
UEs(1).id  = 1;
UEs(1).speed = 1;
UEs(1).numerology = 0;
UEs(1).channelModel = parameters.setting.ChannelModel.PedA;
UEs(2).nRX = 2;
UEs(2).id  = 2;
UEs(2).speed = 1;
UEs(2).numerology = 0;
UEs(2).channelModel = parameters.setting.ChannelModel.PedA;
UEs(3).nRX = 1;
UEs(3).id  = 3;
UEs(3).speed = 1;
UEs(3).numerology = 0;
UEs(3).channelModel = parameters.setting.ChannelModel.PedB;
UEs(4).nRX = 1;
UEs(4).id  = 4;
UEs(4).speed = 1;
UEs(4).numerology = 0;
UEs(4).channelModel = parameters.setting.ChannelModel.PedB;
UEs(5).nRX = 2;
UEs(5).id  = 5;
UEs(5).speed = 1;
UEs(5).numerology = 0;
UEs(5).channelModel = parameters.setting.ChannelModel.VehA;

BSs(1).attachedUsers = UEs;
BSs(1).antennaList = networkElements.bs.antennas.Omnidirectional;
BSs(1).antennaList.nTX = 2;
BSs(1).antennaList.nTXelements = BSs(1).antennaList.nTX;
BSs(1).antennaList.id  = 1;
BSs(1).antennaList.usedCCs = CCs(1);

BSs(2).attachedUsers = UEs(3:5);
BSs(2).antennaList = networkElements.bs.antennas.Omnidirectional;
BSs(2).antennaList.nTX = 2;
BSs(2).antennaList.nTXelements = BSs(2).antennaList.nTX;
BSs(2).antennaList.id  = 2;
BSs(2).antennaList.usedCCs = CCs;

BSs(3).attachedUsers = UEs(1:3);
BSs(3).antennaList = networkElements.bs.antennas.Omnidirectional;
BSs(3).antennaList.nTX = 4;
BSs(3).antennaList.nTXelements = BSs(3).antennaList.nTX;
BSs(3).antennaList.id  = 3;
BSs(3).antennaList.usedCCs = CCs;

allAntennaList = [BSs(1).antennaList, BSs(2).antennaList, BSs(3).antennaList];

%% set parameters
% used parameters:
%   -Parameters.smallScaleParameters
%   -Parameters.time.slotDuration
%   -Parameters.transmissionParameters.DL.resourceGrid.subcarrierSpacingHz
%   -Parameters.transmissionParameters.DL.resourceGrid.nSymbolRb
%   -Parameters.transmissionParameters.DL.resourceGrid.nRBFreq
%   -Parameters.transmissionParameters.DL.resourceGrid.nSubcarrierSlot
%   -Parameters.transmissionParameters.DL.resourceGrid.sizeRbFreqHz
Parameters = parameters.Parameters;
Parameters.smallScaleParameters.correlatedFading = true;
Parameters.setDependentParameters;

%% creates the object
% this should happen before the simulation loop
Container = smallScaleFading.PDPcontainer;
Container.setPDPcontainer(Parameters, Parameters.transmissionParameters.DL.resourceGrid);

%% creates and saves the channel traces
Container.generateTraces(allAntennaList, UEs);

%% loads the channel traces needed for the network configuration
% this should happen in each chunk
Container.loadChannelTraces(allAntennaList, UEs);

%% read out channel realizations for link quality model
iSlot = 1; % index of current slot
channel = Container.getChannelForAllAntennas(UEs(1), allAntennaList, iSlot);

% show channel trace
Container.plotChannelTrace(2, 2, parameters.setting.ChannelModel.PedA, 1, 10);
end

