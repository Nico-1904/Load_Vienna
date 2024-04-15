% example script for scheduler package
%
% initial author: Thomas Dittrich
%
% see also scheduler.Scheduler

% clear workspace
close all
clear variables

%% setup
% set number of users for this example script
nUE = 20;

% set parameters
params = parameters.Parameters();
params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;
params.time.numberOfChunks = 1;
params.time.slotsPerChunk  = 100;
params.time.timeBetweenChunksInSlots = 0;
params.setDependentParameters();
params.transmissionParameters.DL.txModeIndex = 1;

% initialize BS
baseStationParameters.antenna                           = parameters.basestation.antennas.Omnidirectional;
baseStationParameters.antenna.nRX                       = 1;
baseStationParameters.antenna.nTX                       = 4;
baseStationParameters.antenna.transmitPower             = 40;
BS = networkElements.bs.BaseStation;
baseStationParameters.antenna.createAntenna(baseStationParameters.antenna, [0;0;0], BS, params);

% initialize users
userParameters = parameters.user.Poisson2D;
userParameters.nRX = 4;
userParameters.nTX = 1;
UE(nUE) = networkElements.ue.User();
for iUE = 1:nUE
    UE(iUE).setGenericParameters(userParameters,params);
    UE(iUE).id = iUE;
end

% initialize sinr averager
fastAveraging = true;
sinrAverager.DL = tools.MiesmAverager(params.transmissionParameters.DL.cqiParameters,'dataFiles/BICM_capacity_tables_20000_realizations.mat',fastAveraging);

% initialize precoder
BS.precoder.DL = parameters.precoders.LteDL().generatePrecoder(params.transmissionParameters.DL, BS.antennaList);

%% initialize scheduler
% create a scheduler for the example base station
s = scheduler.Scheduler.generateScheduler(params, BS, sinrAverager);

%% simulate
fprintf('      \n');

% attach users to the base station
s.updateAttachedUsers(UE(1:nUE-1));
t = tic;
nTTi = nUE-1;

% get parameters
nRBFreqDL = params.transmissionParameters.DL.resourceGrid.nRBFreq;
nRBTimeDL = params.transmissionParameters.DL.resourceGrid.nRBTime;

lqmDummy.resourceGrid.nRBFreq = nRBFreqDL;
lqmDummy.resourceGrid.nRBTime = nRBTimeDL;
lqmDummy.antenna.nTX = BS.antennaList.nTX;

% simulate all slots
for i = 1:nTTi
    if toc(t)>.1
        t = tic;
        fprintf('\b\b\b\b\b\b\bi=%5i',i);
    end

    % calculate feedback
    for iUE = 1:nUE
        lqmDummy.receiver.nRX = UE(iUE).nRX;
        UE(iUE).userFeedback.DL.calculateFeedbackSafe(i, lqmDummy, zeros(1,nRBFreqDL,nRBTimeDL), true);
    end

    % schedule users
    s.scheduleDL(i);
end % for all slots

% change user cell association
s.updateAttachedUsers(UE(1:nUE-2));
fprintf('\b\b\b\b\b\b\bi=%i\n',i);

