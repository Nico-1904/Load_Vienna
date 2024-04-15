classdef UrbanMicro3D < parameters.losDecision.losDecisionSuper
    % calculate LOS based on 3GPP TR 36.873 (V12.0.0) Table 7.2-2  Page 22

    methods
        function isLos = getLOS(~, nLinks, nUser, nAntenna, nSegment, ~, distance, ~)
            % calculate LOS based on 3GPP TR 36.873 (V12.0.0) Table 7.2-2  Page 22
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

            PLos    = min(18./distance, 1) .* (1-exp(-distance/36)) + exp(-distance/36);
            isLos   = PLos >= rand(1, nLinks);
            isLos   = reshape(isLos, [nUser,nAntenna,nSegment]);
        end
    end
end

