classdef losDecisionSuper < tools.HiddenHandle
    %MODEL NLOS LOS property is decided based on the defined pathloss model
    %
    % initial author: Agnes Fastenbauer

    methods (Abstract)
        % returns the LOS parameter for each link
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
        isLos = getLOS(obj, nLinks, nUser, nAntenna, nSegment, blockageMap, distance, userHeight);
    end
end

