classdef Scheduler < tools.HiddenHandle & matlab.mixin.Heterogeneous
    % abstract scheduler superclass
    % The scheduler allocates physical resources (represented by the
    % resource grid) to the users attached to its base station. Each
    % scheduler corresponds to a base station (which corresponds to a cell)
    % and serves users on physical resources: resource blocks. Each
    % resource block consists of several OFDM symbols and the resource
    % block is the scheduling unit for which a different user, transmit
    % power, precoder, CQI, and number of codewords can be scheduled.
    %
    % initial author: Thomas Dittrich
    %
    % see also scheduler.RoundRobinScheduler, scheduler.BestCQIScheduler,
    % scheduler.rbGrid, scheduler.signaling, parameters.resourceGrid,
    % scheduler.spectrumScheduler, feedback, linkQualityModel,
    % linkPerformanceModel

    properties (SetAccess = protected)
        % struct that contains a list of users served by this scheduler
        % [1 x nUserAttached]handleObject networkElements.ue.User attached users
        %NOTE: it is necessary to have an additional list to the one at the
        %base station in order for the round robin scheduler to update its
        %nonHarqLastScheduledDL and unscheduledResourcesDL properties.
        attachedUsers

        % base station to which this instance of the scheduler is attached
        %
        % [1x1]handleObject networkElements.bs.Basestation
        %
        % see also networkElements.bs.Basestation
        attachedBS

        % transmission parameters
        % [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        %
        % see also parameters.transmissionParameters.TransmissionParameters
        transmissionParameters

        % NOMA scheduling
        % [1x1]handle scheduler.NomaScheduler
        %
        % see also parameters.Noma, scheduler.NomaScheduler
        nomaScheduler

        % scheduling decisions
        % [1x1]struct scheduling decisions for each resource block
        %   DL:	[1x1handleOobject scheduler.rbGrid
        %
        % see also scheduler.rbGrid
        rbGrid

        % feedback delay in slots
        % [1x1]integer feedback delay in slots
        %
        % see also parameters.Time.feedbackDelay
        feedbackDelay

        % use HARQ
        % [1x1]logical use HARQ for scheduler
        %
        % see also parameters.Parameters.useHARQ
        useHARQ

        % SINR averager
        % [1x1]handleObject tools.MiesmAverager
        %
        % see also tools.MiesmAverager
        sinrAverager
    end

    methods (Abstract)
        % assign resources to users according to the chosen scheduling strategy
        % This function sets the user in the rbGrid and calls
        % scheduleDLCommon to set all dependent scheduling parameters
        % (power allocation, precoder, CQI, number of codewords used).
        %
        % input:
        %   currentTime:    [1x1]integer slot index
        %
        % see also scheduler.rbGrid, scheduler.signaling, rbGrid
        scheduleDL(obj, currentTime)

        % re-set the users that are served by this scheduler
        %
        % input:
        %   newUserList: [1 x nUser]handleObject users to be attached to this scheduler
        %
        % see also attachedUsers
        updateAttachedUsers(obj, newUserList)
    end

    methods (Access = protected)
        function obj = Scheduler(params, attachedBS, sinrAverager)
            % superclass constructor for all schedulers
            %
            % input:
            %   params:         [1x1]handleObject parameters.Parameters
            %   attachedBS:     [1x1]handleObject networkElements.bs.BaseStation
            %   sinrAverager:   [1x1]handleObject tools.MiesmAverager

            %% general initialization
            obj.attachedBS   = attachedBS;
            obj.sinrAverager = sinrAverager.DL;

            %% NOMA scheduler
            obj.nomaScheduler = scheduler.NomaScheduler(params, sinrAverager.DL);

            %% DL initialization
            obj.rbGrid.DL = scheduler.rbGrid(...
                obj.attachedBS, ...
                params.transmissionParameters.DL.resourceGrid.nRBFreq, ...
                params.transmissionParameters.DL.resourceGrid.nRBTime, ...
                params.transmissionParameters.DL.maxNCodewords, ...
                params.transmissionParameters.DL.maxNLayer);
            obj.attachedUsers = [];

            % copy config
            obj.feedbackDelay           = params.time.feedbackDelay;
            obj.useHARQ                 = params.useHARQ;
            obj.transmissionParameters	= params.transmissionParameters;
        end

        function scheduleDLCommon(obj, ~)
            % sets the scheduling information according to the user and power allocation set in scheduleDL
            % This sets nLayers, nCodewords, CQI and precoder in
            % scheduler.rbGrid at the base station and the UserScheduling
            % at the user.
            %
            % input:
            %   currentTime: [1x1]integer index of the current time-slot
            %
            % see also scheduler.rbGrid,
            % scheduler.signaling.UserScheduling,
            % networkElements.bs.BaseStation.setDLsignaling

            % get necessary properties
            maxNCodewords	= obj.transmissionParameters.DL.maxNCodewords;
            nRBFreq         = obj.transmissionParameters.DL.resourceGrid.nRBFreq;
            nRBTime         = obj.transmissionParameters.DL.resourceGrid.nRBTime;
            nUser           = length(obj.attachedUsers);
            nAnt            = obj.attachedBS.nAnt;

            % generate masks for quick access
            userRBGridMask     = obj.rbGrid.DL.rbGridMask;
            powerRBGridMask    = permute(repmat(userRBGridMask,1,1,nAnt),[3,1,2]);

            % set allocated Power for each rb in the antenna
            % get the number of scheduled resource blocks at each time
            % instance
            nScheduledInFreq = sum(obj.rbGrid.DL.rbGridMask,1);
            powerFactor       = 1./nScheduledInFreq;
            % get transmitpower at each antenna
            transmitPowers    = [obj.attachedBS.antennaList.transmitPower];
            % powerAllocation matrix for all antennas
            powerRBTime       = transmitPowers' * powerFactor;
            powerRBTIme       = permute(powerRBTime,[1,3,2]);
            powerAllocation   = repmat(powerRBTIme,1,obj.transmissionParameters.DL.resourceGrid.nRBFreq,1);
            obj.rbGrid.DL.powerAllocation(powerRBGridMask) = powerAllocation(powerRBGridMask);

            % set scheduling information for users and base stations
            %NOTE: in case of a NOMA transmission, this sets the scheduling
            %for far users and OMA users. The near NOMA users are included
            %in the loop, but don't have resources allocated in the regular
            %scheduling and thus will be skipped in the line
            % if obj.attachedUsers(iUser).scheduling.nRBscheduled
            %The near NOMA user scheduling is then performed in an extra
            %step after the loop.
            for iUser = 1:nUser

                % get indices of RBs assigned to this user
                obj.attachedUsers(iUser).scheduling.setUserAllocation(obj.rbGrid.DL.userAllocation, obj.attachedUsers(iUser).id);
                assignedRBs = obj.attachedUsers(iUser).scheduling.assignedRBs;

                if obj.attachedUsers(iUser).scheduling.nRBscheduled

                    % get feedback for this user
                    feedback = obj.attachedUsers(iUser).userFeedback.DL.getFeedback(obj.feedbackDelay);

                    % find linear indices of the assigned RBs within CQI
                    assignedRBsCodewords = tools.ind2BigInd(assignedRBs, [nRBFreq, nRBTime], maxNCodewords);
                    %repmat(assignedRBs,[maxNCodewords 1])+max(kron(nRBTot*eye(maxNCodewords),ones(length(assignedRBs),1))*(0:maxNCodewords-1)',[],2);

                    if feedback.isValid

                        % set nLayers and nCodewords
                        [obj.rbGrid.DL.nLayers(assignedRBs), obj.rbGrid.DL.nCodewords(assignedRBs)] = obj.transmissionParameters.DL.layerMapping.decideForNLayer(...
                            obj.attachedUsers(iUser).txMode.DL,  feedback.rankIndicator);

                        % set CQI
                        codewordRV     = obj.attachedUsers(iUser).scheduling.HARQ.codewordRV;
                        nCodewords     = size(feedback.estimatedCQI,3);
                        %NOTE: here the same CQI for each codeword is set
                        obj.rbGrid.DL.CQI(assignedRBsCodewords) = obj.getOptimumCQI(feedback.estimatedCQI, assignedRBs, obj.transmissionParameters.DL, obj.sinrAverager, codewordRV);

                        % overwirtes the CQI in case HARQ is activated
                        % the used CQI is the CQI that was used by the
                        % scheduler during the original transmission slot
                        for iCW = 1: nCodewords
                            if codewordRV(iCW) > 0
                                indiciesFirstCodeword = assignedRBsCodewords(1:length(assignedRBs));
                                indiciesSecondCodeword = assignedRBsCodewords(length(assignedRBs)+1:end);
                                switch iCW
                                    case 1
                                        obj.rbGrid.DL.CQI(indiciesFirstCodeword)  = obj.attachedUsers(iUser).scheduling.getUserCQI(obj.feedbackDelay,iCW);
                                    case 2
                                        obj.rbGrid.DL.CQI(indiciesSecondCodeword) = obj.attachedUsers(iUser).scheduling.getUserCQI(obj.feedbackDelay,iCW);
                                end
                            end
                        end

                        % set precoder
                        scheduler.Scheduler.setPrecoder(obj.attachedBS, obj.rbGrid.DL, assignedRBs, feedback);
                    else
                        % if no valid feedback available => use most robust configuration
                        %NOTE: The precoder, nLayers and nCodewords is
                        %already set to the most robust configuration by
                        %default and by the rbGrid.reset function.
                        obj.rbGrid.DL.CQI(assignedRBsCodewords) = 1;
                    end % if the feedback is valid
                end % if this user has resources

                % set user signaling
                obj.attachedUsers(iUser).scheduling.setUserScheduling(obj.rbGrid.DL, maxNCodewords, obj.useHARQ);

            end %for all users attached to this base station

            % set the NOMA scheduling - this can overwrite the scheduling
            obj.nomaScheduler.schedulingNOMAcommon(obj.attachedBS, obj.rbGrid.DL);

            % write scheduling information to attached BS
            obj.attachedBS.setDLsignaling(obj.rbGrid.DL);
        end

        function [allocatedRB, harqUsers] = updateHARQMaskDL(obj, activeUEs)
            % if a user needs a retransmission, some RBs would be allocated
            % for it. This function updates the RB grid mask in the downlink such that
            % allocated RBs are not accessible to other users
            %
            % input:
            %   activeUsers: [1 x nUserActive]handleObject networkElements.ue.Use
            %
            % initial author: Areen Shiyahin

            harqUsers = [];
            allocatedRB = [];

            if obj.useHARQ

                % get number of active users
                nUser  = length(activeUEs);

                for iUser = 1:nUser
                    % get feedback for this user
                    feedback = activeUEs(iUser).userFeedback.DL.getFeedback(obj.feedbackDelay);

                    if feedback.isValid
                        userRVs = activeUEs(iUser).scheduling.HARQ.initiateRetransmission(feedback.ack);
                        if any(userRVs> 0)
                            retransmissionRBs = activeUEs(iUser).scheduling.getUserAllocation(obj.feedbackDelay);
                            obj.rbGrid.DL.userAllocation(retransmissionRBs) = activeUEs(iUser).id;

                            % get ids of users which need retransmission to ensure they
                            % will not be scheduled on other resources
                            harqUsers = [harqUsers(:)', activeUEs(iUser)];
                        end
                    end
                end

                % set rbGridMask
                allocatedRB = find(obj.rbGrid.DL.userAllocation ~= -1);
                obj.rbGrid.DL.rbGridMask(allocatedRB) = false;
            end
        end

        function resetHARQMaskDL(obj, allocatedRB, unusedRBs)
            % reset the resource grid mask after the user allocation is
            % done all users
            %
            % input:
            %   allocatedRB:    [1 x nUserActive]handleObject networkElements.ue.Use
            %   unusedRBs:      [1 x nUnusedRBs]double indices of RBs where no users are scheduled
            %
            % initial author: Areen Shiyahin

            if obj.useHARQ
                % reset the resource grid mask
                obj.rbGrid.DL.rbGridMask(allocatedRB) = true;

                % when only users that need retransmissions are scheduled on
                % RB grid, some RBs are left unused
                obj.rbGrid.DL.rbGridMask(unusedRBs) = false;
            end
        end

        function activeUsers = getActiveUsers(obj)
            % return all users with traffic in the traffic buffer
            %
            % output:
            %   activeUsers: [1 x nUserActive]handleObject networkElements.ue.User

            if ~isempty(obj.attachedUsers)
                % traffic models for the users
                userTrafficModels = [obj.attachedUsers.trafficModel];
                % filter queue for active users
                isActive = [userTrafficModels.isActive];
                activeUsers = obj.attachedUsers(isActive);
            else
                activeUsers = [];
            end
        end
    end

    methods (Access = public)
        function user = getUserWithID(obj, id)
            % returns user attached to this base station with given ID
            %
            % input:
            %   id: [1x1]integer ID of user to return
            %
            % output:
            %   user:   [1x1]handleObject networkElements.ue.User

            user = obj.attachedBS.attachedUsers([obj.attachedBS.attachedUsers.id] == id);
        end

        function scheduleDLDummy(obj)
            % simplified scheduler for interference region base stations
            %
            % This function randomly allocates the attached users and sets
            % the scheduling properties to simple values:
            %   - resource blocks are randomly allocated to attached users
            %   - power allocation is set to antenna.transmitPower/nRBFreq
            %   if users are attached
            %   - random precoder is used
            %
            % The traffic at each user is not considered here since no
            % attached user should be in the ROI and thus no attached user
            % should really be simulated. HARQ is not implemented
            % since no retransmissions should be done for users in the interference
            % region

            % get parameters
            nRBFreq         = obj.transmissionParameters.DL.resourceGrid.nRBFreq;
            nRBTime         = obj.transmissionParameters.DL.resourceGrid.nRBTime;
            nAntenna        = obj.attachedBS.nAnt;
            nUser           = length(obj.attachedUsers);
            maxNCodewords	= obj.transmissionParameters.DL.maxNCodewords;

            % initialize resource grid
            obj.rbGrid.DL = scheduler.rbGrid(obj.attachedBS, nRBFreq, nRBTime, maxNCodewords, obj.transmissionParameters.DL.maxNLayer);

            % set CQI to most robust configuration
            obj.rbGrid.DL.CQI(:) = 1;

            % set random precoder
            for iAnt = 1:nAntenna
                obj.rbGrid.DL.precoder(iAnt, 1:nRBFreq, 1:nRBTime) = reshape(precoders.PrecoderRandom.calculateRandomPrecoder(obj.rbGrid.DL.nLayers(:), obj.attachedBS.antennaList(iAnt).nTX), nRBFreq, nRBTime);
            end

            % set  user allocation
            if ~isempty(obj.attachedUsers)
                % random user allocation
                obj.rbGrid.DL.userAllocation = reshape([obj.attachedUsers(randi([1 length(obj.attachedUsers)],nRBFreq,nRBTime)).id], nRBFreq, nRBTime);

                % set power allocation for all antennas
                obj.rbGrid.DL.powerAllocation = [obj.attachedBS.antennaList.transmitPower].' ./ (nRBFreq * ones(nAntenna, nRBFreq, nRBTime));

            end % if any users are attached to this base station

            % set scheduler signaling for each user
            for iUser = 1:nUser
                % get indices of RBs assigned to this user
                obj.attachedUsers(iUser).scheduling.setUserAllocation(obj.rbGrid.DL.userAllocation, obj.attachedUsers(iUser).id);
                obj.attachedUsers(iUser).scheduling.setUserScheduling(obj.rbGrid.DL, maxNCodewords, obj.useHARQ);
            end

            % set signaling at base station
            obj.attachedBS.setDLsignaling(obj.rbGrid.DL);
        end
    end

    methods (Static)
        function obj = generateScheduler(params, attachedBS, sinrAverager)
            % GENERATESCHEDULER calls the constructor of the scheduler type
            % that is given in config.schedulerParameters.type
            %
            % input:
            %   params:       [1x1] parameters.Parameters
            %   attachedBS:   [1x1] networkElements.bs.BaseStation
            %   sinrAverager: [1x1] tools.MiesmAverager

            % handle compositeBasestation differently
            if isa(attachedBS,'networkElements.bs.CompositeBasestation')
                switch params.spectrumSchedulerParameters.type
                    case parameters.setting.SpectrumSchedulerType.none
                        obj = scheduler.spectrumScheduler.None(params, attachedBS, sinrAverager);
                    case parameters.setting.SpectrumSchedulerType.static
                        obj = scheduler.spectrumScheduler.Static(params, attachedBS, sinrAverager);
                    case parameters.setting.SpectrumSchedulerType.dynamicUser
                        obj = scheduler.spectrumScheduler.DynamicUser(params, attachedBS, sinrAverager);
                    case parameters.setting.SpectrumSchedulerType.dynamicTraffic
                        obj = scheduler.spectrumScheduler.DynamicTraffic(params, attachedBS, sinrAverager);
                    otherwise
                        error('SCHEDULER:notDefined', 'SpectrumScheduler is not defined, see parameters.setting.SpectrumSchedulerType for available options.');
                end
                return;
            end

            if isa(attachedBS,'networkElements.bs.BaseStation')
                switch params.schedulerParameters.type
                    case parameters.setting.SchedulerType.roundRobin
                        obj = scheduler.RoundRobinScheduler(params, attachedBS, sinrAverager);
                    case parameters.setting.SchedulerType.bestCqi
                        obj = scheduler.BestCQIScheduler(params, attachedBS, sinrAverager);
                    otherwise
                        error('SCHEDULER:notDefined', 'Scheduler is not defined, see parameters.setting.SchedulerType for available options.');
                end
                return;
            end

            % if its not a BaseStation nor a Composite BaseStation it is
            % unknown therefore throw an error
            error('SCHEDULER:notDefined', ['Basestation class is not defined for scheduler to basestation mapping, ',...
                'consider options specified in scheduler.Scheduler.generateScheduler']);
        end

        function setPrecoder(BS, rbGrid, assignedRBs, feedback)
            % set precoder in rbGrid for assignedRBs according to feedback
            % Sets precoder in all assigned resource blocks for all
            % antennas.
            %
            % input:
            %   BS:             [1x1]handleObject base station
            %   rbGrid:         [1x1]handleObject scheduler.rbGrid
            %   assignedRBs:    [nRBs x 1]integer indices of assigned resources
            %   feedback:       [1x1]object feedback of this user

            % set precoder
            for iAntenna = 1:BS.nAnt
                rbGrid.precoder(iAntenna, assignedRBs) = BS.precoder.DL.getPrecoder(...
                    assignedRBs, ...
                    rbGrid.nLayers(assignedRBs),...
                    BS.antennaList,...
                    feedback, ...
                    iAntenna);
            end % for all antennas of this base station
        end

        function tbSizeBits = getTBSizeBits(...
                transmissionParameters, assignedRBs, nLayers, nCodewords, iSlot, nTX, cqi)
            % GETTBSIZEBITS calculates the number of data bits that are
            % contained in the list of assigned RBs. The inputs
            % cqiParameters, resourceGrid, layerMapping and nCRCBits are
            % required so that this function can be used in UL and DL and
            % also for Scheduler and LinkPerformanceModel.
            %
            % input:
            %   transmissionParameters:	[1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   assignedRBs:            [Nx1]integer number indices of RBs within one time-frequency grid
            %   nLayers:                [1x1]integer specifying the number of transmission layers
            %   nCodewords:             [1x1]integer specifying the number of transmitted codewords
            %   iSlot:                  [1x1]integer time index of the current simulation slot
            %   nTX:                    [1x1]integer number of transmit antennas
            %   cqi:                    [NxnCodewords]integer specifying the used CQI. If this parameter is omitted the tbSize will be calculated for all possible CQIs.
            %                                         N can either be 1 if this parameter exist and cqiParameters.nCqi when the input parameter cqi is omitted
            %
            % output:
            %   tbSizeBits: [N x nCodewords] integer (N can either be cqiParameters.nCqi or 1 depending on whether the input
            %     parameter cqi is omitted or not) number of data bits that are contained in the assigned RBs. If the cqi is
            %     omited there will be one value for each possible cqi and all codewords

            nCRCBits        = transmissionParameters.nCRCBits;
            layerMapping	= transmissionParameters.layerMapping;
            resourceGrid	= transmissionParameters.resourceGrid;
            cqiParameters	= transmissionParameters.cqiParameters;

            tbSizeBits = 0;
            nAssignedRBs = length(assignedRBs);
            if nAssignedRBs > 0

                if exist('cqi','var')
                    cqi = cqi(1,1:nCodewords);
                else
                    cqi = repmat((0:(cqiParameters.nCqi-1))',[1 nCodewords]);
                end

                % reshape is necessary for the case when CQI is a column vector to get a column vector here
                modulationOrder = reshape(cqiParameters.getModulationOrder(cqi), size(cqi));
                codingRate      = reshape(cqiParameters.getCodingRateX1024(cqi)/1024, size(cqi));

                iRBFreq = mod((assignedRBs-1), resourceGrid.nRBFreq) + 1;
                nDataSymbols = transmissionParameters.getNDataSymbols(iSlot, iRBFreq, nTX);
                tbSizeBits   = max(8*round(1/8*nDataSymbols .* modulationOrder .* codingRate)-nCRCBits,0);
                nLayersPerCodeword = layerMapping.getNLayersPerCodeword(nCodewords,nLayers);
                tbSizeBits = tbSizeBits .* repmat(nLayersPerCodeword,[size(cqi,1) 1]);
            end
        end

        function averagedCqi = getOptimumCQI(cqi, assignedRBs, configUlDl, sinrAverager, rv)
            % GETOPTIMUMCQI searches for the highest CQI value that
            % achieves a certain threshold on the BLER when used for all
            % the scheduled RBs. This CQI averaging is done for each
            % codeword. In case of a retransmission, this avergaing is not
            % required since the required CQI is the same CQI that was used by the
            % scheduler during the original transmission slot
            %
            % input:
            %	cqi:            [nAssignedRB x nCodewords] integer list of cqi values that need to be averaged
            %   assignedRBs:    []
            %	configUlDL: [1x1] struct with fields maxNCodewords, cqiParameters, sinrAverager and blerCurves
            %     -maxNCodewords:	[1x1] integer maximum Number of codewords that is allowed
            %     -cqiParameters:	[1x1] parameters.transmissionParameters.CqiParameters
            %     -blerCurves:      [1x1] linkPerformanceModel.BlerCurves
            %   sinrAverager:	    [1x1] tools.MiesmAverager
            %   rv:                 [1 x nCodewords]double redundancy version used for the
            %                              retransmission of codewords
            %
            % output:
            %   averagedCqi: [nAssignedRB x configUlDl.maxNCodewords] integer list of averaged cqi values. Codewords for which no cqi is specified are filled with zero

            % the CQI is set to the same value for each RB, it can be
            % different per codeword though
            averagedCqi     = zeros(length(assignedRBs), configUlDl.maxNCodewords);
            cqiParameters   = configUlDl.cqiParameters;
            blerCurves      = configUlDl.blerCurves;

            for iCodeword = 1:size(cqi,3) % this is nCodewords
                % convert CQI values to SINR
                codewordCQI = cqi(:,:,iCodeword);
                % map CQI values to median SINR values for this CQI
                sinr = cqiParameters.cqiToSinr(codewordCQI(assignedRBs),rv(iCodeword));
                % get an average sinr for each codeword and CQI
                cqiSpecificSinr = sinrAverager.average(sinr, 0:(cqiParameters.nCqi-1));
                % get BLER for average sinr
                cqiSpecificBler = blerCurves.getBler(cqiSpecificSinr, 1:cqiParameters.nCqi,rv(iCodeword));
                % look for highest CQI that fulfills the BLER threshold
                averagedCqi(:,iCodeword) = find(cqiSpecificBler <= cqiParameters.mapperBlerThreshold, 1, 'last') - 1;
            end
        end
    end
end

