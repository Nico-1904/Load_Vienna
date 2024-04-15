classdef UrbanMacro5G < parameters.pathlossParameters.Parameters
    % Pathloss for urban environment 3GPP TS 38.901
    % according to 3GPP TR 38.901 UMa
    % Parameter Ranges
    % Frequency           0.5 - 100 GHz
    % User Antenna Height 1.5 - 22.5 m
    % BS Antenna Height    10 - 150 m
    % distance2D           10 - 5000 m
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.UrbanMacro5G, isLos

    properties
        % indicator for whether LOS or NLOS model is used
        % [1x1]logical LOS indicator
        isLos = false;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.UrbanMacro5G(obj.isLos);
        end
    end
end

