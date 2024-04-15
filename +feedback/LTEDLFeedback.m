classdef LTEDLFeedback < feedback.Feedback
    %LTEDLFEEDBACK downlink feedback according to LTE standard
    % This class collects all calculation functions for LTE DL feedback.
    %
    % initial author: Thomas Dittrich
    % extended by: Erik Sausa
    %
    % see also feedback.FeedbackLTE, feedback.Feedback

    methods
        function obj = LTEDLFeedback(feedbackType, cqiParameters, txModeIndex)
            % class constructor - calls superclass constructor
            %
            % input:
            %   feedbackType:   [1x1]enum parameters.setting.FeedbackType
            %   cqiParameters:  [1x1]handleObject parameters.transmissionParameters.CqiParameters
            %   txModeIndex:	[1x1]integer transmit mode

            % call superclass constructor
            obj = obj@feedback.Feedback(feedbackType, cqiParameters, txModeIndex);
        end
    end

    methods (Static, Access = protected)
        function feedbackObject = generateEmptyFeedback()
            % generates an empty feedback object
            %
            % output:
            %   feedbackObject: [1x1]object feedback.FeedbackLTE
            %
            % see also feedback.FeedbackLTE

            feedbackObject = feedback.FeedbackLTE;
        end
    end

    methods (Access = protected)
        function feedbackObject = calculateSimplifiedFeedback(obj, linkQualityModel, sinr)
            % calculate simplified feedback for boundary region users
            %
            % input:
            %   linkQualityModel:	[1x1]handleObject linkQualityModel.LinkQualityModel
            %                    	or [1x1]struct mockup link quality model with fields:
            %                         	-receiver.nRX:  [1x1]integer nRX
            %                       	-antenna.nTX:   [1x1]integer nTX
            %  sinr:                [nLayer x nRBFreq x nRBTime]double post equalization SINR
            %
            % output:
            %   feedback: [1x1]handleObject feedback.FeedbackLTE
            %
            % see also feedback.Feedback, feedback.FeedbackLTE

            % initialize output
            feedbackObject = obj.generateEmptyFeedback();

            % get parameters
            nRBFreq = linkQualityModel.resourceGrid.nRBFreq;
            nRBTime = linkQualityModel.resourceGrid.nRBTime;

            % get rank indicator, channel quality indicator and precoding matrix indicator
            switch obj.txModeIndex
                case 1
                    RI  = 1;
                    CQI = shiftdim(ones(size(sinr)),1);
                    PMI = [];
                case 4
                    RI  = 1;
                    CQI = shiftdim(ones(size(sinr)),1);
                    codebook = obj.precoder.getCodebook(linkQualityModel.antenna);
                    PMI = randi([0 size(codebook{1},3)-1], nRBFreq, nRBTime);
                otherwise
                    error('FEEDBACK:notImplemented','txMode not implemented');
            end % switch transmit mode

            % set feedback
            feedbackObject.txModeIndex	= obj.txModeIndex;
            feedbackObject.rankIndicator = RI;
            feedbackObject.estimatedCQI  = CQI;
            feedbackObject.PMI           = PMI;
            feedbackObject.isValid       = true;
        end

        function [feedbackObject] = calculateFeedback(obj, linkQualityModel, ~)
            % calculate feedback
            %
            % input:
            %   linkQualityModel:	[1x1]handleObject linkQualityModel.LinkQualityModel
            %                    	or [1x1]struct mockup link quality model with fields:
            %                         	-receiver.nRX:  [1x1]integer nRX
            %                       	-antenna.nTX:   [1x1]integer nTX
            %  sinr:                [nLayer x nRBFreq x nRBTime]double post equalization SINR
            %
            % output:
            %   feedback: [1x1]handleObject feedback.FeedbackLTE
            %
            % see also feedback.Feedback, feedback.FeedbackLTE

            % generate empty feedback
            feedbackObject = obj.generateEmptyFeedback();

            % get feedback values
            [RI, CQI, PMI] = obj.getRiCqiPmi(linkQualityModel);

            % set feedback
            feedbackObject(1).txModeIndex	= obj.txModeIndex;
            feedbackObject(1).rankIndicator = RI;
            feedbackObject(1).estimatedCQI  = CQI;
            feedbackObject(1).PMI           = PMI;
            feedbackObject(1).isValid       = true;
        end
    end

    methods (Access = private)
        function [RI, CQI, PMI] = getRiCqiPmi(obj, linkQualityModel)
            % generates RI CQI and PMI feedback values
            % see section 7.2 of TS 36.213
            % This feedback uses the methodologies presented in:
            % S. Schwarz, C. Mehlführer and M. Rupp,
            % "Calculation of the spatial preprocessing and link adaption
            % feedback for 3GPP UMTS/LTE,"
            % 2010 Wireless Advanced 2010, London, 2010, pp. 1-6,
            % doi: 10.1109/WIAD.2010.5544947.
            %
            % input:
            %   linkQualityModel:	[1x1]handleObject linkQualityModel.LinkQualityModel
            %
            % output:
            %   RI:     [1x1]integer rank indicator
            %   CQI:    [nRBFreq x nRBTime x nCodewords]integer channel quality indicator
            %   PMI:    [nRBFreq x nRBTime]integer precoding matrix indicator
            %
            % RI:   Rank Indicator
            % PMI:  Precoding Matrix Indicator
            % CQI:  Channel Quality Indicator
            %
            % see also feedback.FeedbackLTE

            % get parameters
            nRX         = linkQualityModel.receiver.nRX;
            % multiple antennas are considered as one antenna with more nTX Prots
            nTX         = sum([linkQualityModel.antenna(linkQualityModel.desired).nTX]);
            nRBFreq     = linkQualityModel.resourceGrid.nRBFreq;
            % maximum number of layers
            maxRank     = min(nRX, nTX);

            % get a codebook considering all antennas on the BS
            codeBook	= obj.precoder.getCodebook(linkQualityModel.antenna(linkQualityModel.desired));

            % initialize matrices
            % all possible PMIs
            PMI     = zeros(nRBFreq, maxRank);
            % all possible SINRs
            SINR	= NaN(nRBFreq, maxRank*maxRank);
            % averaged SINR for rank indicator calculation
            SINR_RI = zeros(obj.cqiParameters.nCqi-1, maxRank);

            % indices of all possible modulation and coding schemes exclunding CQI=0
            MCSs = 1:(obj.cqiParameters.nCqi-1);

            for iLayer = 1:maxRank
                % calculate PMI and SINR values
                [PMI(:,iLayer), SINR(:,(maxRank*(iLayer-1)+1:maxRank*iLayer))] = obj.calculatePMIlayer(linkQualityModel, iLayer, codeBook{1,iLayer});
            end

            % convert all SINR values to dB
            SinrdB = tools.todB(SINR);

            % average SINR for all possible numbers of layers
            % get a single value per RB for each possible number of layers
            for iLayer = 1:maxRank
                % get layer index
                ind = maxRank*(iLayer-1) + 1;
                % average SINR
                SINR_RI(:,iLayer) = obj.sinrAverager.average(SinrdB(:,(ind:(ind+iLayer-1))),MCSs);
            end % for all possible number of layers

            % set redundancy version of new transmissions to be used in the
            % following sinr to cqi mappings
            newTransmissionRV  = 0;
            % get CQI values for averaged SINRs
            temp_var              = obj.cqiParameters.sinrToCqi(SINR_RI, newTransmissionRV) - repmat(MCSs', 1, maxRank);
            temp_var(temp_var<0)  = Inf;
            [min_vals, CQI_layer_all]    = min(temp_var);
            out_of_range          = CQI_layer_all < 1 | (isinf(min_vals));
            CQI_layer_all(out_of_range) = 1;

            switch nTX
                case 0
                    nRefernceSymbol = 0;
                case 1
                    nRefernceSymbol = 4;
                case 2
                    nRefernceSymbol = 8;
                case 4
                    nRefernceSymbol = 12;
                otherwise
                    nRefernceSymbol = 0;
                    warning('warn:numRefSym', 'Number of reference symbols is not defined for %d TX antennas. No reference symbols are used.',nTX);
                    warning('off','warn:numRefSym');
            end

            % number of symbols per resource block without synchronization symbols
            symPerRBNoSync	= 12*7 - nRefernceSymbol;

            % get number of bits
            bits_layer_config = (1:maxRank).*(8 * round(1/8* obj.cqiParameters.modulationOrder(CQI_layer_all) .* obj.cqiParameters.codingRateX1024(CQI_layer_all) / 1024 * symPerRBNoSync * nRBFreq*2)-24);
            bits_layer_config(out_of_range) = 0;

            % Choose the RI for which the number of bits is maximized
            [~, RI] = max(bits_layer_config);
            % get index of SINR values for optimum rank
            ind = maxRank*(RI-1) + 1;

            % get SINR values for chosen rank indicator
            % if RI > 1 assume two codewords, i.e., report two cqi values for every RB
            switch RI
                case 1
                    SINRs_to_CQI_CWs = SinrdB(:,1);
                case 2
                    SINRs_to_CQI_CWs = SinrdB(:,(ind:ind+1));
                case 3
                    % manually set to two codewords. Layer-to-codeword mapping according to TS 36.211 and done with the last CQI
                    codeword2_SINRs_dB_avg = zeros(nRBFreq,1);
                    for rb = 1:nRBFreq
                        codeword2_SINRs_dB_avg(rb) = obj.sinrAverager.average(SinrdB(rb,((ind+1):(ind+RI-1))), MCSs(end));
                    end
                    SINRs_to_CQI_CWs = [SinrdB(:,ind), codeword2_SINRs_dB_avg];
                case 4
                    % manually set to two codewords. Layer-to-codeword mapping according to TS 36.211
                    codeword1_SINRs_dB_avg = zeros(nRBFreq,1);
                    codeword2_SINRs_dB_avg = zeros(nRBFreq,1);
                    for rb = 1:nRBFreq
                        codeword1_SINRs_dB_avg(rb) = obj.sinrAverager.average(SinrdB(rb,((ind):(ind+RI-3))), MCSs(end));
                        codeword2_SINRs_dB_avg(rb) = obj.sinrAverager.average(SinrdB(rb,((ind+2):(ind+RI-1))), MCSs(end));
                    end
                    SINRs_to_CQI_CWs  = [codeword1_SINRs_dB_avg, codeword2_SINRs_dB_avg];
            end

            % get CQI values from SINR values for the RBs of each codeword and reshape it
            CQI = obj.cqiParameters.sinrToCqi(SINRs_to_CQI_CWs, newTransmissionRV);
            CQI = kron(CQI,[1,1]);
            CQI = reshape(CQI,[nRBFreq, 2, min(2, RI)]);

            % choose PMI, reshape and make sure it is zero indexed as in standards
            PMI = kron(PMI(:,RI), [1,1]) - 1;
        end
    end

    methods (Static)
        function [PMI, SINRchosen] = calculatePMIlayer(linkQualityModel, iLayer, codeBook)
            % calculates the SINR for all possible precoders and chooses optimal PMI
            % This function first calculates the SINR for all possible
            % precoders, then derives the mutual information and chooses
            % the PMI that maximizes the mutual information. The RI is
            % chosen to match the precoder chosen by the PMI.
            %
            % This function implements the PMI and RI feedback described in
            % section III in:
            % S. Schwarz, C. Mehlführer and M. Rupp,
            % "Calculation of the spatial preprocessing and link adaption
            % feedback for 3GPP UMTS/LTE,"
            % 2010 Wireless Advanced 2010, London, 2010, pp. 1-6,
            % doi: 10.1109/WIAD.2010.5544947.
            %
            % input:
            %   linkQualityModel:   [1x1]handleObject linkQualityModel.LinkQualityModel
            %   iLayer:             [1x1]integer number of layers considered
            %   codeBook:           [nTX x nLayer x nPrecoder]complex baseband precoding codebook
            %
            % output:
            %   PMI:        [nRBFreq x 1]integer chosen Precoding Matrix Indicator
            %   SINRchosen: [nRBFreq x maxRank]double chosen SINR for this layer
            %               This is the SINR for which the mutual
            %               information is maximum.

            % get parameters
            desAnt      = linkQualityModel.antenna(linkQualityModel.desired);
            nRX         = linkQualityModel.receiver.nRX;
            nTX         = sum([desAnt.nTX],2);
            nTXelements = sum([desAnt.nTXelements],2);
            nRBFreq     = linkQualityModel.resourceGrid.nRBFreq;
            maxRank     = min(nTX, nRX);

            % get arrays of increasing numbers
            layers      = 1:iLayer;
            txElements	= 1:nTXelements;

            % get transmit powers
            lqmChannels     = linkQualityModel.channel(linkQualityModel.desired);
            channelMatrix	= [lqmChannels.H];

            % instead of LQM use maximum Power of Antenna to estimate
            % channel to calculate feedback on not scheduled resources

            % signal power
            power = [linkQualityModel.antenna.transmitPower];
            power = sum(power(linkQualityModel.desired) ...
                .* linkQualityModel.macroscopicFadingW(linkQualityModel.desired)) ... % sum over desired antennas
                /nRBFreq/iLayer;

            % interference Power
            interference	= sum(linkQualityModel.powerRB(:,:,:,~linkQualityModel.desired),4);

            % ini power
            interference = interference + linkQualityModel.interNumerologyInterference;

            % number of different precoders
            nPrecoder	= size(codeBook, 3);  % codebookmatrix dimensions --> nTXelements * layers * number of precoders

            % get analog precoder
            lqmAnalogPrecoder   = linkQualityModel.precoderAnalog(linkQualityModel.desired);
            % stack diagnonal
            W_a                 = blkdiag(lqmAnalogPrecoder.W_a);

            % generate block matrix version of the precoders
            W_all_block = complex(zeros(nTXelements*nPrecoder, iLayer*nPrecoder));

            % generate the block diagonal matrix containing the precoders
            % in case we use the sparse-optimized function
            for iPrecoder = 1:nPrecoder
                W_cols = (iPrecoder-1)*iLayer       + layers;
                W_rows = (iPrecoder-1)*nTXelements	+ txElements;
                W_all_block(W_rows,W_cols) = W_a * codeBook(:,:,iPrecoder);
            end

            % get sparse version of matrix with all precoders
            W_all_block = sparse(W_all_block);

            %% now calculate mutual information

            % preallocate mutual information matrix
            I           = zeros(nRBFreq, nPrecoder);
            % preallocate SNR matrix
            SINR_all	= NaN(nRBFreq, nPrecoder, iLayer);

            for iRBFreq = 1:nRBFreq

                % create sparse block diagonal matrix with the repeated
                % current channel matrix
                H = channelMatrix(:,:,1,iRBFreq);
                H_t_block = kron(speye(nPrecoder), H);

                % equalize with all of the possible precoders in one step
                % with sparsity and the mldivide operator (faster)
                P_all = H_t_block * W_all_block;

                % find precoders that yield near zero rank MIMO channel matrix
                columnMultiplier = size(W_all_block, 2)/nPrecoder; % needed to handle different precoder sizes for same nTX
                normPrecoded = zeros(1, nPrecoder); % save norms of precoded channel matrices for each precoder
                for iPrecoder = 1:nPrecoder
                    % extract the precoded channel matrix for each precoder
                    H_precoded = P_all( ((iPrecoder-1)*nRX+1):(iPrecoder*nRX), ((iPrecoder-1)*columnMultiplier+1):(iPrecoder*columnMultiplier));
                    normPrecoded(iPrecoder) = norm(full(H_precoded));
                end

                eliminatePrecoder = (normPrecoded < 1e-4);
                nEliminatePrecoder = sum(eliminatePrecoder, 2);

                % check whether all precoders are flagged to be eliminated
                if nEliminatePrecoder == nPrecoder
                    % find least bad precoder
                    [~, indBest] = max(normPrecoded);
                    % remove elimination flag from that precoder
                    eliminatePrecoder(indBest) = 0;
                    % recalculate elimination flag counter (should be 1 here)
                    nEliminatePrecoder = sum(eliminatePrecoder, 2);
                end

                if nEliminatePrecoder > 0 % in case of near zero entries
                    % eliminate unsuitable precoders by deleting the
                    % corresponding entries from P_all

                    %preallocate space for cleaned up version of P_all
                    P_all_clean = zeros((nPrecoder-nEliminatePrecoder)*nRX, (nPrecoder-nEliminatePrecoder)*columnMultiplier);

                    % copy desired parts of P_all to P_all_clean
                    desiredPrecoderCounter = 1; % needed to correctly position the values in P_all_clean

                    for iPrecoder = 1:nPrecoder
                        if ~eliminatePrecoder(iPrecoder) % if this precoder should not be eliminated
                            % copy into P_all_clean
                            P_all_clean( ((desiredPrecoderCounter-1)*nRX+1):(desiredPrecoderCounter*nRX), ...
                                ((desiredPrecoderCounter-1)*columnMultiplier+1):(desiredPrecoderCounter*columnMultiplier)) = ...
                                P_all( ((iPrecoder-1)*nRX+1):(iPrecoder*nRX), ((iPrecoder-1)*columnMultiplier+1):(iPrecoder*columnMultiplier));
                            % increase counter
                            desiredPrecoderCounter = desiredPrecoderCounter + 1;
                        end
                    end

                    % replace P_all with P_all_clean
                    P_all = P_all_clean;
                end
                % get zero forcing receive filter
                % Right now only ZF receiver supported in SL,
                F_all       = (P_all'*P_all) \ P_all'; % ZF receiver
                % equalize
                K_all       = F_all * P_all;
                % put receive powers in diagonal matrix for further calculations
                diag_K_all	= diag(K_all);

                % calculate SINRs
                signal      = power .* reshape(abs(diag_K_all).^2, iLayer, []) .* linkQualityModel.receiver.scheduling.nomaPowerShare(1);
                interferes  = interference(1,iRBFreq,1)	.* reshape(sum(abs(F_all).^2,2), iLayer, []);
                inter_layer = power .* reshape(sum(abs(K_all-diag(diag_K_all)).^2,2), iLayer, []);
                noise       = reshape(linkQualityModel.noise .* sum(abs(F_all).^2,2), iLayer, []); % this is psi
                SINR        = signal ./ (interferes + inter_layer + noise);

                % rate of one resource block for different precoders and this specific rank (nLayers)
                I(iRBFreq,~eliminatePrecoder)   = I(iRBFreq,~eliminatePrecoder) + sum(log2(1+SINR), 1);

                % save calculated SINR
                SINR_all(iRBFreq,~eliminatePrecoder,:) = SINR';
            end

            % calculate precoding matrix indicator
            [~, PMI] = max(I, [], 2);

            % SINR choice
            % selector to only choose the diagonal elements
            diagMask    = logical(repmat(eye(nRBFreq,nRBFreq),[1,1,iLayer]));
            SINRchosen  = SINR_all(:,PMI,:);
            SINRchosen  = SINRchosen(diagMask);
            SINRchosen	= reshape(SINRchosen,[nRBFreq,iLayer]);
            SNR_temp	= NaN(nRBFreq, maxRank-iLayer);
            SINRchosen	= reshape([SINRchosen SNR_temp], [nRBFreq, maxRank]);
        end
    end
end

