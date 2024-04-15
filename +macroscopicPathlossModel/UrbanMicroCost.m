classdef UrbanMicroCost < macroscopicPathlossModel.Cost231WI
    %UMI Urban Micro cell NLOS pathloss
    %   according to TR 125 996 V6.1.0 based on COST 231 Walfisch-Ikegami NLOS
    % The TR 125 996 model is a simplification of the COST 231
    % Walfisch-Ikegami NLOS model for the following parameters:
    %   Building Height (averageBuildingHeight):    12 m
    %   Building to building distance:              50 m
    %   Street width:                               25 m
    %   orientation for all paths:                  30 deg
    % and selection of metropolitan center.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    properties
        % standard defined properties used with a COST231 Walfisch
        % Ikegami
        % Height of the base station
        % [1x1] double
        bsHeight = 12.5;

        % Height of the user element
        % [1x1] double
        ueHeight = 1.5;

        % Identifier for the current path loss
        % [1x1] logical
        % defines if the current path loss model is applied to the non line
        % of sight or line of sight links
        isLOS
    end

    methods
        function obj = UrbanMicroCost(isLOS)
            % Constructor
            streetOrientation   = 30;
            buildingSeperationM = 50;
            streetWidthM        = 25;
            buildingHeightM     = 12;
            isUrban             = true;
            obj = obj@macroscopicPathlossModel.Cost231WI(streetOrientation,buildingSeperationM,streetWidthM,buildingHeightM,isUrban);
            obj.bsHeight        = 12.5;
            obj.ueHeight        = 1.5;
            obj.isLOS           = isLOS;
        end

        function pathlossdB = getPathloss(obj, frequencyGHz, distance2Dm, ~, userHeightm, antennaHeightm)
            % class constructor for macroscopicPathlossModel.UMi
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

            % calculate LOS/NLOS pathloss
            if obj.isLOS
                pathlossdB  = obj.losWIPathloss(distance2Dm, frequencyGHz*1e3);
            else
                pathlossdB	= obj.nlosWIPathloss(distance2Dm, frequencyGHz*1e3, antennaHeightm, userHeightm);
            end
        end
    end
end

