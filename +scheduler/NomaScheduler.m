classdef NomaScheduler < tools.HiddenHandle
    %NOMASCHEDULER scheduling for NOMA users
    % The scheduleNOMA function schedules the NOMA near user and the NOMA
    % far user to all resources assigned to either user of the NOMA user
    % pair.
    % The function schedulingNOMAcommon sets the dependent scheduler
    % signaling for near users and the the NOMA signaling for near and far
    % users. This function also chooses the NOMA power share factor
    % depending on the CQIs and adjusts the CQI of the far user.
    %
    % NOMA: Non-Orthogonal Multiple Access
    % SIC:  Successive Interference Cancellation
    %
    % see also scheduler.rbGrid, scheduler.signaling.BaseStationNoma,
    % scheduler.signaling.UserScheduling, scheduler.signaling.UserNoma,
    % parameters.setting.MUSTIdx

    properties
        % downlink transmission parameters
        % [1x1]handleObject downlink transmission parameters
        %
        % see also parameters.transmissionParameters.TransmissionParameters
        transmissionParameters

        % feedback delay in multiples of slots
        % [1x1]integer number of slots by which the feedback is delayed
        %
        % see also parameters.Time.feedbackDelay
        feedbackDelay

        % use HARQ
        % [1x1]logical use HARQ for scheduler
        %
        % see also parameters.useHARQ
        useHARQ

        % SINR averager
        % [1x1]handleObject tools.MiesmAverager
        sinrAverager

        % MUST index
        % [1x1]enum parameters.setting.MUSTIdx
        %
        % The power share factor is chosen according to the MUST index and
        % 3GPP TS 36.211 Table 6.3.3-1. MUST index 0 indicates no NOMA
        % transmission, i.e., only OMA transmission.
        %
        % MUST: MultiUser Superposition Transmission
        % NOMA: Non-Orthogonal Multiple Access
        % OMA:  Orthogonal Multiple Access
        %
        % see also parameters.Noma.mustIdx, parameters.setting.MUSTIdx
        mustIdx

        % indicator to abort NOMA transmission if CQI is too low
        % [1x1]logical indicator to abort low channel quality transmission
        %
        % see also parameters.Noma.abortLowCqi
        abortLowCqi

        % power share factor seetings from 3GPP TS 36.211 Table 6.3.3-1
        % [MUSTIDx x ModulationType]double power share factors of NOMA far users
        %
        % MUST: MultiUser Superposition Transmission
        powerShareTable = [	8/10,       32/42,      128/170; ...
            50/58,      144.5/167,	40.5/51; ...
            264.5/289,	128/138,	288/330];
    end

    methods
        function obj = NomaScheduler(params, sinrAverager)
            %NOMASCHEDULER read in parameters and set power share table
            %
            % input:
            %	params: [1x1]handleObject parameters.Parameters

            % take over parameters
            obj.transmissionParameters  = params.transmissionParameters.DL;
            obj.feedbackDelay           = params.time.feedbackDelay;
            obj.mustIdx                 = params.noma.mustIdx;
            obj.abortLowCqi             = params.noma.abortLowCqi;
            obj.useHARQ                 = params.useHARQ;
            obj.sinrAverager            = sinrAverager;
        end

        function scheduleNOMA(obj, attachedBS, rbGrid)
            % set user allocation for NOMA users
            % This functions searches all resources assigned to a NOMA user
            % pair and assigns all resources to both users for a NOMA
            % transmission. NOMA transmission is cancelled if abortLowCqi
            % is activated and the far user CQI is lower than 6.
            %
            % input:
            %   attachedBS: [1x1]handleObject networkElements.bs.BaseStation
            %   rbGrid:     [1x1]handleObject scheduler.rbGrid
            %
            % set properties:
            %   obj.rbGrid.DL.noma.userAllocation
            %   obj.rbGrid.DL.userAllocation
            %
            % see also networkElements.bs.BaseStation.nomaPairs,
            % scheduler.rbGrid.userAllocation,
            % scheduler.signaling.BaseStationNoma.userAllocation

            % [2 x nNOMA]integer user pairs for NOMA transmission
            % (1,:) far user with bad channel condition that will suffer additional interference
            % (2,:) near user with good channel condition that will perform SIC
            nNomaPair = size(attachedBS.nomaPairs, 2);

            if nNomaPair
                for iNomaPair = 1:nNomaPair
                    % get NOMA users
                    farUser     = attachedBS.attachedUsers(attachedBS.nomaPairs(1,iNomaPair));
                    nearUser	= attachedBS.attachedUsers(attachedBS.nomaPairs(2,iNomaPair));
                    % get NOMA user IDs
                    farUserID	= farUser.id;
                    nearUserID	= nearUser.id;

                    if farUser.isActive && nearUser.isActive
                        % find resources allocated to near user
                        farAllocation = find(rbGrid.userAllocation == farUserID);
                        nearAllocation = find(rbGrid.userAllocation == nearUserID);
                        nomaResources = [nearAllocation; farAllocation];

                        % abort NOMA if far user CQI is too low
                        if obj.abortLowCqi
                            farFeedback = farUser.userFeedback.DL.getFeedback(obj.feedbackDelay);
                            if farFeedback.isValid
                                farCQI = scheduler.Scheduler.getOptimumCQI(farFeedback.estimatedCQI, nomaResources, obj.transmissionParameters, obj.sinrAverager, farUser.scheduling.HARQ.codewordRV);
                                if farCQI < 6
                                    % cancel NOMA transmission
                                    continue;
                                end
                            end
                        end

                        % set near user as NOMA user
                        rbGrid.noma.userAllocation(nomaResources) = nearUserID;
                        % overwrite scheduling to set far user in 'normal' scheduling
                        rbGrid.userAllocation(nomaResources) = farUserID;
                    end % if both users have data to transmit
                end % for all NOMA pairs at this base station
            end % if there are NOMA user pairs
        end

        function schedulingNOMAcommon(obj, attachedBS, rbGrid)
            % set dependent scheduling parameters for NOMA signaling (CQI and nCodewords)
            % Choose alpha according to 3GPP TS 36.211 and CQI from
            % feedback. Set NOMA far user CQI=6. Set the NOMA scheduling
            % at the base station and at the NOMA users.
            %
            % input:
            %   attachedBS: [1x1]handleObject networkElements.bs.BaseStation
            %   rbGrid:     [1x1]handleObject scheduler.rbGrid
            %
            % set properties:
            %   obj.rbGrid.DL.nCodewords(nomaRBs)
            %   obj.rbGrid.DL.CQI(nomaRBsCodewords)
            %	obj.rbGrid.DL.noma.CQI(nomaRBsCodewords)
            %	obj.rbGrid.DL.noma.powerShare(nomaRBs)
            %
            % see also scheduler.NomaScheduler.removeFarUser

            % get NOMA pairs
            % [2 x nNOMA]integer user pairs for NOMA transmission
            % (1,:) far user with bad channel condition that will suffer additional interference
            % (2,:) near user with good channel condition that will perform SIC
            nomaPairs	= attachedBS.nomaPairs;
            nNomaPair	= size(nomaPairs, 2);

            if nNomaPair
                for iNomaPair = 1:nNomaPair
                    % get NOMA users
                    farUser     = attachedBS.attachedUsers(nomaPairs(1, iNomaPair));
                    nearUser	= attachedBS.attachedUsers(nomaPairs(2, iNomaPair));

                    % get RB allocated to this NOMA pair
                    nomaRBs = find(rbGrid.noma.userAllocation == nearUser.id);
                    nNomaRB = size(nomaRBs, 1);

                    if nNomaRB
                        % get NOMA scheduling
                        % get feedback for this user pair
                        nearFeedback	= nearUser.userFeedback.DL.getFeedback(obj.feedbackDelay);

                        % initialize CQIs
                        nearCQI	= zeros(nNomaRB, obj.transmissionParameters.maxNCodewords);

                        if nearFeedback.isValid
                            % set number of codewords
                            [nomaNearLayer, nomaNearCodewords] = obj.transmissionParameters.layerMapping.decideForNLayer(...
                                nearUser.txMode.DL, nearFeedback.rankIndicator);
                            % get CQI of near user
                            nearCQI = scheduler.Scheduler.getOptimumCQI(nearFeedback.estimatedCQI, nomaRBs, obj.transmissionParameters, obj.sinrAverager, nearUser.scheduling.HARQ.codewordRV);
                            % get modulation order of used MCS
                            nearModulationType	= obj.transmissionParameters.cqiParameters.getModulationType(nearCQI(1,:));

                            % set power share factor for each layer according to modulation scheme
                            alpha = zeros(nomaNearLayer, 1);
                            layerMapping = obj.transmissionParameters.layerMapping.getMapping(nomaNearCodewords, nomaNearLayer);
                            for iCodeword = 1:nomaNearCodewords
                                alpha(layerMapping{iCodeword}) = obj.powerShareTable(obj.mustIdx, max(1, nearModulationType(iCodeword)-1));
                            end

                            % set nLayers and precoder for near user
                            rbGrid.nLayers(nomaRBs) = nomaNearLayer;
                            if nomaNearLayer == 1
                                %NOTE: this assumes that maxNCodewords = 2
                                % If the near user has only one layer, we need to check
                                % that the far user uses at most one codeword,
                                % otherwise the far user runs into problems trying to
                                % decode more codewords than there are layers.
                                rbGrid.nCodewords(nomaRBs) = 1;
                            end % if only one layer is used by the NOMA near user

                            % set precoder
                            scheduler.Scheduler.setPrecoder(attachedBS, rbGrid, nomaRBs, nearFeedback);
                        else
                            % feedback of near user is not valid - use robust configuration
                            nomaNearCodewords	= 1;
                            nearCQI(:, 1)       = 1;
                            nomaNearLayer       = 1;
                            alpha               = obj.powerShareTable(obj.mustIdx, 1);

                            rbGrid.nLayers(nomaRBs) = nomaNearLayer;
                            rbGrid.nCodewords(nomaRBs) = 1;

                            % set precoder
                            for iAntenna = 1:attachedBS.nAnt
                                nTX	= attachedBS.antennaList(iAntenna).nTX;
                                rbGrid.precoder(iAntenna, nomaRBs) = struct('W', ones(nTX,1)/sqrt(nTX));
                            end
                        end

                        % find linear indices of the assigned RBs within CQI
                        nRBFreq	= obj.transmissionParameters.resourceGrid.nRBFreq;
                        nRBTime	= obj.transmissionParameters.resourceGrid.nRBTime;
                        nomaRBsCodewords = tools.ind2BigInd(nomaRBs, [nRBFreq, nRBTime], obj.transmissionParameters.maxNCodewords);

                        maxLayer = max(rbGrid.nLayers(:));
                        alpha_ = zeros(1, maxLayer);
                        alpha_(1, 1:nomaNearLayer) = alpha;
                        nomaRBsLayers = tools.ind2BigInd(nomaRBs, [nRBFreq, nRBTime], maxLayer);

                        % set NOMA scheduling information at the base station
                        rbGrid.noma.nCodewords(nomaRBs)          = nomaNearCodewords;
                        rbGrid.noma.CQI(nomaRBsCodewords)        = nearCQI;
                        rbGrid.CQI(nomaRBsCodewords)             = 6;
                        rbGrid.noma.powerShare(nomaRBsLayers)	= repmat(1 - alpha_, nNomaRB, 1);

                        % set scheduling at the user
                        nearUser.scheduling.setNomaNearUserScheduling(rbGrid, nearUser.id, nomaRBs);

                        % set new CQI and power share for NOMA resources at far user
                        farUser.scheduling.nomaPowerShare	= alpha;
                        farUser.scheduling.CQI(:,:)         = 6;
                        farUser.scheduling.nLayer           = nomaNearLayer;
                        farUser.scheduling.nCodeword        = nomaNearCodewords;
                    end % if this NOMA pairs has RBs scheduled
                end % for all NOMA pairs
            end
        end
    end
end

