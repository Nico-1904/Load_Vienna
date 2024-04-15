classdef (Abstract) ResourceGrid < tools.HiddenHandle
    % defines resource grid parameters for the smallest numerology
    % All higher numerologies are derived from this base grid.
    %
    % initial author: Agnes Fastenbauer (originally from ResourceGrid.m)
    % extended by: Alexander Bokor
    %
    % see also parameters.resourceGrid.LTE
    %
    %NOTE: a basic LTE scenario has been chosen as default values. This is
    %to make it possible to have a simple class constructor, that can be
    %called easily, the default values should eventually be changed to 5G
    %values and the LTE scenario be implemented in the LTE class

    properties
        %% properties that define the resource grid

        % subcarrier spacing of the base grid in Hz
        % [1x1]double subcarrier spacing in Hz
        %NOTE: possible carrier frequencies above 6 GHz for 5G are {15kHz,
        %30 kHz, 60 kHz}
        subcarrierSpacingHz_base = 15e3;

        % number of subcarriers in a resource block for the base numerology
        % [1x1]integer number of subcarriers in a resource blocks
        nSubcarrierRb_base = 12;

        % duration of a symbol in the base numerology in seconds
        % [1x1]double symbol duration in seconds
        % The setter function assumes a constant resource block size and
        % adapts nSymbolRb and nSymbolSlot to the new subcarrier
        % spacing.
        symbolDurationS_base = 0.5e-3/7;

        % size of a resource block in time in seconds
        % [1x1]double size of a resource block in seconds
        % The setter function assumes that the symbol duration stays the
        % same, as well as the number of symbols per slot. The number of
        % resource blocks is adapted.
        sizeRbTimeS = 0.5e-3;

        % number of resource blocks in time in a slot
        % [1x1]integer number of resource blocks in a slot in time
        % This is assumed to be a dependent parameter, it cannot be set
        % from outside of this class. It is set through sizeRbTimeS and the
        % slotDuration.
        nRBTime

        % number of resource blocks in frequency in a slot
        % [1x1]integer number of resource blocks in a slot in frequency
        % This is assumed to be a dependent parameter, it cannot be set
        % from outside of this class. It is set through sizeRbFreqHz,
        % symbolDurationS and also depends on the bandwidth.
        nRBFreq

        % cyclic prefix ratio
        % ratio of cp length to total symbol duration
        cpRatio;

        % percentage of bandwidth used for transmission
        % [1x1]double percentage of usable bandwidth
        % This is 0.9 for LTE and up to 0.98 for 5G.
        % The non-usable bandwidth is used as guard band to avoid Inter
        % Symbol Interferernce (ISI).
        usableBandwidth = 0.9;
    end

    properties (Dependent)
        %% dependent properties

        % total number of resource blocks in a slot
        % [1x1]integer number of resource blocks in a slot
        % This is assumed to be a dependent parameter, it cannot be set
        % from outside of this class. It is set through sizeRbTimeS,
        % subcarrierSpacingHz and also depends on the slotDuration.
        nRBTot

        % total number of symbols in a resource block in time and frequency
        % [1x1]integer number of symbols in a resource block
        nSymbolRBTot

        % bandwidth of a resource block in Hz
        % [1x1]double bandwidth of a resource block in Hz
        % This is the subcarrier spacing times the number of subcarriers of
        % the base grid.
        sizeRbFreqHz %= 180e3;

        % number of symbols in time in a resource block
        % [1x1]integer number of symbols in time in a resource blocks
        % This is assumed to be a dependent parameter, it is set through
        % the symbolDurationS and sizeRbTimeS.
        nSymbolRb_base %= 7;

        % total number of subcarriers in a slot
        % [1x1]integer number of subcarriers in a slot
        % This is assumed to be a dependent parameter, it is set through
        % the nRBFreq and nSubcarrierRb.
        nSubcarrierSlot_base

        % total number of symbols in time in a slot
        % [1x1]integer number of symbols in time in a slot
        % This is assumed to be a dependent parameter, it is set through
        % the nRBTime and nSymbolRb.
        nSymbolSlot_base %= 14;
    end

    %% initialization
    methods (Static)
        function ResourceGrid = generateResourceGrid(type, bandwidthHz, slotDuration)
            % creates a resource grid according to the given parameters
            %
            % input:
            %	type:           [1x1]enum parameters.setting.ResourceGrid
            %	bandwidthHz:	[1x1]double used simulation bandwidth in Hertz
            %   slotDuration:   [1x1]double duration of a slot in seconds
            %
            % output:
            %   ResourceGrid:	[1x1]handleObject parameters.resourceGrid.ResourceGrid

            % call class contructor for resource grid type set in params
            switch type
                case parameters.setting.ResourceGrid.LTE
                    ResourceGrid = parameters.resourceGrid.LTE(bandwidthHz, slotDuration);
                case parameters.setting.ResourceGrid.NR5G
                    error("5G resource grid not implemented");
                otherwise
                    error('This is not a valid resource grid type. See parameters.setting.ResourceGrid for valid options.');
            end
        end
    end

    methods
        function obj = ResourceGrid(slotDuration, bandwidthHz)
            % resource grid class constructor
            % Sets all values to default values and calculates the
            % number of resource blocks.
            % This class constructor is kept very simple to enable an easy
            % use. Possible LTE compatible default values for slot duration
            % and bandwidth are 1 ms and 10MHz.
            %
            % input:
            %   slotDuration:       [1x1]double temporal duration of a slot in seconds
            %   bandwidthHz:        [1x1]double used bandwidth in Hz
            %                       This value is multiplied with the factor usableBandwidth.
            %   usableBandwidth:    [1x1]double percentage of bandwidth used for transmission 0...1

            % set the number of resource blocks in frequency domain in a slot
            obj.nRBFreq = floor(bandwidthHz * obj.usableBandwidth ./ obj.sizeRbFreqHz);
            % set the number of resource blocks in the time domain in a slot
            obj.nRBTime = floor(slotDuration ./ obj.sizeRbTimeS);
        end

        function isValid = checkConfig(obj, params)
            % checks if all users and basestations are equipped with
            % compatible numerologies.
            %
            % Tests if:
            %   - each basestation has at least one user of same
            %     numerology
            %   *- numerologies are compatible with resource grid
            %
            %
            % input:  [1x1]parameters.Parameters parameters
            % output: [1x1]logic true if valid
            isValid = true;

            % extract used numerologies from the basestations and antennas
            baseStationNumerologies = [];

            bsKeys = params.baseStationParameters.keys;
            nKeys = length(bsKeys);
            for iKey = 1:nKeys
                bsParam = params.baseStationParameters(bsKeys{iKey});
                antennas = bsParam.antenna;
                numerologies = [antennas.numerology];
                baseStationNumerologies = [baseStationNumerologies, numerologies];
            end

            ueKeys = params.userParameters.keys;
            nKeys = length(ueKeys);
            userNumerologies = zeros(1, nKeys);
            for iKey = 1:nKeys
                ueParam = params.userParameters(ueKeys{iKey});
                userNumerologies(iKey) = ueParam.numerology;
            end

            baseStationNumerologies = sort(unique(baseStationNumerologies));
            userNumerologies = sort(unique(userNumerologies));

            if any(userNumerologies ~= baseStationNumerologies)
                msg = "There are basestation numerologies without matching users. " + ...
                    "Consider adding users with numerolgies matching to the basestations!";
                warning(msg);
                isValid = false;
            end

            % go through the nSubcarrierRb for each numerology
            % if they are not integeres than this numerology cant be used

            for iNumerology = userNumerologies
                nSubcarrierRb = obj.nSubcarrierRb(iNumerology);
                if mod(nSubcarrierRb, 1) ~= 0
                    msg = "Numerology=" + iNumerology + " is not supported. " + ...
                        "Consider using a different type of resource grid";
                    warning(msg);
                    isValid = false;
                end
            end
        end

        function nSubcarrierSlot_base = get.nSubcarrierSlot_base(obj)
            % getter function for nSubcarrierSlot, the number of subcarriers per slot
            %
            % used properties: nRBFreq, nSubcarrierRb

            % The number of subcarriers in a slot is the number of
            % subcarriers in a resource block times the number of resource
            % block in a slot in frequency.
            nSubcarrierSlot_base = obj.nRBFreq .* obj.nSubcarrierRb_base;
        end

        function nSymbolRb_base = get.nSymbolRb_base(obj)
            % getter function for nSymbolRb, the number of symbols in time per resource block
            %
            % used properties: sizeRbTimeS, symbolDurationS

            % The number of symbols in time per resource block is the
            % duration of a resource block divided by the symbol duration.
            %NOTE: the floor operation should not be necessary
            nSymbolRb_base = floor(obj.sizeRbTimeS ./ obj.symbolDurationS_base);
        end

        function nSymbolSlot_base = get.nSymbolSlot_base(obj)
            % getter function for nSymbolSlot, the number of symbols in time in a slot
            %
            % used proeprties: nRBTime, sizeRbTimeS, symbolDurationS

            % The number of symbols in a resource block is the number of
            % resource blocks in time times the number of symbols per
            % resource block. Since the number of symbols per resource
            % block is a dependent parameter, the resource block duration
            % and symbol duration are used here.
            nSymbolSlot_base = obj.nRBTime .* floor(obj.sizeRbTimeS ./ obj.symbolDurationS_base);
        end

        function nRBTot = get.nRBTot(obj)
            % getter function for nRBTot, the total number of resource blocks in a slot
            %
            % used properties: nRBFreq, nRBTime

            % the total number of resource blocks is the number of resource
            % blocks in time times the number of resource blocks in
            % frequency
            nRBTot = obj.nRBFreq * obj.nRBTime;
        end

        function nSymbolRBTot = get.nSymbolRBTot(obj)
            % getter function for total number of symbols in a resource block
            %
            % used properties: nSubcarrierRb_base, nSymbolRb_base

            nSymbolRBTot = obj.nSubcarrierRb_base .* obj.nSymbolRb_base;
        end

        function sizeRbFreqHz = get.sizeRbFreqHz(obj)
            % getter function for sizeRbFreqHz, the size of a resource block in Hertz
            %
            % used proeprties: nSubcarrierRb, subcarrierSpacingHz

            % The bandwidth of a resource block is the bandwidth of a
            % subcarrier times the number of subcarriers in a resource
            % block.
            sizeRbFreqHz = obj.nSubcarrierRb_base .* obj.subcarrierSpacingHz_base;
        end

        %% numerology dependent parameters
        % Properties that are dependent on the numerology.
        % These are derived from the base grid.
        function subcarrierSpacingHz = subcarrierSpacingHz(obj, numerology)
            % subcarrier spacing in Hertz
            % Higher numerologies increases the subcarrierspacing.
            %
            % input:  [1x1]integer numerology parameter
            % output: [1x1]double subcarrier spacing in Hertz
            subcarrierSpacingHz = obj.subcarrierSpacingHz_base * 2^numerology;
        end

        function nSubcarrierRb = nSubcarrierRb(obj, numerology)
            % number of subcarrier in a resource block
            % Higher numerologies decreases the number of subcarriers.
            %
            % input:  [1x1]integer numerology parameter
            % output: [1x1]double number of subcarrier in a resource block
            nSubcarrierRb = obj.nSubcarrierRb_base / 2^numerology;
        end

        function nSubcarrierSlot = nSubcarrierSlot(obj, numerology)
            % number of subcarrier per slot for the given numerology if
            % numerology would use entire bandwith.
            % Higher numerologies increases the number of subcarriers.
            %
            % input:  [1x1]integer numerology parameter
            % output: [1x1]double number of subcarrier in a resource block
            nSubcarrierSlot = obj.nSubcarrierSlot_base / 2^numerology;
        end

        function nSymbolRb = nSymbolRb(obj, numerology)
            % number of symbols in time in a resource block
            % Higher numerologies increases the number of symbols in time.
            %
            % input:  [1x1]integer numerology parameter
            % output: [1x1]double number of symbols in time in a resource
            % block
            nSymbolRb = obj.nSymbolRb_base * 2^numerology;
        end
    end
end

