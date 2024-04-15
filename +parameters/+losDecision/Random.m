classdef Random < parameters.losDecision.losDecisionSuper
    %RANDOM los/nlos property is decided randomly with a set probability
    % This parameter class defines how to decide if the users of a user
    % group are los or nlos to all antennas over all times.
    %
    % initial author: Christoph Buchner

    properties
        % probability that a user is los to all antennas at all times
        % [1x1]double los probability
        losProbability = 0.5;
    end

    methods
        function isLos = getLOS(obj, ~, nUser, nAntenna, nSegment, ~, ~, ~)
            % random indoor/outdoor-decision
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

            % get random indoor/outdoor-decision according to probability
            isLos = rand(nUser, nAntenna , nSegment) <= obj.losProbability;
        end
    end
end

