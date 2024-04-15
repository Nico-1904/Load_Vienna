classdef UrbanMacro3D < parameters.pathlossParameters.Parameters
    % parameter class for urban macro 3D path loss according to 3GPP TR 36.873 (V12.0.0)
    % with high user density where BS is above sorrounding buildings
    %
    % Applicability range:
    %   frequency range:            2GHz...6GHz
    %   heigth UE antenna:        	1.5m...22.5m
    %   2D distance UE-BS:          10m...5000m LOS
    %   2D distance UE-BS outdoor:  10m...1000m Outdoor to Indoor
    %   2D distance UE-BS outdoor assumed uniformly distributed between 0
    %   and 25 m indoor for Outdoor to Indoor
    %   height BS antenna:          25m
    %   average building height:    5m...50m
    %   street width:               5m...50m
    %
    %NOTE: in the outdoor to indoor scenario of the TR 36.873 standard
    %the height of the user equipment is h_U_T = 3*(n_f_l - 1) + 1.5
    %with n_f_l = 1, 2, 3, 4, 5, 6, 7, 8
    %This is not considered here, the actual user antenna height is
    %used for the calculation of the pathloss.
    %
    % see also macroscopicPathlossModel.UrbanMacro3D, isLos, isIndoor

    properties
        % average building height in meter
        % [1x1]double street width in m
        avgStreetWidth         = 20;

        % average street width in meter
        % [1x1]double building height in m
        avgBuildingHeight      = 20;

        % indicator for whether LOS or NLOS model is used
        % [1x1]logical LOS indicator
        isLos = false;

        % indicator for whether indoor or outdoor model is used
        % [1x1]logical LOS indicator
        isIndoor = false;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.UrbanMacro3D(obj.avgStreetWidth, obj.avgBuildingHeight, obj.isLos, obj.isIndoor);
        end

        function checkParameters(obj)
            % checks parameter settings

            if obj.avgBuildingHeight < 5 || obj.avgBuildingHeight > 50
                warning('warn:builHeight', 'The building height is outside of the applicable range of 5 to 50 m.');
            end

            if obj.avgStreetWidth < 5 || obj.avgStreetWidth > 50
                warning('warn:streetWidth', 'The street width is outside of the applicable range of 5 to 50 m.');
            end
        end
    end
end

