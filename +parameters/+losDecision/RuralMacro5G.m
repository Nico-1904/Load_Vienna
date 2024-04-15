classdef RuralMacro5G < parameters.losDecision.losDecisionSuper
    % LOS probability from 3GPP TR 38.901 table 7.4.2-1 to the isLOS parameter

    methods
        function isLos = getLOS(~, nLinks, nUser, nAntenna, nSegment, ~, distancesInMeter2D, ~)
            % applies the LOS probability from 3GPP TR 38.901 table 7.4.2-1 to the isLOS parameter
            %
            % input:
            %   nLinks:         [1x1]integer number of links for which LOS indicator is calculated
            %   nUser:          [1x1]integer number of users for which LOS indicator is calculated
            %   nAntenna:       [1x1]integer number of antennas for which LOS indicator is calculated
            %   nSegment:       [1x1]integer number of segments for which LOS indicator is calculated
            %   blockageMap:    [nAntennas x nUsers x nWalls x nSegment]logical table indicating links blocked by walls
            %   distance:       [1 x nLinks]double 2D distance between each user and antenna in meters
            %   userHeight:     [1 x nLinks]double height of user equipment
            %
            % output:
            %   LOS:    [nUsers x nAntennas x nSegments]logical LOS state of each links

            LOS_prob = min(exp(-(distancesInMeter2D-10)/1000),1);
            isLos = LOS_prob >= rand(1, nLinks);
            isLos = reshape(isLos, [nUser,nAntenna,nSegment]);
        end
    end
end

