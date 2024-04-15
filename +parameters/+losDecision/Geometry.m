classdef Geometry < parameters.losDecision.losDecisionSuper
    %GEOMETRY parameter class that defines how to decide if the users and
    % antenna, LOS NLOS
    % If this class is instantiated the LOS/NLOS decision is based
    % on the scenario geometry.
    %
    % initial author: Christoph Buchner

    methods
        function isLos = getLOS(~, ~, nUser, nAntenna, nSegment, blockageMap, ~, ~)
            % set los based on blockageMap which is generated based on blockage geometry
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

            if ~isempty(blockageMap)
                % get table that indicates which links ago through a blockage
                % [nAntennas x nUsers x 1 x nSegment]
                isLos = sum(blockageMap, 3) == 0;
                isLos = permute(isLos, [2,1,4,3]);
            else
                isLos = true(nUser, nAntenna, nSegment);
            end
        end
    end
end

