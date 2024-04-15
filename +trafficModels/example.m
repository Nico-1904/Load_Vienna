% This example illustrates how to use trafficModels package
%
% We show:
% *How to set the parameters that are necessary for creating a model
% *Choose traffic model for a user
% *Create traffic model
% *Create packets to be appended to the packets buffer
% *Check the buffer state and update it according to the user throughput
% *Calculate and plot the transmission latency
% *Clear the buffer at the end of a chunk simulation
%
% initial author: Areen Shiyahin
%
% see also parameters.user.Parameters
% networkElements.ue.User

%% set parameters

% traffic model is chosen by the trafficModelType
% set user parameters
params   = parameters.Parameters;
params.setDependentParameters;
params.transmissionParameters.DL.bandwidthHz = 20e6;
UE                        = networkElements.ue.User;
poissonUser               = parameters.user.Poisson2D;
params.userParameters('poissonUser') = poissonUser;

%% Chose model
% When no parameters are listed, it means they are already set within the model class

poissonUser.trafficModelType        = parameters.setting.TrafficModelType.ConstantRate;
poissonUser.trafficModel.numSlots   = 2;
poissonUser.trafficModel.size       = 1000;

% poissonUser.trafficModelType  = parameters.setting.TrafficModelType.FullBuffer;
% poissonUser.trafficModel.numSlots = 0;

% poissonUser.trafficModelType   = parameters.setting.TrafficModelType.FTP;

% poissonUser.trafficModelType   = parameters.setting.TrafficModelType.HTTP;

% poissonUser.trafficModelType   = parameters.setting.TrafficModelType.Video;

% poissonUser.trafficModelType   = parameters.setting.TrafficModelType.Gaming;

% poissonUser.trafficModelType   = parameters.setting.TrafficModelType.VoIP;

%% create traffic model

% traffic model is read-only property for the user
UE.setGenericParameters(poissonUser, params);
traffic = UE.trafficModel;

%% create packets

% some models need longer simulation duration for creating packets
for iSlot = 1:10
    UE.trafficModel.checkNewPacket(iSlot);
end

%% Check and update the buffer

[numberOfPackets,remaningBits,generationTimes] = UE.trafficModel.getBufferState;

userThroughput = 3000;
UE.trafficModel.updateAfterTransmit(userThroughput,iSlot);

%% compute packets transmission latency

Latency = UE.trafficModel.getTransmissionLatency;

if all(isinf(Latency)) || isempty(Latency)
    warning('Transmission latency plot will not be shown since insufficient number of packets has been transmitted, you may need to increase the simulation time or change the traffic model parameters.');
    return;
end

% create figure
figure();
tools.myEcdf(Latency(:));
xlabel('latency(slots)')
ylabel('ECDF')
title('packets latency');

%% clear the buffer
UE.trafficModel.clearBuffer;

