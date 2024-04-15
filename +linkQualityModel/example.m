function postEqSinr = example()
% returns and displays the post equalization SINR for one user for 3 slots
%   This functions shows how to use the linkQualityModel package.
%   In the first part this function shows, what network elements are
%   necessary for the link quality model. In the second part the link
%   quality model class is set up and the post equalization SINR is
%   calculated for the first slot in the first segment of model parameters
%   for the next slot and calculates the SINR for this new slot. In the
%   fourth part small and macro scale parameters are updated for a new
%   segment and the link quality model object is set accordingly to finally
%   calculate the SINR values for the first slot in the second segment.
%
% output:
%   postEqSinr:     [nLayers x nRBFreq x nRBTime]double SINR for each RB
%
% RB: Resource Block
% SINR: Signal to Interference and Noise Ratio
%
% see also linkQualityModel.LinkQualityModel
%
% initial author: Agnes Fastenbauer

%% 1 - SETUP - set parameters and setup network elements

% the slot index is used to read the small scale fading out of the channel trace,
iSlot = 1; % index of current slot

% set simulation parameters
Parameters = parameters.Parameters;
Parameters.transmissionParameters.DL.txModeIndex = 1;
Parameters.setDependentParameters();
nRBFreqDL = Parameters.transmissionParameters.DL.resourceGrid.nRBFreq;
nRBTimeDL = Parameters.transmissionParameters.DL.resourceGrid.nRBTime;

% set network elements
[BSs, UE, antennaBSmapper] = networkElements.example;
AntennaList = [BSs.antennaList];
nAnt = length(AntennaList);

% get schedulers
nBS = length(BSs);
lqmDummy.resourceGrid.nRBFreq = nRBFreqDL;
lqmDummy.resourceGrid.nRBTime = nRBTimeDL;
for iBS = 1:nBS
    scheduling = scheduler.quick.getScheduler(Parameters, BSs(iBS), UE);
    scheduling.updateAttachedUsers(UE);
    lqmDummy.receiver.nRX = UE.nRX;
    lqmDummy.antenna.nTX = BSs(iBS).antennaList.nTX;
    for iUE = 1:length(UE)
        UE(iUE).userFeedback.DL.calculateFeedbackSafe(1, lqmDummy, zeros(1,nRBFreqDL,nRBTimeDL), true);
    end
    scheduling.scheduleDL(iSlot);
end
% set up small scale fading container
Container = smallScaleFading.PDPcontainer.setupContainer(Parameters, BSs, UE);

% calcualte macroscopic loss, small scale fading and assigned RBs
H_array = Container.getChannelForAllAntennas(UE, AntennaList, iSlot);
%NOTE: those are very random values
macroscopicPathLoss      = tools.dBto(-50)* ones(1, nAnt);

% For this example we use the first antenna as the one with the desired
% signal, the others are interferers. We choose the desired antennas
% arbitrarily here, in the simulation, this should depend on the cell
% association, more than one antenna can transmit desired signal.
desired = false(1, nAnt);
desired(1) = true;

%% 2 - CLASS CONSTRUCTION AND 1st SINR CALCULATION - generation, initialization and calculation of SINR for first slot in first segment
% setup link quality model class
iniCache = linkQualityModel.ini.IniCache(Parameters.transmissionParameters.DL.resourceGrid, 0);
LQM = linkQualityModel.ZeroForcing(Parameters, Parameters.transmissionParameters.DL.resourceGrid, antennaBSmapper, iniCache);
LQM.setLinkParameters(AntennaList, UE);
% set macroscopic parameters for this segment
LQM.updateMacroscopic(desired, macroscopicPathLoss);
% set small scale parameters for this segment
LQM.updateSmallScale(H_array);
% calculate SINR for first slot
postEqSinr1 = LQM.getPostEqSinr;
% disp('post equalization SINR for 1st Slot in 1st Segment: ');
% disp(postEqSinr1);

%% 3 - SLOT UPDATE - update for new slot and calculation of SINR of second slot in first segment
% move forward to the next slot
iSlot = iSlot + 1;
% update small scale parameters
H_array = Container.getChannelForAllAntennas(UE, AntennaList, iSlot);
for iBS = 1: nBS
    scheduling = scheduler.quick.getScheduler(Parameters, BSs(iBS), UE);
    scheduling.updateAttachedUsers(UE);
    for iUE = 1:length(UE)
        UE(iUE).userFeedback.DL.clearFeedbackBuffer();
        UE(iUE).userFeedback.DL.calculateFeedbackSafe(1, LQM, postEqSinr1, true);
    end
    scheduling.scheduleDL(iSlot);
end
% set new small scale parameters
LQM.updateSmallScale(H_array);
% calculate SINR for second slot
postEqSinr2 = LQM.getPostEqSinr;
% disp('post equalization SINR for 2nd Slot in 1st Segment: ');
% disp(postEqSinr2);

%% 4 - SEGMENT UPDATE - update for new segment and calculation of SINR for first slot in second segment
% move forward to next segment
iSlot = iSlot +  Parameters.time.timeBetweenChunksInSlots;
% update macroscale parameters
macroscopicPathLoss = tools.dBto(-60) * ones(1, nAnt);
macroscopicPathLoss(1,1) =  tools.dBto(-30);

% set new macroscopic parameters for second segment
LQM.updateMacroscopic(desired, macroscopicPathLoss);
% update small scale parameters for new slot
H_array = Container.getChannelForAllAntennas(UE, AntennaList, iSlot);
for iBS = 1: nBS
    scheduling = scheduler.quick.getScheduler(Parameters, BSs(iBS), UE);
    scheduling.updateAttachedUsers(UE);
    for iUE = 1:length(UE)
        UE(iUE).userFeedback.DL.clearFeedbackBuffer();
        UE(iUE).userFeedback.DL.calculateFeedbackSafe(2, LQM, postEqSinr2, true);
    end
    scheduling.scheduleDL(iSlot);
end
% set new small scale parameters for first slot in second segment
LQM.updateSmallScale(H_array);
% calculate SINR for first slot in second segment
postEqSinr = LQM.getPostEqSinr;
% disp('post equalization SINR for 1st Slot in 2nd Segment: ');
% disp(postEqSinr);
end

