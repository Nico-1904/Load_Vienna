classdef CqiParameters < tools.HiddenHandle
    %CQIPARAMETERS superclass for CQI parameters
    %   Superclass for all different types of CQI parameters that give
    %   information about the different modulation and coding schemes
    %   and specify their parameters like coding rate and modulation order.
    %
    % CQI:      Channel Quality Indicator
    % MCS:      Modulation and Coding Scheme
    % MIESM:    Mutual Information Effective SINR mapping
    %
    % initial author: Thomas Dittrich
    %
    % see also parameters.setting.CqiParameterType,
    % parameters.transmissionParameters.TransmissionParameters

    properties (SetAccess = protected, GetAccess = public)
        % modulation type for each CQI
        % [1 x nCqi]integer modulation type for each CQI
        modulationType

        % modulation order for each CQI
        % [1 x nCqi]integer number of bits per symbol
        modulationOrder

        % modulation name for each CQI
        % [1 x nCqi]cell modulation name as string for each CQI
        modulationName

        % coding rate for each CQI
        % [1 x nCqi]integer number of data bits per 1024 transmitted bits
        codingRateX1024

        % efficiency for each CQI
        % [1 x nCqi]double number of data bits transmitted per symbol
        efficiency

        % number of CQIs
        % [1x1]integer number of different CQIs
        nCqi

        % beta calibration for each CQI
        % [1 x nCqi]double beta calibration for each CQI
        % Calibration parameters are used to minimize the MSE of the
        % estimated effective SINR of the MIESM. They are obtained from
        % extensive link level simulations.
        % Empty if CqiParameters with no calibration is chosen.
        betaMIESMCalibration

        % files with BLER curves
        % [nCqi x 1 x nRedundancyVersoins]cell containing BLER curve file locations
        % For each modulation and coding scheme there must be a
        % corresponding AWGN BLER curve which is used for the mapping from
        % the effective SINR to the BLER.
        blerCurveFiles

        % SINR threshold
        % [1 x nCqi+1 x nRedundancyVersoins]double SINR threshold for each CQI
        % SINR values for which the BLER equals the mapperBlerThreshold.
        mapperSinrThreshold

        % CQI BLER threshold
        % [1x1]double threshold for CQI BLER
        mapperBlerThreshold = .1;
    end

    methods (Abstract)
        % the following methods need to be implemented depending on the starting CQI value

        %CQITOSINR maps a set of cqi values to typical sinr values for the given cqi and redundancy version.
        [sinr] = cqiToSinr(obj, cqi,rv);

        %SINRTOCQI maps a set of sinr values to the highest possible CQI
        % for a redundancy version.
        [cqi] = sinrToCqi(obj, sinr,rv);

        %SETCQIMAPPERPARAMETERS initializes the sinr thresholds that can later be used in the CQI mapper
        setCqiMapperParameters(obj, blerCurves);

        % returns the modulation type for the given CQI
        [modulationType] = getModulationType(obj, cqi)

        % returns the modulation order for the given CQI
        [modulationOrder] = getModulationOrder(obj, cqi)

        % returns the modulation name for the given CQI
        [modulationName] = getModulationName(obj, cqi)

        % returns the coding rate for the given CQI
        [codingRateX1024] = getCodingRateX1024(obj, cqi)

        % returns the efficency rate for the given CQI
        [efficiency] = getEfficiency(obj, cqi)

        % returns the beta MIESM calibration for the given CQI
        [betaMIESMCalibration] = getBetaMIESMCalibration(obj, cqi)

        % returns the location of BLER files for the given CQI and redundancy version
        [blerFiles] = getBlerCurveFiles(obj, cqi, rv)
    end

    methods(Static)
        function CqiParameters = generateCqiParameters(transmissionParameters)
            % CqiParameters creates CqiParameters according to settings
            %   Creates CqiParameters by calling the corresponding
            %   constructor according to the setting choosen by the
            %   simulator user.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %
            % output:
            %   CqiParameters:  [1x1]handleObject parameters.transmissionParameters.CqiParameters

            % create CQI parameters
            switch transmissionParameters.cqiParameterType
                case parameters.setting.CqiParameterType.Cqi64QAM
                    CqiParameters = parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE1(transmissionParameters);
                case parameters.setting.CqiParameterType.Cqi256QAM
                    CqiParameters = parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE2(transmissionParameters);
                case parameters.setting.CqiParameterType.Cqi1024QAM
                    CqiParameters = parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE4(transmissionParameters);
                otherwise
                    error('''%s'' is an unknown type of cqi parameters!', transmissionParameters.cqiParameterType);
            end
        end
    end
end

