classdef Urban < parameters.pathlossParameters.Parameters
    % parameter class for urban path loss according to 3GPP TS 36.942 subclause 4.5.2
    % vehicular urban area outside the high rise core
    % also described in 3GPP TR 101 110 V.3.2.0, subclause B.1.8.3
    %
    % Macro cell propagation model for urban and suburban areas outside
    % the high rise core where buildings are of nearly uniform height.
    % It is a pathloss model for vehicular test environment.
    % This model dscribes worst case propagation for NLOS case.
    %
    % The difference between the mean building height and the mobile
    % antenna height is set to 10.5 m for this model and used to
    % calculate the height of BS antenna from rooftop.
    %
    % Applicability range:
    %   Height of BS from rooftop:  0 ... 50m
    %   Distance UE to BS antenna:  few hundred meters ... kilometers
    %
    % This model is not very accurate for short distances.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.Urban, avgBuildingHeight

    properties
        % average building height in meter
        % [1x1]double average building height in m
        avgBuildingHeight = 20;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.Urban(obj.avgBuildingHeight);
        end
    end
end

