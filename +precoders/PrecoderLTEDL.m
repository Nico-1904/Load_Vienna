classdef PrecoderLTEDL < precoders.Precoder
    % LTE downlink precoder
    % Definition of codebook is given in TS 36.211, Table 6.3.4.2.3-1 and
    % Table 6.3.4.2.3-2
    %
    % Compatible with LTEDLFeedback
    % Features: Up to 4 transmit chains and 4 layers.
    %
    % initial author: Thomas Dittrich
    % extended by: Alexander Bokor, added documentation, code cosmetics
    %
    % see also parameters.precoders.LteDL, precoders.Precoder,
    % feedback.LTEDLFeedback

    properties
        % codebook
        % [4x1]cell with codebooks for {1,2,4} transmit antennas
        % [1 x nLayers]cell array with
        % [nTX x nLayers x nPrecoders]complex codebook
        codebook

        % transmit mode
        % [1x1]struct
        txModeIndex
    end

    methods
        function obj = PrecoderLTEDL(transmissionParameters)
            % defines the precoder codebook for all available nTX
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters


            % get transmit mode information
            obj.txModeIndex = transmissionParameters.txModeIndex;

            % preallocate codebook
            obj.codebook = cell(4,1);

            % make sure j is the imaginary unit
            j = 1i;

            %% nTX = 1
            obj.codebook{1} = {1};

            %% nTX = 2
            p1 = zeros(2,1,4);
            p1(:,:,1) = [1; 1] / sqrt(2);
            p1(:,:,2) = [1;-1] / sqrt(2);
            p1(:,:,3) = [1; j] / sqrt(2);
            p1(:,:,4) = [1;-j] / sqrt(2);
            p2 = zeros(2,2,3);
            p2(:,:,1) = [1 0; 0  1] / sqrt(2);
            p2(:,:,2) = [1 1; 1 -1] / 2;
            p2(:,:,3) = [1 1; j -j] / 2;
            obj.codebook{2} = {p1, p2};

            %% nTX = 4
            pp = (1+j) / sqrt(2);
            pm = (1-j) / sqrt(2);
            mp = (-1+j) / sqrt(2);
            mm = (-1-j) / sqrt(2);
            U = [ 1 -1 -1 -1
                1 -j  1  j
                1  1 -1  1
                1  j  1 -j
                1 mm -j pm
                1 pm  j mm
                1 pp -j mp
                1 mp  j pp
                1 -1  1  1
                1 -j -1 -j
                1  1  1 -1
                1  j -1  j
                1 -1 -1  1
                1 -1  1 -1
                1  1 -1 -1
                1  1  1  1].';
            s1 = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
            s2 = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                4 2 2 2 4 4 3 3 2 4 3 3 2 3 3 2];
            s3 = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                2 2 2 2 2 2 3 3 2 3 2 3 2 2 2 2
                4 3 3 3 4 4 4 4 4 4 3 4 3 3 3 3];
            s4 = [1 1 3 3 1 1 1 1 1 1 1 1 1 1 3 1
                2 2 2 2 2 2 3 3 2 2 3 3 2 3 2 2
                3 3 1 1 3 3 2 2 3 3 2 2 3 2 1 3
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4];
            p1 = zeros(4, 1, 16);
            p2 = zeros(4, 2, 16);
            p3 = zeros(4, 3, 16);
            p4 = zeros(4, 4, 16);
            for i = 1:16
                u = U(:, i);
                W = eye(4) - 2 * (u*u') / (u'*u);
                p1(:,:,i) = W(:,s1(:,i));
                p2(:,:,i) = W(:,s2(:,i)) / sqrt(2);
                p3(:,:,i) = W(:,s3(:,i)) / sqrt(3);
                p4(:,:,i) = W(:,s4(:,i)) / 2;
            end
            obj.codebook{4} = {p1, p2, p3, p4};
        end

        function codebook = getCodebook(obj, antenna)
            % Obtain the codebook for an antenna
            % input:
            %   antenna:     [nDesAntenna x 1]networkElements.bs.Antenna
            % ouput:
            %   codebook: [nTX x nLayer x nCodebooks]complex
            codebook = obj.codebook{sum([antenna.nTX])};
        end
    end

    methods (Access = protected)
        function precoder = calculatePrecoder(obj, assignedRBs, nLayer, antennas, feedback,  iAntenna)
            % returns a precoding matrix for all assigned RBs
            % The precoding matrix is normalized such that the power of the
            % output signal is equal to the power of the input signal.
            %
            % input:
            %   assignedRBs: [Nx1]integer specifies the index of RBs that are scheduled for the currently considered user
            %   nLayer:      [Nx1]integer specifies the number of layers in the assigned RBs
            %   antennas:    [Nx1]handleObject networkElements.bs.Antennas
            %   feedback:    [1x1]feedback.FeedbackSuperclass feedback from currently considered user
            %   iAntenna:    [1x1]integer index of the antenna in the feedback
            %
            % output:
            %   precoder:    [Nx1]struct containing the precoders for all the scheduled RBs
            %       -W: [nTX x nLayer]complex baseband precoder for this RB
            %
            % with N the number of assigned resource blocks for this user
            % and antenna

            switch feedback.txModeIndex
                case 1 % SISO
                    precoder(1:length(assignedRBs),1) = struct('W',1);

                case 4 % MIMO
                    % preallocate precoder struct
                    precoder(1:length(assignedRBs),1) = struct('W',[]);

                    % set precoder for each assigned resource block
                    for iRB = 1:length(assignedRBs)
                        PMI = feedback.PMI(assignedRBs(iRB));
                        bsPrecoder = obj.codebook{sum([antennas.nTX],2)}{nLayer(iRB)}(:,:,PMI+1);
                        %get desired antenna precoder
                        precoder(iRB).W = obj.getDASAntennaPrecoder(antennas,iAntenna,bsPrecoder);
                    end % for all assigned resource blocks

                otherwise
                    error('PRECODERS:wrongTxMode','This txMode not yet implemented.');
            end
        end
    end

    methods (Static)
        function [isValid] = checkConfig(transmissionParameters, baseStations)
            % checks if parameter config for precoder and transmit mode are compatible
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % see also: precoders.Precoder.checkConfigStatic

            % initialize output
            isValid = false;

            if transmissionParameters.feedbackType == parameters.setting.FeedbackType.minimum
                warning("Minimum feedback is not compatible with the 5G or LTE precoders, currently it works with random precoder.");
                isValid = false;
                return;
            end

            antennaList = [baseStations.antennaList];

            % extract uniqe nTX
            nTX = unique([antennaList.nTX]);

            switch transmissionParameters.txModeIndex
                case 1 % SISO
                    % check if nTX is compatible with SISO transmission
                    if all(nTX == 1)
                        isValid = true;
                    end

                case 4 % MIMO
                    % check if nTX is compatible with MIMO transmission
                    if all(nTX == 1 | nTX == 2 | nTX == 4)
                        isValid = true;
                    end

                otherwise
                    isValid = false;
            end % switch between transmit modes
        end
    end
end

