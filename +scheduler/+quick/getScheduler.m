function scheduling = getScheduler(Parameters, BS, UE)
%GETSCHEDULER gets a scheduler with basic parameter setting
%
% input:
%   Parameters: [1x1]handleObject parameters.Parameters
%   BS:         [1x1]handleObject networkElements.bs.BaseStation
%   UE:         [1x1]handleObject networkElements.ue.User
%
% output:
%   scheduling: [1x1]handleObject scheduler for this BS
%
% initial author: Agnes Fastenbauer
% extended by: Areen Shiyahin, added traffic model setup

%% initializations
% initialize sinr averager
fastAveraging = true;
sinrAverager.DL = tools.MiesmAverager(Parameters.transmissionParameters.DL.cqiParameters,'dataFiles/BICM_capacity_tables_20000_realizations.mat',fastAveraging);

% set user parameters
userParameters = parameters.user.Poisson2D;
userParameters.nRX              = UE.nRX;
userParameters.channelModel     = parameters.setting.ChannelModel.PedA;
userParameters.trafficModelType = parameters.setting.TrafficModelType.ConstantRate;

UE.setGenericParameters(userParameters, Parameters);
UE.id = 1;

% set traffic model
%NOTE: current slot equals the initial time to avoid having empty packets buffer
UE.trafficModel.checkNewPacket(UE.trafficModel.initialTime);

% initialize scheduler
scheduling = scheduler.Scheduler.generateScheduler(Parameters, BS, sinrAverager);
end

