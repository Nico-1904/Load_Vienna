classdef ThreeSector < parameters.basestation.antennas.Parameters
    %THREESECTOR Three Sector antenna according to 3GPP TS 36 942
    % 3 sector antenna according to 3GPP TS 36.942 section 4.2.1
    %
    % In this standard a rural antenna scenario for 900 MHz and antenna
    % height 45 m is defined, as well as urban area scenarios with 30 m
    % antenna height for 900 MHz and 2 GHz. The maximum antenna gain is
    % then set according to table 4.3 in TS 36.942.
    %
    % In case the antenna settings deviate from the values defined in
    % the standard, the maximum antenna gain is set to 15dBi and a
    % warning is displayed.
    % The settings of this antenna depend on the antenna height and
    % carrier frequency.
    %
    % This is a 3 sector antenna with:
    % 15 or 12 dBi antenna gain (depending on scenario and carrier frequency)
    % 20 dB maximum attenuation
    % 65deg 3dB beam width
    %
    % initial author: Agnes Fastenbauer
    % extended by: Thomas Lipovec, Changed to a single three sector antenna
    %
    % see also parameters.basestation.antennas.Parameters,
    % networkElements.bs.Antenna,
    % networkElements.bs.antennas.ThreeSector,
    % networkElements.bs.Antenna.generateThreeSector

    properties (SetAccess = protected)
        % 3 dB beam width
        % [1x1]integer 3dB beam width as defined by standard
        theta3dB = 65;
    end

    methods
        function obj = ThreeSector()
            % ThreeSector class constructor

        end

        function checkParameters(obj)
            % check antenna parameters

            % check superclass parameters
            obj.checkParametersSuperclass;
        end
    end

    methods (Static)
        function createAntenna(antennaParameters, positionList, BS, params)
            % creates a single ThreeSector antenna with antennaParameters
            %
            % input:
            %   antennaParameters:  [1 x 1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   BS:                 [1 x 1]handleObject networkElements.BaseStation
            %   params:             [1 x 1]handleObject parameters.Parameters

            % preallocate antenna object
            newAntenna = networkElements.bs.antennas.ThreeSector();

            % set antenna parameters
            newAntenna.setGenericParameters(antennaParameters, positionList, params);

            % extend antennaList in the BS
            BS.antennaList(end+1) = newAntenna;
        end
    end
end

