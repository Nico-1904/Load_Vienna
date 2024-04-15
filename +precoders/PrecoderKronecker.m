classdef PrecoderKronecker < precoders.Precoder
    % Implementation of kronecker procduct based precoders.
    %
    % Based on the paper:
    % Y. Xie, S. Jin, J. Wang, Y. Zhu, X. Gao and Y. Huang,
    % "A limited feedback scheme for 3D multiuser MIMO based on Kronecker product codebook,"
    % 2013 IEEE 24th Annual International Symposium on Personal, Indoor, and Mobile Radio Communications (PIMRC),
    % London, 2013, pp. 1130-1135, doi: 10.1109/PIMRC.2013.6666308.
    %
    % Compatible with antenna:  networkElements.bs.AntennaArray
    % Compatible with feedback: LTEDLFeedback
    % Features: Number of layers and precoders can be configured via the
    %           precoder parameters.
    %
    % initial author: Alexander Bokor
    %
    % See also: parameters.precoders.Kronecker, precoders.Precoder,
    % feedback.LTEDLFeedback, parameters.transmissionParameters.PrecoderParameters

    properties(Access = private)
        % 2D cell array with codebooks for {N1, N2} configurations with
        % [1 x nLayers]cell array with
        % [nTX x nLayers x nPrecoders]complex codebook
        % where nTX = N1 * N2.
        % stores all codebooks
        % usage: codebooks{N1,N2}{nLayer}(:, :, iPMI)
        codebooks

        % [1x1]integer number of layers to generate (e.g. 8)
        maxLayer

        % [1x1]integer oversampling proportion (e.g. 4)
        beta

        % [1x1]integer number of horizontal codewords (e.g. 16)
        horizontalOversampling

        % [1x1]integer number of vertical codewords (e.g. 16)
        verticalOversampling
    end

    methods
        function obj = PrecoderKronecker(beta, maxLayer, horizontalOversampling, verticalOversampling, baseStations)
            % Determines needed codebooks from the antenna list and pre
            % calculates the codebooks.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   antennaList: [1xnAnt]handleObject networkElements.antennas.AntennaArray antennas used in simulation

            % load settings from the precoder parameters
            obj.maxLayer = maxLayer;
            obj.beta = beta;
            obj.horizontalOversampling = horizontalOversampling;
            obj.verticalOversampling = verticalOversampling;

            % list of all antennas in the simulation
            antennaList = [baseStations.antennaList];

            % create an array of unique (N1, N2) pairs
            if(isa(antennaList, "networkElements.bs.antennas.AntennaArray"))
                % calculate number of rows in the codebook
                nBaseStations = size(baseStations, 2);
                maxNTXperBS = zeros(1,nBaseStations);
                for i = 1:nBaseStations
                    maxNTXperBS(i) = sum([baseStations(i).antennaList.nTX],2);
                end
                cbSizeRows = max(maxNTXperBS);

                % get all N1 / N2 configuartions
                A = unique([[antennaList.N1]; [antennaList.N2]]', "rows")';
                N1 = A(1, :);
                N2 = A(2, :);

                % initialize codebook
                obj.codebooks = cell(cbSizeRows, max(N2));

                % normal mode create Precoder based on antennageometry
                for i = 1:size(N1)
                    obj.codebooks{N1(i), N2(i)} = obj.calcCodebook(N1(i), N2(i));
                end

                %DAS mode codebooks only consider the nTX Parameter for the
                %codebooks
                for iTx = 1:cbSizeRows
                    obj.codebooks{iTx, 1} = obj.calcCodebook(iTx, 1);
                end
            end
        end

        function codebook = getCodebook(obj, antennas)
            % get a codebook for a specific antenna
            %
            % input:
            %   antennas: [nAnt x1]handleObject networkElements.bs.antenna
            % output:
            %   codebook: [1 x maxLayer]cell array with
            % [nTX x nLayers x nPrecoders]complex codebook
            if size(antennas,2) == 1
                %normal mode get codebook based on n1 and n2
                if antennas.nTX == 1
                    codebook = {1};
                else
                    codebook = obj.codebooks{antennas.N1, antennas.N2};
                end
            else
                %DAS MODE get codebook based on nTX
                codebook = obj.codebooks{sum([antennas.nTX],2), 1};
            end
        end
    end

    methods(Access = private)
        function codebook = calcCodebook(obj, N1, N2)
            % calculate a kronecker based codebook
            %
            % input:
            %   N1: [1x1]integer number of horizontal rf chains
            %   N2: [1x1]integer number of vertical rf chains
            % ouput:
            %   codebook: [1 x maxLayer]cell array with
            %             [nTX x nLayers x nPrecoders]complex codebooks

            nHorizontalWords = obj.horizontalOversampling * N1;
            nVerticalWords = obj.verticalOversampling * N2;

            words = obj.generateCodewords(N1, N2, nHorizontalWords, ...
                nVerticalWords, obj.beta);
            codebook = cell(1, obj.maxLayer);
            for nLayers = 1:obj.maxLayer
                codebook{nLayers} = obj.generateCodebook(words, nLayers, N1, N2, ...
                    obj.horizontalOversampling, obj.verticalOversampling);
            end
        end

        function  c = generateCodewords(~, N1, N2, nHwords, nVwords, beta)
            % generate an array of kronecker based codewords
            %
            % input:
            %   N1: [1x1]integer number of horizontal antennas
            %   N2: [1x1]integer number of vertical antennas
            %   nHwords: [1x1]integer number of horizontal codewords
            %   nVwords: [1x1]integer number of vertical codewords
            %   beta: [1x1]integer oversampling proportion
            %
            % ouput:
            %   [N1*N2, Nh*Nv]complex array with codewords
            cv = @(m)  1/sqrt(N2) * exp(2j * pi * m .* (0:N2 - 1) / (beta * nVwords))';
            ch = @(n)  1/sqrt(N1) * exp(2j * pi * n .* (0:N1 - 1) / (nHwords))';


            c = zeros(N2 * N1, nHwords * nVwords);
            for m = 0:nVwords - 1
                for n = 0:nHwords - 1
                    c(:,nHwords * m + n + 1) = kron(cv(m), ch(n));
                end
            end
        end

        function codebook = generateCodebook(obj, codewords, nLayers, N1, N2, O1, O2)
            % Takes an array of codewords and the amount of layers and
            % stacks them in precoder matrices.
            %
            % input:
            %   codewords: [nCodewords x lenthCodeword]complex array of codewords
            %   nLayers: [1x1]integer number of layers
            %   N1: [1x1]integer horizontal RF chains
            %   N2: [1x1]integer vertical RF chains
            %   O1: [1x1]integer horizontal oversampling
            %   O2: [1x1]integer vertical oversampling
            %
            % ouput:
            %   codebook: [nTX x nLayers x nPrecoder]complex codebook

            nTX = size(codewords, 1);
            nCodewords = size(codewords, 2);
            nPrecoder = floor(nCodewords / nLayers);
            nHorizontalWords = O1 * N1;
            nVerticalWords = O2 * N2;

            codebook = zeros(nTX, nLayers, nPrecoder);

            % distance between two adjacent codewords
            % we need this distance, otherwise we get precoders without
            % full rank
            distance = min(O1, obj.beta * O2) + 1;

            for i = 1:nPrecoder
                mask = i * ones(1, nLayers);
                mask(2:nLayers) = mask(2:nLayers) +  distance * (1:(nLayers-1));
                mask = mod(mask - 1, nHorizontalWords * nVerticalWords) + 1;

                % save in codebooks and normalize
                codebook(:, :, i) = codewords(:, mask) ./ sqrt(nLayers);
            end
        end
    end

    methods(Access = protected)
        function precoder = calculatePrecoder(obj, assignedRBs, nLayer, antennas, feedback, iAntenna)
            % Returns a precoding matrix for all assigned RBs
            % The precoding matrix is normalized such that the power of the
            % output signal is equal to the power of the input signal.
            %
            % input:
            %   assignedRBs: [Nx1]integer specifies the index of RBs that are scheduled for the currently considered user
            %   nLayer:      [Nx1]integer specifies the number of layers in the assigned RBs
            %   antenna:     [Nx1]handleObject networkElements.bs.Antenna
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
                    precoder(1:length(assignedRBs), 1) = struct('W', 1);

                case 4 % MIMO

                    % preallocate precoder struct
                    precoder(1:length(assignedRBs), 1) = struct('W', []);

                    % set precoder for each assigned resource block
                    for iRB = 1:length(assignedRBs)
                        PMI = feedback.PMI(assignedRBs(iRB));
                        cbook = obj.getCodebook(antennas);
                        bsPrecoder= cbook{nLayer(iRB)}(:, :, PMI + 1);
                        %get desired antenna precoder
                        precoder(iRB).W = obj.getDASAntennaPrecoder(antennas,iAntenna,bsPrecoder);
                    end % for all assigned resource block

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

            if ~isa([antennaList.precoderAnalog],"precoders.analog.NoAnalogPrecoding")
                warning("PRECODERS:analogCompatibility", ...
                    "This digitial precoder is not tested for compatibility with the analog precoder. " + ...
                    "You may want to disable the analog precorder or select a different digital precoder.");
                return;
            end

            switch transmissionParameters.txModeIndex
                case 1 % SISO
                    % check if nTX is compatible with SISO transmission
                    if all(unique([antennaList.nTX]) == 1)
                        isValid = true;
                    end

                case 4 % MIMO
                    if ~isa(antennaList, "networkElements.bs.antennas.AntennaArray")
                        warning("PRECODERS:antennaCompatibility", ...
                            "This precoder is only compatible with antenna arrays.");
                        return;
                    end
                    if ~all([antennaList.nPV] == 1 & [antennaList.nPH] == 1)
                        warning("PRECODERS:multipanelCompatibility", ...
                            "This precoder is only compatible with single panel antenna arrays");
                        return;
                    end

                    isValid = true;
                    return;

                otherwise
                    isValid = false;
            end % switch between transmit modes
        end
    end
end

