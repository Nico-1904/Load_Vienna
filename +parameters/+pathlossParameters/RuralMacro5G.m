classdef RuralMacro5G < parameters.pathlossParameters.Parameters
    % parameter class for rural path loss according to 3GPP TS 38.901 RMa
    %
    % Applicability rang:
    %   Frequency           0.5 - 30 GHz
    %   User Antenna Height   1 - 20 m
    %   BS Antenna Height    10 - 150 m
    %   avg. Building Height  5 - 50 m
    %   avg. Street Width     5 - 50 m
    %   distance2D           10 - 5000 m
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.RuralMacro5G, isLos,
    % avgStreetWidth, avgBuildingHeight

    properties
        % indicator for whether LOS or NLOS model is used
        % [1x1]logical LOS indicator
        isLos = false;

        % average street width
        % [1x1]double average street width
        avgStreetWidth = 20;

        % average building height in meter
        % [1x1]double average building height in meter
        avgBuildingHeight = 5;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.RuralMacro5G(obj.avgStreetWidth, obj.avgBuildingHeight, obj.isLos);
        end

        function checkParameters(obj)
            % checks the range of the parameters for the model

            if obj.avgStreetWidth < 5 || obj.avgStreetWidth > 50
                warningMessage = 'The street width is outside of the applicability range of the model. ';
                warning('warning:strWidthSize', warningMessage);
            end

            if obj.avgBuildingHeight < 5 || obj.avgBuildingHeight > 50
                warningMessage = 'The averageBuildingHeightm is not in the applicability range of the model. ';
                warning('warning:avgBuildingSize', warningMessage);
            end
        end
    end
end

