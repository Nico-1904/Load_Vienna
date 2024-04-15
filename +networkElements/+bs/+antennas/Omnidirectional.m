classdef Omnidirectional < networkElements.bs.Antenna
    %OMNIDIRECTIONAL omnidirectional antenna
    %   This class contains the gain calculations functions for an
    %   omnidirectional antenna.
    %
    % initial author: Agnes Fastenbauer, based on
    % network_element.omnidirectionalAntenna by Josep Colom Ikuno in LTE DL
    % Systemlevel simulator
    %
    % see also networkElements.bs.Antenna, parameters.basestation.antennas

    methods
        function obj = Omnidirectional()
            %OMNIDIRECTIONAL sets the maximum antenna gain to 0

            % call superclass costructor
            obj = obj@networkElements.bs.Antenna;

            % set maximum antenna gain
            obj.gaindBmax = 0;
            % set azimuth to zero, it is an irrelevant parameter for omnidirectional antennas
            obj.azimuth = 0;
        end

        function gaindB = gain(obj, User, ~, ~)
            %GAIN calculates the antenna gain in direction of the given user(s)
            %
            % input:
            %   User:   [1 x nUser]handleObject users for which antenna gain is to be calculated
            %           This is only used to get the correct number
            %           of gains, the user position has no effect
            %           on the antenna gain.
            %
            % output:
            %   gaindB: [1 x nUser]double antenna gain for each user

            % set antenna gain for all users - is the same in all directions
            gaindB = obj.gaindBmax * ones(1, size(User, 2));
        end
    end
end

