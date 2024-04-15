classdef Parameters < tools.HiddenHandle & matlab.mixin.Heterogeneous
    %PARAMETERS superclass for antenna object creation
    %   This class contains all parameters necessary for antenna creation.
    % The antennas attached to a base station are created, when the base
    % station is created and the settings for the antenna are taken from
    % this class.
    %
    % initial author: Agnes Fastenbauer
    % extended by: Christoph Buchner added technology parameter
    %
    % see also networkElements.bs.Antenna,
    % parameters.basestation.Parameters,
    % parameters.basestation.antennas.Omnidirectional,
    % parameters.basestation.antennas.SixSector,
    % parameters.basestation.antennas.ThreeSector,
    % parameters.basestation.antennas.ThreeSectorBerger,
    % parameters.basestation.antennas

    properties
        % number of transmit RF chains
        % [1x1]integer number of transmit antenna ports
        nTX = 1;

        % number of receive antennas
        % [1x1]integer number of receive antennas
        nRX = 1;

        % type of the base station can be macro, pico or femto
        % [1x1]enum parameters.setting.BaseStationType
        baseStationType = parameters.setting.BaseStationType.macro;

        % analog precoder type
        % [1x1]enum parameters.setting.PrecoderAnalogType
        precoderAnalogType = parameters.setting.PrecoderAnalogType.none;

        % antenna height in meters
        % [1x1]double height at which antenna is positioned
        %NOTE: for parameters.basestation.MacroOnBuildings a different
        %antennaHeight, that represents the height of the antenna above the
        %rooftop it is placed on, is defined and this antenna height is not
        %used.
        % see also parameters.basestation.MacroOnBuildings,
        % parameters.basestation.MacroOnBuildings.antennaHeight
        height = 30;

        % transmit power in W
        % [1x1]double transmit power of antenna in Watt
        transmitPower = nan;

        % indicates if the antenna is an interferer if no users are scheduled
        % [1x1]logical indicates if antenna is always transmitting
        % If this is true the antenna is always transmitting and generating
        % interference even if no users are scheduled at the base station
        % in this slot.
        %NOTE: This is applied in the link quality model, where the
        %antennas that do not generate interference are not added as
        %interference.
        alwaysOn = true;

        % receiver noise figure in dB for this antenna type
        % [1x1]double receiver noise figure in dB
        %
        % see also parameters.Constants.NOISE_FLOOR,
        % networkElements.NetworkElementWithPosition.setThermalNoisePower
        rxNoiseFiguredB = 5;

        % numerology used on this antenna
        % [1x1]integer numerology indicator 0 ... 5
        % this is equivialent to the 5G numerology parameter
        numerology = 0;

        % technology used for this NetworkElement
        % [1x1]enum parameters.setting.NetworkElementTechnology
        %
        % see also: simulation.ChunkSimulation.cellAssociation
        technology = parameters.setting.NetworkElementTechnology.LTE;

        % azimuth angle in which the antenna has its maximum gain in degrees
        % [1x1]double azimuth angle in radians in which this antenna has its maximum gain
        azimuth = 0;

        % elevation angle in which the antenna has its maximum gain in degrees
        % [1x1]double elevation angle in radians in which this antenna has its maximum gain
        elevation = 90;
    end

    methods (Abstract)
        % check antenna parameters
        checkParameters(obj)
    end

    methods (Abstract, Static)
        % Create antenna network elements from antennaParameters.
        % This function creates the antennas for the given
        % basestation.
        %
        % input:
        %   antennaParameters:  [1 x 1]handleObject parameters.basestation.antennas.Parameters
        %   positionList:       [3 x nSlot]double position of antenna in each slot
        %   BS:                 [1 x 1]handleObject networkElements.BaseStation
        %   params:             [1 x 1]handleObject parameters.Parameters
        createAntenna(antennaParameters, positionList, BS, params)
    end

    methods (Access = protected)
        function checkParametersSuperclass(obj)
            % check general antenna parameters

            % check base station height
            if obj.height < 0
                warning('antennaHeight:low', 'The base station height is set to a value below 0.');
            end
        end
    end
end

