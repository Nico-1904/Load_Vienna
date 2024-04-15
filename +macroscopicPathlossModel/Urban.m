classdef Urban < macroscopicPathlossModel.PathlossModel
    %URBAN pathloss for vehicular urban area outside the high rise core
    %   according to 3GPP TS 36.942, subclause 4.5.2
    %   also described in 3GPP TR 101 110 V.3.2.0, subclause B.1.8.3
    % Macro cell propagation model for urban area is applicable for
    % scenarios in urban and suburban areas outside the high rise
    % core of the city where the buildings are of nearly uniform height. It
    % is a pathloss model for vehicular environment.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.Rural

    properties
        % average height of buildings in meter
        % [1x1]double average height of buildings in meter
        % It is calculated from the distance between the mean building
        % heigth and the UE height.
        % The distance between the mean building height is set to 10.5 m
        % for this model as described in 3GPP TR 101 110 V.3.2.0
        averageBuildingHeights
    end

    properties (SetAccess = private)
        % height difference between a building and a user equipment in meter
        % [1x1]double height difference in m
        % This is the height difference between a UE (usually at 1.5m
        % height) and the top of a building, where the antenna is
        % considered to be (which is usally 12m).
        deltaHm = 10.5;
    end

    methods
        function obj = Urban(averageBuildingHeights)
            % class constructor for macroscopicPathlossModel.Urban

            % set properties
            obj.averageBuildingHeights  = averageBuildingHeights;
        end

        function pathlossdB = getPathloss(obj, frequencyGHz, distance2Dm, distance3Dm, ~, antennaHeightm)
            % returns the pathloss value in dB
            % input:
            %   frequencyGHz:   [1 x nLinks]double frequency in GHz
            %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
            %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
            %   userHeightm:    [1 x nLinks]double user height in m
            %   antennaHeightm: [1 x nLinks]double antenna height in m
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % convert frequency to MHz
            frequencyMHz = frequencyGHz * 1e3;

            % get antenna height from average rooftop
            BSheightsFromRooftop	= antennaHeightm - obj.averageBuildingHeights;

            % calculate pathloss according to the model in dB
            pathlossdB = 40 * (1 - 4e-3 * BSheightsFromRooftop) .* log10(distance2Dm*1e-3) ...
                - 18*log10(BSheightsFromRooftop) + 21*log10(frequencyMHz) + 80;

            % ensure that the pathloss is no less than the free space pathloss
            FSPL = 20 * log10(4 * pi * distance3Dm .* frequencyGHz*1e9 / parameters.Constants.SPEED_OF_LIGHT);
            pathlossdB = max(pathlossdB, FSPL);
        end
    end
end

