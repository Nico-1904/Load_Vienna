classdef UrbanMicroCost < parameters.pathlossParameters.Parameters
    % parameter class for urban micro cell according to TR 25 996 V6.1.0
    % based on COST 231 Walfisch-Ikegami
    %
    % Choose LOS or NLOS model through isLos parameter.
    %
    % For less than 1 km distance from BS to BS and BS antenna height
    % at rooftop height.
    % Frequency range: 800 MHz ... 1900 MHz
    %
    % This corresponds to the COST 231 Walfisch-Ikegami NLOS model for
    % the following fixed parameters:
    %   BS antenna height: 12.5 m
    %   Building Height (averageBuildingHeight): 12 m
    %   Building to building distance: 50 m
    %   Street width: 25 m
    %   User antenna height: 1.5 m
    %   orientation for all paths: 30 deg
    %   and selection of metropolitan center.
    %
    % see also macroscopicPathlossModel.UrbanMicroCost,
    % parameters.PathlossModelContainer, isLos

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

            pathLossModel = macroscopicPathlossModel.UrbanMicroCost(obj.isLos);
        end
    end
end

