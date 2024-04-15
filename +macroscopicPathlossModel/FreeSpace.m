classdef FreeSpace < macroscopicPathlossModel.PathlossModel
    % FREESPACE pathloss for free space
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.PathlossModelContainer,
    % macroscopicPathlossModel.FreeSpace

    properties
        % pathloss exponent alpha
        % [1x1]double pathloss exponent (should be bigger or equal 2)
        alpha
    end

    methods
        function obj = FreeSpace(alpha)
            % class constructor for macroscopicPathlossModel.FreeSpace
            %
            % input:
            %   alpha:  [1x1]double pathloss exponent

            % set parameters
            obj.alpha = alpha;
        end

        function pathlossdB = getPathloss(obj, frequencyGHz, ~, distance3Dm, ~, ~)
            % returns the pathloss according to the freespace model
            %
            % input:
            %   frequencyGHz:   [1 x nLinks]double frequency in GHz
            %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
            %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
            %   userHeightm:    [1 x nLinks]double user height in m
            %   antennaHeightm: [1 x nLinks]double antenna height in m
            %
            % output:
            %   pathlossdB: [1 x nLinks]double path loss of each link

            pathlossdB = obj.alpha .* tools.todB(4 * pi * distance3Dm .* frequencyGHz * 1e9 / parameters.Constants.SPEED_OF_LIGHT);

            % restrict that pathloss must be bigger than 0 dB
            pathlossdB = max(pathlossdB, 0);
        end
    end
end

