classdef Omnidirectional < parameters.basestation.antennas.Parameters
    %OMNIDIRECTIONAL omnidrectional antenna with 0 dBi gain
    % This antenna has the same gain of 0 dB in all directions.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.basestation.antennas.Parameters,
    % networkElements.bs.Antenna,
    % networkElements.bs.antennas.Omnidirectional,
    % networkElements.bs.Antenna.generateOmnidirectional

    methods
        function obj = Omnidirectional()
            % Omnidirectional class constructor

        end

        function checkParameters(obj)
            % check antenna parameters

            obj.checkParametersSuperclass;
        end
    end

    methods (Static)
        function createAntenna(antennaParameters, positionList, BS, params)
            % creates omnidirectional antennas with antennaParameters
            %
            % input:
            %   antennaParameters:  [1 x 1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   BS:                 [1x1]handleObject networkElements.BaseStation
            %   params:             [1x1]handleObject parameters.Parameters

            % create antenna object
            antenna = networkElements.bs.antennas.Omnidirectional;

            % set antenna parameters
            antenna.setGenericParameters(antennaParameters, positionList, params);

            % extend antenna list of BS
            BS.antennaList(end+1) = antenna;
        end
    end
end

