classdef Fixed < macroscopicPathlossModel.PathlossModel
    %fixedPathlossModel always returns the set pathloss value in dB
    %
    % Returns the pathloss in dB fixed in pathlossModel for each
    % component carrier of the given link.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.PathlossModelContainer,
    % macroscopicPathlossModel.Fixed

    properties
        % fixed pathloss in dB
        % [1x1]double fixed pathloss value
        fixedPathlossdB
    end

    methods
        function obj = Fixed(fixedPathlossdB)
            % class constructor for macroscopicPathlossModel.Fixed
            %
            % input:
            %   fixedPathlossdB:    [1x1]double fixed pathloss value

            % set pathloss value
            obj.fixedPathlossdB = fixedPathlossdB;
        end

        function pathlossdB = getPathloss(obj, ~, distance2Dm, ~, ~, ~)
            % returns the path loss value for each link
            %
            % input:
            %   frequencyGHz:   [1 x nLinks]double frequency in GHz
            %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
            %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
            %   userHeightm:    [1 x nLinks]double user height in m
            %   antennaHeightm: [1 x nLinks]double antenna height in m
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % set pathloss
            pathlossdB  =  obj.fixedPathlossdB * ones(size(distance2Dm));
        end
    end
end

