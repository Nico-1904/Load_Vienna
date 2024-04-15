classdef LinkPerformanceModel < handle
    % LINKPERFORMANCEMODEL calculates the throughput based on post-equalization SINR and CQI
    %
    % initial author: Thomas Dittrich
    % extended by   : Areen Shiyahin, added ack parameter

    properties (SetAccess = private, GetAccess = public)
        % Used to find a common sinr value based on a list of several values
        % [1x1] tools.MiesmAverager
        sinrAverager

        % transmission parameters
        % [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        transmissionParameters

        % defines the method for how the block error ratio is handled
        % When this variable is set to true, the LPM flips a coin that
        % determines if all bits are correct or none.
        % [1x1]logical determines if a Bernoulli experiment is used to calculate the throughput
        %
        % see also parameters.Parameters.bernoulliExperiment
        useBernoulliExperiment

        % [1x1]logical
        useFeedback

        % [1xnCodeword]logical indicates whether the codewords transmission succeeds or fails
        ack
    end

    methods
        function obj = LinkPerformanceModel(...
                sinrAverager, transmissionParameters, useBernoulliExperiment, useFeedback)
            % LINKPERFORMANCEMODEL instantiates a LinkPerformanceModel for
            % the given sinr averager and codeword to layer mapping.
            %
            % input:
            %   sinrAverager:           [1x1] tools.MiesmAverager
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   useBernoulliExperiment: [1x1]logical parameters.Parameters.useBernoulliExperiment
            %   useFeedback:            [1x1]logical parameters.Parameters.useFeedback

            obj.sinrAverager            = sinrAverager;
            obj.transmissionParameters	= transmissionParameters;
            obj.useBernoulliExperiment	= useBernoulliExperiment;
            obj.useFeedback             = useFeedback;
            obj.ack                     = true(1,transmissionParameters.maxNCodewords);
        end

        function [throughput, throughputBestCqi, effectiveSinr, bler_codeword] = calculateThroughput(obj, ...
                cqi, sinrList, nCodeword, currentTime, assignedRBs, nTX, nLayer, nomaPowerShare,rv)
            % CALCULATETHROUGHPUT calculates the throughput in one simulation slot in bit.
            % The resulting throughput is either determined by means of a
            % Bernoulli experiment or the expected value of the expirement by multiplying
            % the number of transmitted bits with (1-BLER). Then, the throughput
            % is choosen either by taking the BLER of the CQI that was selected
            % by the feedback, or based on an ideal CQI choice whcih results
            % maximum throughput. Which version is used is specified in the constructor.
            %
            % input:
            %   cqi:            [1 x nCodeword]integer list of CQI values for all codewords
            %   sinrList:       [nLayer x nRBscheduled] double list of sinr values for a specific user
            %   nCodeword:      [1x1] integer number of codewords
            %   currentTime:    [1x1] integer specifying the index of the current simulation time-slot
            %   assignedRBs:    [1 x nRBassigned]integer list of RB-indices that are scheduled for a specific user
            %   nTX:            [1x1] integer number of transmit antennas
            %   nLayer:         [1x1]integer number of layers used by this user
            %   rv:             [1xnCodewords]double redundancy version of codewords
            %
            % output:
            %   throughput:         [1x1]double throughput in bit for the assigned RBs
            %   throughputBestCqi:	[1x1]double throughput for the CQI decision that yields the maximum value
            %   effectiveSinr:      [1x1]double effective average SINR in this transmission
            %   bler_codeword:      [1x1]double average block error ratio

            % initialize throughput and BLER values
            throughput          = 0;
            throughputBestCqi	= 0;
            effectiveSinr       = nan;
            bler                = 0;
            bler_codeword       = 0;

            if nCodeword == 0 || isempty(sinrList)
                % when the user is inactive and unscheduled i.e., its packet buffer is empty,
                % acknowledgment of its codewords should be reset because if its buffer is
                % emptied due to successful transmission of one codeword, there is no
                % meaning of carrying on a retransmisson of the second codeword  in the
                % future slots
                obj.ack(:) = true;

                % if this user is not scheduled, we can skip the throughput
                % calculations
                return;
            end

            % get layer mapping for each codeword
            iLayer = obj.transmissionParameters.layerMapping.getMapping(nCodeword, nLayer);

            %% for throughputBestCQI, we need the tbSizes of all CQIs and not just of the scheduled
            tbSizes = zeros(15, nCodeword);
            for cqi_ii = 1:15
                tbSizes(cqi_ii,:) = scheduler.Scheduler.getTBSizeBits(...
                    obj.transmissionParameters, assignedRBs, nLayer,...
                    nCodeword, currentTime, nTX, cqi_ii*ones(size(cqi)));
            end
            % add zero CQI
            tbSizes = [zeros(1, nCodeword); tbSizes];

            for iCodeword = 1:nCodeword
                % get SINRs from layers of current codeword
                sinrListCodeword = sinrList(iLayer{iCodeword},:);

                % calculate effective SINR for all possible CQIs
                yEff = obj.sinrAverager.average(reshape(sinrListCodeword,[],1)', 0:(obj.transmissionParameters.cqiParameters.nCqi-1));

                % get BLER from lookuptable for all possible CQIs and
                % a redundancy version
                blerVec = obj.transmissionParameters.blerCurves.getBler(yEff, 1:obj.transmissionParameters.cqiParameters.nCqi,rv(iCodeword))';

                % calculate throughput for all possible CQIs
                if obj.useBernoulliExperiment
                    isSuccess = rand() > blerVec;
                    throughputVec = isSuccess .* tbSizes(:,iCodeword);
                else
                    throughputVec = (1-blerVec) .* tbSizes(:,iCodeword);
                end

                % choose throughput according to CQI value
                if obj.useFeedback
                    % use the CQI value from the feedback
                    throughput = throughput + throughputVec(cqi(1,iCodeword)+1);

                    % set ack of this codeword to zero if the transmission
                    % fails
                    if throughputVec(cqi(1,iCodeword)+1) == 0
                        obj.ack(iCodeword) = false;
                    else
                        obj.ack(iCodeword) = true;
                    end

                    % set BLER
                    bler = bler + blerVec(cqi(1,iCodeword)+1);

                    if iCodeword == 1
                        effectiveSinr = yEff(cqi(1,iCodeword)+1);
                    end

                    if nomaPowerShare(1) > 0.5 && nomaPowerShare(1) < 1
                        throughputVec = throughputVec(7);
                    end % if this is the NOMA far user

                    % get maximum throughput for bestCQI throughput
                    [maxThroughput, ~] = max(throughputVec);
                else

                    if nomaPowerShare(1) > 0.5 && nomaPowerShare(1) < 1
                        throughputVec = throughputVec(7);
                    end % if this is the NOMA far user

                    % get maximum throughput and CQI index of maximum throughput
                    [maxThroughput, p] = max(throughputVec);

                    % set effective SINR to SINR with maximum throughput
                    effectiveSinr = yEff(p);
                end
                throughputBestCqi = throughputBestCqi + maxThroughput;
            end

            % get average BLER over codewords
            bler_codeword = bler/nCodeword;
        end
    end
end

