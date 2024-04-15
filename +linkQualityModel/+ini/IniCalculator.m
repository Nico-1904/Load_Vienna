classdef IniCalculator < tools.HiddenHandle
    %INICALCULATOR Calculates the inter-numerology interference between to
    % numerologies in a ressource grid. It is assumed that both
    % numerologies have the same amount of resource blocks in frequency.
    %
    % the calculation is based on the paper:
    % A. B. Kihero, M. S. J. Solaija, A. Yazar and H. Arslan,
    % "Inter-Numerology Interference Analysis for 5G and Beyond,"
    % 2018 IEEE Globecom Workshops (GC Wkshps),
    % 2018, pp. 1-6, doi: 10.1109/GLOCOMW.2018.8644394.
    %
    % NSN: narrow subcarrier numerology
    % WSN: wide subcarrier numerology
    %
    % initial author: Alexander Bokor

    properties (Access=private)
        % number of resource blocks in the frequency axis
        % [1x1]integer
        nRBFreq

        % subcarrier spacing of numerology 1
        % [1x1]double
        scs1

        % number of subcarriers per RB from numerology 1
        % [1x1]integer
        nCarriersPerRB1

        % subcarrier spacing of numerology 2
        % [1x1]double
        scs2

        % number of subcarriers per RB from numerology 1
        % [1x1]integer
        nCarriersPerRB2

        % cyclic prefix ratio
        % [1x1]double
        cp

        % FFT oversampling factor
        oversampling
    end

    methods
        function obj = IniCalculator(nRBFreq, scs1, nCarriersPerRB1, scs2, nCarriersPerRB2, cp, oversampling)
            %INICALCULATOR
            %
            % input:
            %   nRBFreq:         [1x1]double  number of resource blocks in frequency
            %   scs1:            [1x1]double  subcarrier spacing of numerology 1
            %   nCarriersPerRB1: [1x1]integer number of subcarriers per RB from numerology 1
            %   scs2:            [1x1]double  subcarrier spacing of numerology 2
            %   nCarriersPerRB2: [1x1]integer number of subcarriers per RB from numerology 1
            %   cp:              [1x1]double  cyclic prefix ratio
            %   oversampling:    [1x1]double FFT oversampling factor

            obj.nRBFreq = nRBFreq;
            obj.scs1 = scs1;
            obj.nCarriersPerRB1 = nCarriersPerRB1;
            obj.scs2 = scs2;
            obj.nCarriersPerRB2 = nCarriersPerRB2;
            obj.cp = cp;
            obj.oversampling = oversampling;

            % the numerology 1 must always be smaller than numerolgoy 2
            if scs1 > scs2
                error('ini:invalidParameters', 'subcarrierspacing 1 must be smaller than subcarrierspacing 2');
            end

            % same scs is not possible
            if scs1 == scs2
                error('ini:invalidParameters', 'INI can not be calculated for equal subcarrierspacings');
            end
        end

        function [A_WSN_TO_NSN, A_NSN_TO_WSN] = getFactorMatrix(obj)
            % obtain the INI factor matrices
            %
            % output:
            %   A_WSN_TO_NSN: [nRBFreq x nRBFreq]double
            %   A_NSN_TO_WSN: [nRBFreq x nRBFreq]double

            % get factors
            A_WSN_TO_NSN = obj.calculate_WSN_TO_NSN();
            A_NSN_TO_WSN = obj.calculate_NSN_TO_WSN();

            % due to the symmetry a toeplitz matrix is used to obtain all other factors
            A_WSN_TO_NSN = toeplitz([0, A_WSN_TO_NSN]);
            A_NSN_TO_WSN = toeplitz([0, A_NSN_TO_WSN]);
        end

        function A_WSN_TO_NSN = calculate_WSN_TO_NSN(obj)
            % calculates INI factors from wide subcarrier spacing to narrow
            % subcarrierspacing
            % The narrow subcarrierspacing is the FIRST RB and all others RBs
            % are interferers
            %
            % output
            %   A_WSN_TO_NSN: [1x nRBFreq - 1]double INI factors from the
            %                 nRBFreq - 1 interfering RBs to the first RB.

            nCarrier1 = obj.nRBFreq * obj.nCarriersPerRB1;
            nCarrier2 = obj.nRBFreq * obj.nCarriersPerRB2;
            os = obj.oversampling;

            n1 = 1 / obj.nRBFreq;
            n2 = 1 - n1;
            Q = obj.scs2 / obj.scs1;

            % Interference factors for carrier to carrier interference
            % [active carriers numerology 1 x active carriers numerology 2]double
            PSI_WSN_TO_NSN = zeros(nCarrier1 * n1, nCarrier2 * n2);

            % INI from WSN to NSN
            k = 0:Q:(n2 * nCarrier1 - 1); % only multiples of Q
            for v = 0:(n1 * nCarrier1 - 1)
                psi = sin(pi / Q * (1 + (1 - Q) * obj.cp) * (k - v)).^2 ./ ...
                    sin(pi / os / nCarrier1 * (k - v + n1 * nCarrier1) ).^2 + ...
                    (Q - 1) * sin(pi / Q * (1 + obj.cp) * (k - v)).^2 ./ ...
                    sin(pi / os / nCarrier1 * (k - v + n1 * nCarrier1)).^2;

                PSI_WSN_TO_NSN(v+1, :) = psi;
            end

            % interference factor for block to carrier interference
            % [active carriers numerology 1 x active rb numerology 2]
            PSI_WSN_TO_NSN_BLOCK = reshape(PSI_WSN_TO_NSN, nCarrier1*n1, obj.nCarriersPerRB2, []);

            % sum over the carriers in the interfering RBs and RBs of interest
            PSI_WSN_TO_NSN_BLOCK = sum(PSI_WSN_TO_NSN_BLOCK, [1, 2]);

            % squeeze out the summed dimensions
            A_WSN_TO_NSN = squeeze(PSI_WSN_TO_NSN_BLOCK) / nCarrier1 / nCarrier2 / os^2;
            A_WSN_TO_NSN = A_WSN_TO_NSN';
        end

        function A_NSN_TO_WSN = calculate_NSN_TO_WSN(obj)
            % calculates INI factors from narrow subcarrier spacing to wide
            % subcarrierspacing
            % The wide subcarrierspacing is the LAST RB and all others RBs
            % are interferers
            %
            % output
            %   A_NSN_TO_WSN: [1x nRBFreq - 1]double INI factors from the
            %                 nRBFreq - 1 interfering RBs to the last RB.

            nCarrier1 = obj.nRBFreq * obj.nCarriersPerRB1;
            nCarrier2 = obj.nRBFreq * obj.nCarriersPerRB2;
            os = obj.oversampling;

            n2 = 1 / obj.nRBFreq;
            n1 = 1 - n2;
            Q = obj.scs2 / obj.scs1;

            % [active carriers numerology 2 x active carriers numerology 1]double
            PSI_NSN_TO_WSN = zeros(nCarrier2 * n2, nCarrier1 * n1);

            % INI from NSN to WSN
            k = 0:(n1 * nCarrier1 - 1);
            for p = 0:Q:(n2 * nCarrier1 - 1)  % only multiples of Q
                xi = sin(pi / Q * (k - p)) ./ ...
                    sin(pi / os / nCarrier1 * (k - p - n1 * nCarrier1));

                PSI_NSN_TO_WSN(p/Q+1,:) = abs(xi).^2;
            end

            % [active carriers numerology 2 x active rb numerology 1]
            PSI_NSN_TO_WSN_BLOCK = reshape(PSI_NSN_TO_WSN, nCarrier2*n2, obj.nCarriersPerRB1, []);

            % sum over the carriers in the interfering RBs and RBs of interest
            PSI_NSN_TO_WSN_BLOCK = sum(PSI_NSN_TO_WSN_BLOCK, [1,2]);

            % squeeze out the summed dimensions
            A_NSN_TO_WSN = squeeze(PSI_NSN_TO_WSN_BLOCK) / nCarrier1 / nCarrier2 / os^2;


            % since we assumed that the last RB is of interest, we now assume
            % symmetry and flip the vector
            A_NSN_TO_WSN = flip(A_NSN_TO_WSN');
        end
    end
end

