classdef LteCqiParametersTS36213NonBLCEUE4 < parameters.transmissionParameters.CqiParameters
    %LTECQIPARAMETERSTS36213NONBLCEUE4 gives information about the CQI according to TS 36.213
    % It uses the fourth table for non-BL/CE UEs (Bandwidth-reduced
    % Low-complexity or Coverage Enhanced UE) in TS 36.213 V15.8.0
    % (2020-02) (i.e., Table 7.2.3-4)
    %
    % CQI:  Channel Quality Indicator
    %
    % initial author: Thomas Dittrich
    % extended by: Thomas Lipovec, adapted for Table 7.2.3-4 in TS 36.213 V15.8.0
    %
    % see also parameters.transmissionParameters.CqiParameters,
    %          linkPerformanceModel.BlerCurves
    %          tools.MiesmAverager

    properties (SetAccess = private)
        % indicates if mapper is initialized
        % [1x1]logical mapper initialization flag
        % Once the mapper is initialized a mapping from CQI to SINR and
        % vice versa can be performed. The initialization is done in the
        % class method setCqiMapperParameters.
        isMapperInitialized
    end

    methods
        function obj = LteCqiParametersTS36213NonBLCEUE4(transmissionParameters)
            % LteCqiParametersTS36213NonBLCEUE4 class constructor
            %   Sets class properties according to the CQI table from
            %   TS 36.213 V15.8.0 (2016-06) (i.e., Table 7.2.3-4) and
            %   specifies the corresponding BLER curves files for each
            %   modulation and coding scheme.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters

            % set CQI table according to standard
            cqi                      = [0       1       2       3       4       5       6       7       8       9       10          11          12          13          14          15       ];
            obj.modulationType       = [1       2       2       2       3       3       4       4       4       4       5           5           5           5           6           6        ];
            obj.modulationOrder      = [0       2       2       2       4       4       6       6       6       6       8           8           8           8           10          10       ];
            obj.modulationName       = {'None'  'QPSK'  'QPSK'  'QPSK'  '16QAM' '16QAM' '64QAM' '64QAM' '64QAM' '64QAM' '256QAM'    '256QAM'    '256QAM'    '256QAM'    '1024QAM'   '1024QAM'};
            obj.codingRateX1024      = [0       78      193     449     378     616     567     666     772     873     711         797         885         948         853         948      ];
            obj.efficiency           = [0       0.1523  0.3770  0.8770  1.4766  2.4036  3.3223  3.9023  4.5234  5.1152  5.5547      6.2266      6.9141      7.4063      8.3321      9.2578   ];
            obj.betaMIESMCalibration = [1       3.07    0.6     1.06    0.87    1.04    1.11    1.01    1.07    1       1.19        0.92        0.97        1.12        1.22        0.937    ];
            obj.nCqi                 = 16;
            redundancyVersion        = transmissionParameters.redundancyVersion;
            nRedundancyVersoins      = size(redundancyVersion, 2);

            % allocate cell that holds the file locations for each BLER
            % curve
            obj.blerCurveFiles       = cell(obj.nCqi,1, nRedundancyVersoins);
            %NOTE: no AWGN BLER curves for redundaucy versions higher than 0,
            % which mean no retranamissions are possible
            obj.blerCurveFiles{1,:,1}	 = ''; % no bler curve for zero CQI

            % set BLER curve files
            fileFolder = fullfile('dataFiles', 'AWGN_BLERs', 'TS36213NonBLCEUE4');
            for iBlerFile = 2:length(obj.blerCurveFiles)
                obj.blerCurveFiles{iBlerFile,:,1} = fullfile(fileFolder, sprintf('AWGN_1.4MHz_SISO_cqi%i.mat', cqi(iBlerFile)));
            end

            % set BLER threshold
            obj.mapperBlerThreshold = transmissionParameters.mapperBlerThreshold;
            % allocate array for SINR thresholds
            % the tresholds are set in setCqiMapperParameters once
            % the BLER curves have been initialized
            obj.mapperSinrThreshold = zeros(1, obj.nCqi+1, nRedundancyVersoins);
            % set mapper initialization flag
            obj.isMapperInitialized = false;
        end

        function [modulationType] = getModulationType(obj, cqi)
            % getModulationType gets the modulation type for given CQI or all modulation types
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   modulationType: [size(cqi)]integer
            %                   [1 x nCqi]integer if cqi=[

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                modulationType = obj.modulationType(cqi+1);
            else
                modulationType = obj.modulationType;
            end
        end

        function [modulationOrder] = getModulationOrder(obj, cqi)
            % getModulationOrder returns the modulation order for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   modulationOrder: [size(cqi)]integer
            %                    [1 x nCqi]integer if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                modulationOrder = obj.modulationOrder(cqi+1);
            else
                modulationOrder = obj.modulationOrder;
            end
        end

        function [modulationName] = getModulationName(obj, cqi)
            % getModulationName returns the modulation name for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   modulationName: [size(cqi)]cell containing modulation names
            %                   [1 x nCqi]cell if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                modulationName = obj.modulationName{cqi+1};
            else
                modulationName = obj.modulationName;
            end
        end

        function [codingRateX1024] = getCodingRateX1024(obj, cqi)
            % getCodingRateX1024 returns the coding rate for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   codingRateX1024: [size(cqi)]double
            %                    [1 x nCqi]double if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                codingRateX1024 = obj.codingRateX1024(cqi+1);
            else
                codingRateX1024 = obj.codingRateX1024;
            end
        end

        function [efficiency] = getEfficiency(obj, cqi)
            % getEfficiency returns the efficency rate for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   efficiency: [size(cqi)]double
            %               [1 x nCqi]double if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                efficiency = obj.efficiency(cqi+1);
            else
                efficiency = obj.efficiency;
            end
        end

        function [betaMIESMCalibration] = getBetaMIESMCalibration(obj, cqi)
            % getBetaMIESMCalibration returns the beta MIESM calibration for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %
            % output:
            %   betaMIESMCalibration:   [size(cqi)]double
            %                           [1 x nCqi]double if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                betaMIESMCalibration = obj.betaMIESMCalibration(cqi+1);
            else
                betaMIESMCalibration = obj.betaMIESMCalibration;
            end
        end

        function [blerFiles] = getBlerCurveFiles(obj, cqi, rv)
            % getBlerCurveFiles returns the location of BLER files for the given CQI
            %
            % input:
            %   cqi:    [1x1]integer CQI value 0...15
            %           [1 x n]integer array of CQIs
            %   rv:     [1x1] double index of the redundancy version
            %
            % output:
            %   modulationName: [size(cqi)]cell containing bler curve file locations
            %                   [1 x nCqi]cell if cqi=[]

            if exist('cqi','var')
                % check if input cqi values are in valid range
                if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                    error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
                end
                blerFiles = obj.blerCurveFiles{cqi+1,:,rv};
            else
                blerFiles = obj.blerCurveFiles;
            end
        end

        function [sinr] = cqiToSinr(obj, cqi, rv)
            % CQITOSINR maps a set of cqi values to typical sinr values
            %   The resulting SINR value for each given CQI will be in the
            %   middle of the interval of SINR values where this CQI would
            %   be used.
            %
            % input:
            %   cqi:    [1 x n]integer array of CQIs
            %   rv:     [1 x 1]double redundancy version of a codeword
            %
            % output:
            %   sinr:   [size(cqi)]double SINR value corresponding to CQI

            % abort if mapper is not initialized
            if ~obj.isMapperInitialized
                error('CQI mapper is not initialized! This can be done right after the initialization of the bler curves using the function setCqiMapperParameters.');
            end

            % check if input cqi values are in valid range
            if ~(all(cqi>=0) && all(cqi <=(obj.nCqi-1)))
                error('LteCqiParametersTS36213NonBLCEUE1:invalidCQIvalues', 'Input CQI values must be in the range from 0 to %d.', (obj.nCqi-1));
            end

            cqi_ = reshape(cqi,[],1);
            % take the sinr from the middle of every interval
            alpha = .5;
            sinr_ = (1-alpha) * obj.mapperSinrThreshold(1,cqi_+1,rv+1) + alpha * obj.mapperSinrThreshold(1,cqi_+2,rv+1);
            sinr  = reshape(sinr_, size(cqi));
        end

        function [cqi] = sinrToCqi(obj, sinr, rv)
            % SINRTOCQI maps a set of sinr values to the highest possible CQI
            %   The highest possible CQI is the CQI that still supports this
            %   sinr with a BLER that is lower than obj.mapperBlerThreshold.
            %   In case that no CQI supports this sinr zero is returned in
            %   the respective element of the return value.
            %
            % input:
            %   sinr:	[1 x n]double array of SINR values
            %   rv:     [1 x 1]double redundancy version of a codeword
            %
            % output:
            %   cqi:	[size(sinr)]integer CQI value corresponding to SINR

            % abort if mapper is not initialized
            if ~obj.isMapperInitialized
                error('Cqi mapper is not initialized! This can be done right after the initialization of the bler curves using the function setCqiMapperParameters');
            end

            sinr_ = reshape(sinr,[],1);
            % find the highest CQI whose threshold is below the sinr. find(...,'last') won't work here because it cannot be applied to each row seperately
            cqi_ = sum(repmat(sinr_, 1, obj.nCqi) >= repmat(obj.mapperSinrThreshold(1,1:obj.nCqi,rv+1), size(sinr_,1), 1),2)-1;
            cqi = reshape(cqi_,size(sinr));
        end

        function setCqiMapperParameters(obj, blerCurves)
            % SETCQIMAPPERPARAMETERS initializes the sinr thresholds
            %   The tresholds are used in the class methods cqiToSinr and
            %   and sinrToCqi to map from a CQI value to a typical SINR
            %   value and vice versa.
            %
            % input:
            %    blerCurves:    [1x1]handleObject linkPerformanceModel.BlerCurves

            for iCqi = 1:obj.nCqi
                % get CQI value
                cqi = iCqi-1;
                % set SINR threshold for this CQI value considering
                % redundancy version 0
                obj.mapperSinrThreshold(:, iCqi, 1) = blerCurves.getSinr(obj.mapperBlerThreshold, cqi, 1);
            end % for all CQIs

            % introduce another threshold. This is required because for
            % every cqi we need an interval of possible sinrs for which it
            % would be used
            meanIntervalLength = mean(diff(obj.mapperSinrThreshold(1, 2:obj.nCqi, 1)));
            obj.mapperSinrThreshold(1, obj.nCqi+1, 1)=obj.mapperSinrThreshold(1, obj.nCqi, 1) + meanIntervalLength;
            obj.isMapperInitialized = true;
        end
    end
end

