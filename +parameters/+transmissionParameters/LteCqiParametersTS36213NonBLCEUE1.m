classdef LteCqiParametersTS36213NonBLCEUE1 < parameters.transmissionParameters.CqiParameters
    %LTECQIPARAMETERSTS36213NONBLCEUE1 gives information about the CQI according to TS 36.213
    % It uses the first table for non-BL/CE UEs (Bandwidth-reduced
    % Low-complexity or Coverage Enhanced UE) in TX 36.213 V13.2.0
    % (2016-06) (i.e., Table 7.2.3-1)
    %
    % CQI:  Channel Quality Indicator
    %
    % initial author: Thomas Dittrich
    % extended by: Thomas Lipovec, documentation
    %               Areen Shiyahin, added BLER mappings for different rednudancy versions
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
        function obj = LteCqiParametersTS36213NonBLCEUE1(transmissionParameters)
            % LteCqiParametersTS36213NonBLCEUE1 class constructor
            %   Sets class properties according to the CQI table from
            %   TS 36.213 V13.2.0 (2016-06) (i.e., Table 7.2.3-1) and
            %   specifies the corresponding BLER curves files for each
            %   modulation and coding scheme.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters

            % set CQI table according to standard
            cqi                      = [0      1      2      3      4      5      6      7       8       9       10      11      12      13      14      15];
            obj.modulationType       = [1      2      2      2      2      2      2      3       3       3       4       4       4       4       4       4];
            obj.modulationOrder      = [0      2      2      2      2      2      2      4       4       4       6       6       6       6       6       6];
            obj.modulationName       = {'None' 'QPSK' 'QPSK' 'QPSK' 'QPSK' 'QPSK' 'QPSK' '16QAM' '16QAM' '16QAM' '64QAM' '64QAM' '64QAM' '64QAM' '64QAM' '64QAM'};
            obj.codingRateX1024      = [0      78     120    193    308    449    602    378     490     616     466     567     666     772     873     948];
            obj.efficiency           = [0      0.1523 0.2344 0.3770 0.6016 0.8770 1.1758 1.4766  1.9141  2.4063  2.7305  3.3223  3.9023  4.5234  5.1152  5.5547];
            obj.betaMIESMCalibration = [1      3.07   4.41   0.6    1.16   1.06   1.06   0.87    1.01    1.04    1.03    1.11    1.01    1.07    1       1.05];
            obj.nCqi                 = 16;
            redundancyVersion        = transmissionParameters.redundancyVersion;
            nRedundancyVersoins      = size(redundancyVersion, 2);

            % allocate cells that holds the file locations for each BLER
            % curve for each redundancy version
            obj.blerCurveFiles       = cell(obj.nCqi,1, nRedundancyVersoins);
            [obj.blerCurveFiles{1,:,1}, obj.blerCurveFiles{1,:,2},...
                obj.blerCurveFiles{1,:,3},obj.blerCurveFiles{1,:,4}] = deal('','','',''); % no bler curve for zero CQI

            % set BLER curve files for all redundancy versions
            fileFolder = fullfile('dataFiles', 'AWGN_BLERs', 'TS36213NonBLCEUE1');
            for iRV = 1: nRedundancyVersoins
                for iBlerFile = 2:size(obj.blerCurveFiles,1)
                    obj.blerCurveFiles{iBlerFile,:,iRV} = fullfile(fileFolder ,sprintf('redundancyVersion%i', redundancyVersion(iRV)), sprintf('AWGN_1.4MHz_SISO_cqi%i_rv%i.mat', cqi(iBlerFile), redundancyVersion(iRV)));
                end
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
            %                   [1 x nCqi]integer if cqi=[]

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
            % and redundancy version
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
            %   for the given redundancy version.
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
            %   for the given redundancy version.
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
            %   The thresholds are used in the class methods cqiToSinr and
            %   and sinrToCqi to map from a CQI value to a typical SINR
            %   value and vice versa.
            %
            % input:
            %    blerCurves:    [1x1]handleObject linkPerformanceModel.BlerCurves

            nRedundancyVersoins = size(blerCurves.blerCurves,3);
            for iRV = 1: nRedundancyVersoins
                for iCqi = 1:obj.nCqi
                    % get CQI value
                    cqi = iCqi-1;
                    % set SINR threshold for this CQI and redundancy version
                    obj.mapperSinrThreshold(:,iCqi,iRV) = blerCurves.getSinr(obj.mapperBlerThreshold, cqi,iRV);
                end % for all CQIs
            end

            % introduce another thresholds. This is required because for
            % every cqi we need an interval of possible sinrs for which it
            % would be used
            meanIntervalLength = zeros(1,nRedundancyVersoins);
            meanIntervalLength(:) = mean(diff(obj.mapperSinrThreshold(1,2:obj.nCqi,:)));
            for iRV = 1: nRedundancyVersoins
                obj.mapperSinrThreshold(1,obj.nCqi+1,iRV)=obj.mapperSinrThreshold(1,obj.nCqi,iRV)+meanIntervalLength(iRV);
            end
            obj.isMapperInitialized = true;
        end
    end
end

