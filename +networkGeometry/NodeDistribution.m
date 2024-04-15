classdef NodeDistribution < tools.HiddenHandle
    %NODEDISTRIBUTION creates 2D positions for different spatial distributions
    %   Returns a struct with the positions of the distributed network
    %   elements and other parameters, depending on the chosen
    %   distribution.
    %   The positions are saved in a [2 x nPositions]double matrix with the
    %   x coordinates (horizontal) in the first row and the y coordinates
    %   in the second row.
    %   NOTE: for predefined positions, the positions are saved in a
    %   [3 x nPositions]double matrix with the z-coordinates containing the
    %   user heights in (3,:).
    %
    % see also networkGeometry.GaussCluster, networkGeometry.HexagonalGrid,
    % networkGeometry.ManhattanGrid, networkGeometry.PredefinedPositions,
    % networkGeometry.UniformCluster, networkGeometry.UniformDistribution,
    % networkGeometry.RectangularGrid
    %
    % initial author: Agnes Fastenbauer

    properties
        % center of the interference region
        %[1x2]double [x,y]-coordinate of the center of the interference region
        origin2D
        % length of region
        % [1x1]double length of the region (horizontal size, x coordinate)
        % This is the horizantal length of the region in which network
        % elements are distributed.
        xSpan
        % width of region
        % [1x1]double width of the region (vertical size, y coordinate)
        % This is the vertical width of the region in which network
        % elements are distributed.
        ySpan
        % minimal x coordinate of the interference region
        % [1x1]double minimal x coordinate of the interference region
        xMin
        % maximal x coordinate of the interference region
        % [1x1]double maximal x coordinate of the interference region
        xMax
        % minimal y coordinate of the interference region
        % [1x1]double minimal y coordinate of the interference region
        yMin
        % maximal y coordinate of the interference region
        % [1x1]double maximal y coordinate of the interference region
        yMax
        % surface of the region
        % [1x1]double surface of the region in sq m
        % Surface of the region in which elements are distributed.
        % It is used for determining the number of elements to distribute
        % through a poisson random variable.
        % It corresponds to the Lebesgue measure.
        area
    end

    properties (Access = protected)
        % coordinates to set (0,0) as center of map
        % [2x1]double   coordinate transform to move (0,0) cooordinate from
        %               lower left corner to center of map
        %               [x;y] coordinates for coordinate transfom
        coord2zeroCenter
    end

    methods (Abstract)
        % Returns the locations of the distributed network elements
        Locations = getLocations(obj);
    end

    methods
        function obj = NodeDistribution(placementRegion)
            % class constructor for NodeDistribution, sets map size and coordinates
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.regionOfInterest.Region
            %
            % set properties: origin2D, length, width, area, xMin, xMax,
            % xMax, yMin, yMax

            % set dimensions of ROI
            obj.origin2D    = placementRegion.origin2D;
            obj.xSpan       = placementRegion.xSpan;
            obj.ySpan       = placementRegion.ySpan;
            obj.xMin        = placementRegion.xMin;
            obj.xMax        = placementRegion.xMax;
            obj.yMin        = placementRegion.yMin;
            obj.yMax        = placementRegion.yMax;

            % set other parameters
            obj.setCoord2zeroCenter;
        end
    end

    methods (Access = protected)
        function setCoord2zeroCenter(obj)
            % calculates and sets coord2zeroCenter
            %
            % used properties: length, width
            %
            % set properties: coord2zeroCenter

            obj.coord2zeroCenter = [obj.xMin; obj.yMin];
        end

        function setArea(obj)
            % calculate and set area
            %
            % used properties: length, width
            %
            % set properties: area

            obj.area = obj.xSpan * obj.ySpan;
        end

        function nElements = getNumberOfElements(obj, density)
            % sets the number of elements according to a Poisson random variable
            % The mean of the Poisson random variable is set to the mean
            % number of network elements according to the density and the
            % area of the ROI. If the number of elments is 0, then 1
            % element is placed on the map.
            %
            % input:
            %   density:    [1x1]double density of network elements
            %
            % used properties: area
            %
            % output:
            %   nElements:  [1x1]integer number of network elements to be
            %               distributed

            nElements = max(poissrnd(density * obj.area), 1); % minimal 1 element to distribute
        end

        function checkLocationRange(obj, locationMatrix)
            % checks if coordinates of locationMatrix are within the ROI
            %
            % input:
            %   locationMatrix: [2 x nPositions]double array with
            %                 	(x;y)-postitions of network elements
            %
            % used properties: xMax, xMin, yMax, yMin

            if size(locationMatrix, 1) ~= 3 && size(locationMatrix, 1) ~= 2
                error('error:notValidPosition', 'Network elements coordinates have the wrong structure, they are not a [3 x n] matrix.');
            end

            if max(locationMatrix(1,:)) > obj.xMax || min(locationMatrix(1,:)) < obj.xMin
                warning('warning:positionOutOfRoi', 'Network elements coordinates are outside of the map.');
            end

            if max(locationMatrix(2,:)) > obj.yMax || min(locationMatrix(2,:)) < obj.yMin
                warning('warning:positionOutOfRoi', 'Network elements coordinates are outside of the map.');
            end
        end
    end
end

