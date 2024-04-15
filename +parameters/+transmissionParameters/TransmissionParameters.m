classdef TransmissionParameters < tools.HiddenHandle
    %TRANSMISSIONPARAMETERS contains all transmission parameters
    % This class contains all transmission parameters and offers a function
    % to generate downlink transmission parameters and a function to
    % generate uplink transmission parameters and a setDependentParameters
    % function, that needs to be called after all parameters, that have
    % SetAccess public, have been set.
    %
    %NOTE: the default values are set in the property definitions and in
    %the getDownlinkTransmissionParameters and
    %getUplinkTransmissionParameters functions.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.transmissionParameters.CqiParameters,
    % parameters.transmissionParameters.LayerMapping,
    % parameters.resourceGrid.ResourceGrid
    % linkPerformanceModel.BlerCurves, feedback.Feedback

    properties
        % transmit mode
        % [1x1]struct transmit mode index
        txModeIndex = 4;

        % transmission bandwidth in Hz
        % [1x1]double bandwidth in Hz
        bandwidthHz = 5e6;

        % CQI parameter type
        % [1x1]enum parameters.setting.CqiParameterType
        cqiParameterType = parameters.setting.CqiParameterType.Cqi64QAM;

        % RedundancyVersion
        % [1xnRedundancyVersions] double redundancy version tells the user
        % about amount of redundancy added into the codeword while turbo encoding.
        % There can be 3 different redundancy versions corresponding
        % to a retransmission. Redundancy version 0 means
        % no retransmission. When a transmission fails, the configured
        % maximum number of retransmissions from a base station to a user
        % is 3.
        % At the moment, there are AWGN BLER curves correspond to
        % different redundancy versions for the first table used for non-BL/CE
        % UEs in TX 36.213 V13.2.0.
        redundancyVersion = [0 1 2 3];

        % type of layer mapping used
        % [1x1]enum parameters.setting.LayerMappingType
        layerMappingType

        % type of resource grid used
        % [1x1]enum parameters.setting.ResourceGrid
        resourceGridType = parameters.setting.ResourceGrid.LTE;

        % type of feedback used
        % [1x1]enum parameters.setting.FeedbackType
        feedbackType

        % number of CRC bits - CQI mapping used
        % [1x1]integer number of bits used for Cyclic Redundancy Check
        nCRCBits = 24;

        % maximum number of codewords
        % [1x1]integer maximum number of codewords
        maxNCodewords = 2;

        % maximum number of layers that can be used in a simulation
        % [1x1]integer maximum number of layers
        maxNLayer = 4;

        % indicator for fast block error rate mapping
        % [1x1]logical indicates if fast BLER mapping is used
        fastBlerMapping = true;

        % CQI BLER threshold
        % [1x1]double threshold for CQI BLER
        mapperBlerThreshold = .1;

        % use synchronization signal
        % [1x1]logical flag for reference signal
        % If this flag is set, then some symbols are used for the
        % transmission of the primary synchronization signal and cannot be
        % used for data transmission. This reduces the user throughput.
        synchronizationSignalLTE = true;

        % use cell specific reference signal
        % [1x1]logical flag for reference signal
        % If this flag is set, then some symbols are used for the
        % transmission of a reference signal and cannot be used for data
        % transmission. This reduces the user throughput.
        referenceSignalLTE = true;
    end

    properties (SetAccess = protected, GetAccess = public)
        % CQI parameters
        % [1x1]handleObject parameters.transmissionParameters.CqiParameters
        cqiParameters

        % BLER curves
        % [1x1]handleObject linkPerformanceModel.BlerCurves
        blerCurves

        % layer mapping
        % [1x1]handleObject parameters.transmissionParameters.LayerMapping
        layerMapping

        % resource grid parameters
        % [1x1]handleObject parameters.resourceGrid.ResourceGrid
        resourceGrid
    end

    methods (Static)
        function transmitParamsDL = getDownlinkTransmissionParameters()
            % creates downlink transmission parameter settings
            %
            % output:
            %   transmitParamsDL:   [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %
            % see also parameters.Parameters.setDefaults

            % create object
            transmitParamsDL = parameters.transmissionParameters.TransmissionParameters;

            % codeword to layer mapping
            transmitParamsDL.layerMappingType	= parameters.setting.LayerMappingType.TS36211;
            % set feedback type
            transmitParamsDL.feedbackType       = parameters.setting.FeedbackType.LTEDL;
        end
    end

    methods
        function obj = TransmissionParameters()
            %TRANSMISSIONPARAMETERS empty class constructor - only sets defaults
        end

        function setDependentParameters(obj, params)
            % set dependent transmission parameters
            % Sets properties according to type chosen, e.g. layerMapping
            % according to layerMappingType. This function should be called
            % after the type properties have been set.
            %
            % input:
            %   params: [1x1]handleObject parameters.Parameters
            %
            % see also parameters.Parameters.setDependentParameters

            % set CQI parameters
            obj.cqiParameters = parameters.transmissionParameters.CqiParameters.generateCqiParameters(obj);
            % initialize bler curves
            obj.blerCurves = linkPerformanceModel.BlerCurves(obj.cqiParameters, obj.fastBlerMapping, obj.redundancyVersion, obj.cqiParameterType);
            % set BLER curves at CQI mapper
            obj.cqiParameters.setCqiMapperParameters(obj.blerCurves);
            % codeword to layer mapping
            obj.layerMapping = parameters.transmissionParameters.LayerMapping.generateLayerMapping(obj.layerMappingType);

            % generate resource grid
            obj.resourceGrid = parameters.resourceGrid.ResourceGrid.generateResourceGrid(obj.resourceGridType, obj.bandwidthHz, params.time.slotDuration);
        end

        function checkParameters(obj)
            % check parameter settings

            % check layer mapping
            if ~isa(obj.layerMapping,'parameters.transmissionParameters.LayerMapping')
                error('layerMapping must be a subclass of parameters.transmissionParameters.LayerMapping');
            end

            % check redundancy versions
            if obj.redundancyVersion(1) ~= 0 || obj.redundancyVersion(2) ~= 1 || obj.redundancyVersion(3) ~= 2 || obj.redundancyVersion(4) ~= 3
                error('redundacy versions of the codewords must have specifc values.');
            end
        end

        %% data symbol calculation
        function nDataSymbols = getNDataSymbols(obj, iSlot, iRBFreq, nTX)
            % get the number of data sysmbols in the given resource blocks
            %
            % input:
            %   iSlot:      [1x1]integer index of current slot
            %   iRBFreq:    [1 x nAssignedRBs]integer index of resource block in frequency
            %   nTX:        [1x1]integer number of transmit antennas
            %
            % output:
            %   nDataSymbols:   [1x1]integer number of data symbols

            % number of assigned resource blocks
            nAssignedRBs = length(iRBFreq);

            % get number of symbols used for signaling
            nReferenceSymbol        = obj.getNumberOfReferenceSymbols(nTX, nAssignedRBs);
            nSynchronizationSymbol	= obj.getNumberOfSynchronizationSymbols(iSlot, iRBFreq);

            % calculate number of symbols used for data transmission
            nDataSymbols = obj.resourceGrid.nSymbolRBTot * nAssignedRBs - nReferenceSymbol - nSynchronizationSymbol;
        end

        function nReferenceSymbol = getNumberOfReferenceSymbols(obj, nTX, nAssignedRBs)
            % calculate the number of symbols used for reference signal
            %
            % input:
            %   nTX:    [1x1]integer number of transmit antennas used
            %
            % output:
            %   nReferenceSymbol:   [1x1]integer number of symbols used for reference signal

            nReferenceSymbol = 0;

            if obj.referenceSignalLTE && nTX <= 8
                % set number of reference symbols
                nReferenceSymbol = obj.resourceGrid.referenceSymbolsPerRB(nTX) * nAssignedRBs;
            end % if reference signal is used and number of symbols is defined
        end

        function nSynchronizationSymbol = getNumberOfSynchronizationSymbols(obj, iSlot, iRBFreq)
            % calculate number of symbols used for synchronization signal
            %
            % input:
            %   iSlot:      [1x1]integer index of current slot
            %   iRBFreq:    [1 x nAssignedRBs] indices of resource blocks in frequency
            %
            % output:
            %   nSynchronizationSymbol: [1x1]integer number of symbols used for synchronization signal

            nSynchronizationSymbol = 0;

            if obj.synchronizationSignalLTE && mod(iSlot-1,5)
                nSynchronizationSymbol = sum(obj.resourceGrid.synchronizationRB(iRBFreq)) * obj.resourceGrid.nSubcarrierRb_base;
            end % if synchronization signal is used and is present in this slot
        end
    end
end

