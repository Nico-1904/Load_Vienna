classdef RectangularGrid < networkGeometry.NodeDistribution
    %RECTANGULARGRID creates locations of a rectangular grid
    %   Creates the locations in the given placementRegion of a rectangular
    %   grid with the horizontal and vertical distance set in
    %   GridParameters. The grid is set in a way that at (0,0) coordinates
    %   a network element is located.
    %
    % see also networkGeometry.NodeDistribution,
    % networkGeometry.ManhattanGrid
    %
    % initial author: Agnes Fastenbauer

    properties
        % x distance between two network elements
        % [1x1]double horizontal distance between two network elements
        xDistance
        % y distance between two network elements
        % [1x1]double vertical distance between two network elements
        yDistance
    end

    methods
        function obj = RectangularGrid(placementRegion, GridParameters)
            % class constructor for manhattan grid
            % Sets the grid parameters.
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]struct with grid parameters
            %       -xDistance:	[1x1]double horizontal distance between two elements
            %       -yDistance:	[1x1]double vertical distance between two elements

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set grid parameters
            obj.xDistance = GridParameters.xDistance;
            obj.yDistance = GridParameters.yDistance;
        end

        function Locations = getLocations(obj)
            % returns locations of centres of buildings arranged in Manhattan grid
            % The Manhattan grid is set so that at (0,0) coordinates is the
            % centre of a building.
            %
            % used properties: length, horizontalDistance, width,
            % verticalDistance
            %
            % output:
            %   Locations:  [1x1]struct with locations of network elements
            %       -locationMatrix:    [2 x nPositions]double array with (x;y)-postitions of network elements

            % find number of buildings from (0)-axis in horizontal and vertical row
            nHorzMin =  ceil(obj.xMin / obj.xDistance);
            nVertMin =  ceil(obj.yMin / obj.yDistance);
            nHorzMax = floor(obj.xMax / obj.xDistance);
            nVertMax = floor(obj.yMax / obj.yDistance);

            % find minimum and maximum vaulue of x and y coordinate
            minHorz = nHorzMin * obj.xDistance;
            minVert = nVertMin * obj.yDistance;
            maxHorz = nHorzMax * obj.xDistance;
            maxVert = nVertMax * obj.yDistance;

            % create grid
            [X, Y] = meshgrid(minHorz:obj.xDistance:maxHorz, minVert:obj.yDistance:maxVert);

            % set output
            Locations.locationMatrix = [X(:).' ; Y(:).'];
        end
    end
end

