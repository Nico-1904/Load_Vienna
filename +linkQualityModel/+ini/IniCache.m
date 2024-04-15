classdef IniCache < tools.HiddenHandle
    %INICACHE Calculates and stores inter-numerology inteference factors.
    % The INI is precalculated at the beginning of the simulation and
    % passed to the LinkQualityModel.
    % see also: linkQualityModel.IniCalculator,
    % linkQualityModel.LinkQualityModel
    %
    % initial author: Alexander Bokor

    properties
        % [nNum x nNum]cell array with INI factor matrix
        % Index starts at one. to access the factor matrix for INI from
        % numerology i to j use: obj.cache{i+1, j+1}
        %
        % nNum: number of numerologies
        cache
    end

    methods
        function obj = IniCache(resourceGrid, numerologies, oversampling)
            %INICACHE Constructor
            %
            % resourceGrid: [1x1]parameters.resourceGrid.ResourceGrid
            %                        resource grid
            % numerologies: [1 x nNum]double list of all numerologies in the
            %                        simulation
            % oversampling: [1x1]double FFT oversampling factor

            nRBFreq = resourceGrid.nRBFreq;
            cp = resourceGrid.cpRatio;

            % order and sort numerologies
            numerologies = sort(unique(numerologies));

            % if only on numerology exist we don't have anything to do
            if length(numerologies) == 1
                return;
            end

            % get all possible numerology pairs
            pairs = nchoosek(numerologies, 2);
            nNum = length(numerologies);
            nPairs = size(pairs, 1);

            % init cache
            obj.cache = cell(nNum);

            % print out a status message
            fprintf("Calculating INI factors for %d numerology pair(s).\n", nPairs);

            % calculate the INI factors for each numerology pair
            for iPair = 1:nPairs
                num1 = pairs(iPair, 1);
                num2 = pairs(iPair, 2);
                scs1 = resourceGrid.subcarrierSpacingHz(num1);
                scs2 = resourceGrid.subcarrierSpacingHz(num2);
                nCarriersPerRB1 = resourceGrid.nSubcarrierRb(num1);
                nCarriersPerRB2 = resourceGrid.nSubcarrierRb(num2);

                % init the INI calculator and obtain INI factor matrices
                iniCalculator = linkQualityModel.ini.IniCalculator(nRBFreq, scs1, nCarriersPerRB1, scs2, nCarriersPerRB2, cp, oversampling);
                [WSN_TO_NSN, NSN_TO_WSN] = iniCalculator.getFactorMatrix();

                obj.cache{num1+1, num2+1} = NSN_TO_WSN;
                obj.cache{num2+1, num1+1} = WSN_TO_NSN;
            end
        end

        function A = getFactors(obj, fromNum, toNum)
            % convenience function that accesses the cache with zero based
            % index
            %
            % input
            %   fromNum: [1x1]integer interfering numerology
            %   toNum:   [1x1]integer numerology of interest
            %
            % output:
            %   A: [nRBFreq x nRBFreq]double INI factor matrix value

            A = obj.cache{fromNum + 1, toNum + 1};
        end
    end
end

