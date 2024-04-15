classdef Constants
    % CONSTANTS physical constants
    % These parameters should not be changed.
    %
    % initial author: Lukas Nagel

    methods (Static)
        function SPEED_OF_LIGHT = SPEED_OF_LIGHT()
            % speed of light in meter per second
            % [1x1]double speed of light in vacuum in m/s
            SPEED_OF_LIGHT = 299792458;
        end

        function NOISE_FLOOR = NOISE_FLOOR()
            % thermal noise density/noise floor in dB/Hz
            % [1x1]double thermal noise density in dB/Hz
            % This is the thermal noise power for a bandwidth of 1 Hz at a
            % temperature of 290?K. This corresponds to -174dBm/Hz (or
            % -204dB/Hz).
            %
            % NOISE_FLOOR = 10*log10(290 * 1.38064852e-23);
            % where 1.38e-23 m^2*kg*s^(-2)/K is the Boltzmann constant.
            %
            % see also networkElements.NetworkElementWithPosition,
            % networkElements.NetworkElementWithPosition.rxNoiseFiguredB
            NOISE_FLOOR = tools.todB(290 * 1.38064852e-23);
        end

        function RAD_EARTH = RAD_EARTH()
            % radius of the planet earth in meters
            % [1x1]double distance surface-core in m
            RAD_EARTH = 6371000;
        end
    end
end

