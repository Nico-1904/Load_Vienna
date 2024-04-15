classdef UrbanMacro5G < parameters.losDecision.losDecisionSuper
    % LOS based on 3GPP TR 38.901 (V 14.0.0) Release 14 Page 28 Table 7.4.2-1

    methods
        function isLos = getLOS(~, nLinks, nUser, nAntenna, nSegment, ~, outDistance, UEantennaHeightm)
            % Calculate LOS based on 3GPP TR 38.901 (V 14.0.0) Release 14 Page 28 Table 7.4.2-1
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

            C = macroscopicPathlossModel.UrbanMacro5G.getC(outDistance, UEantennaHeightm, nLinks);
            PLos = min( ...
                (18./outDistance...
                + exp(-outDistance/63).*(1-18./outDistance))...
                .* (1+5/4*C.*(outDistance/100).^3 .* exp(-outDistance/150))...
                ,1);
            isLos = rand(1, nLinks) <= PLos;
            isLos = reshape(isLos,[nUser,nAntenna,nSegment]);
        end
    end
end

