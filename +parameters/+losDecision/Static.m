classdef Static < parameters.losDecision.losDecisionSuper
    %STATIC LOS/NLOS decision for users is constant
    % Static is a parameter class that defines how to decide if the users
    % of the user group are in line of sight or not to all antennas.
    %
    % initial author: Christoph Buchner
    %
    % see also parameters.setting.LOS

    properties
        % indicator for los users
        % [1x1]logical indicates if user is line of sight
        % This is true if users are los and false if users are nlos.
        isLos = false;
    end

    methods
        function isLos = getLOS(obj, ~, nUser, nAntenna, nSegment, ~, ~, ~)
            % static LOS/NLOS decision
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

            % set isLos matrix for all antennas and segments
            isLos = repmat(obj.isLos, nUser, nAntenna, nSegment);
        end
    end
end

