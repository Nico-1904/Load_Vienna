classdef SuburbanMacroCost < parameters.pathlossParameters.Parameters
    % parameter class for suburban macro cell according to COST-231
    % COST-Hata-Model as described in COST 231 Chapter 4
    %
    % For medium sized city and suburban centres with medium tree
    % density in large and small macro-cells, i.e. base station antenna
    % heights above rooftop levels adjacent to the base station and
    % approximately 3 km BS to BS distance.
    %
    % Applicability range:
    %   frequency:                      1500 MHz ... 2000 MHz
    %   base station antenna height:    30 m ... 200 m
    %   user antenna height:            1 m ... 10 m
    %   user to base station distance:  1 km ... 20 km
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.SuburbanMacroCost,
    % parameters.PathlossModelContainer

    methods
        function pathLossModel = createPathLossModel(~)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.SuburbanMacroCost;
        end
    end
end

