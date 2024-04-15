classdef HexagonalGrid < networkGeometry.NodeDistribution
    %HEXAGONALGRID returns coordinates of centres of flat topped hexagonal grid
    %   Creates the locations of the centres of a flat topped hexagonal
    %   grid with the centre location at (0,0) coordinates.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkGeometry.NodeDistribution

    properties
        % side length of a hexagon
        % [1x1]double length of the edge of a hexagon
        sideLength

        % smallest radius of a hexagon / height of a triangle constituing a hexagon
        % [1x1]double half of the width of the inter BS distance
        height
    end

    properties (Access = private)
        % horizontal distance (x coordinate) between two hexagon centres
        % [1x1]double x distance between two hexagon centres in the same row
        horizontalDistance

        % vertical distance (y coordinate) between two hexagon centres
        % [1x1]double y distance between two hexagon centres in the same column
        verticalDistance
    end

    methods
        function obj = HexagonalGrid(placementRegion, GridParameters)
            % class constructor, sets grid parameters
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]struct with grid parameters
            %       -interBSdistance: [1x1]double vertical distance between two neighbouring base stations
            %
            % calls superclass constructor
            %
            % sets sideLength, height, horizontalDistance, verticalDistance

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set grid parameters
            obj.verticalDistance    = GridParameters.interBSdistance;
            obj.height              = obj.verticalDistance / 2;
            obj.sideLength          = obj.verticalDistance / sqrt(3);
            obj.horizontalDistance	= sqrt(3) * obj.verticalDistance;
        end

        function Locations = getLocations(obj)
            % returns locations of centres of flat topped hexagons
            %
            % used properties: length, horizontalDistance, width,
            % verticalDistance
            %
            % output:
            %   Locations:  [1x1]struct with locations of network elements
            %       -locationMatrix:    [2 x nPositions]double array with
            %                           (x;y)-postitions of network elements

            %% horizontal coordinates
            % 1/2 number - 1 of hexagonal structures in the row that contains (0,0)
            nHexagonsRowEvenMax = floor(obj.xMax / obj.horizontalDistance);
            nHexagonsRowEvenMin =  ceil(obj.xMin / obj.horizontalDistance);
            % 1/2 number of hexagonal structures in the rows that are shifted
            nHexagonsRowOddMax = floor((obj.xMax + 0.5*obj.horizontalDistance) / obj.horizontalDistance);
            nHexagonsRowOddMin =  ceil((obj.xMin + 0.5*obj.horizontalDistance) / obj.horizontalDistance);

            % biggest x coordinate for even rows
            xMaxEven = nHexagonsRowEvenMax * obj.horizontalDistance;
            xMinEven = nHexagonsRowEvenMin * obj.horizontalDistance;
            xLocationEven = xMinEven:obj.horizontalDistance:xMaxEven;

            % biggest x coordinate for odd rows
            xMaxOdd = (nHexagonsRowOddMax - 0.5)* obj.horizontalDistance;
            xMinOdd = (nHexagonsRowOddMin - 0.5)* obj.horizontalDistance;
            xLocationOdd = xMinOdd:obj.horizontalDistance:xMaxOdd;

            %% vertical coordinates
            % 1/2 number - 1 of hexagonal structures in the column that contains (0,0)
            nHexagonsColumnEvenMax = floor(obj.yMax / obj.verticalDistance);
            nHexagonsColumnEvenMin =  ceil(obj.yMin / obj.verticalDistance);
            % 1/2 number of hexagonal structures in the rows that are 'verschoben'-
            nHexagonsColumnOddMax = floor((obj.yMax + 0.5*obj.verticalDistance) / obj.verticalDistance);
            nHexagonsColumnOddMin =  ceil((obj.yMin + 0.5*obj.verticalDistance) / obj.verticalDistance);

            % biggest y coordinate for even rows
            yMaxEven = nHexagonsColumnEvenMax * obj.verticalDistance;
            yMinEven = nHexagonsColumnEvenMin * obj.verticalDistance;
            yLocationEven = yMinEven:obj.verticalDistance:yMaxEven;

            % biggest y coordinate for odd rows
            yMaxOdd = (nHexagonsColumnOddMax - 0.5) * obj.verticalDistance;
            yMinOdd = (nHexagonsColumnOddMin - 0.5) * obj.verticalDistance;
            yLocationOdd = yMinOdd:obj.verticalDistance:yMaxOdd;

            % create grid
            [X1, Y1] = meshgrid(xLocationEven, yLocationEven);
            [X2, Y2] = meshgrid(xLocationOdd,  yLocationOdd);
            Locations.locationMatrix = [X1(:).', X2(:).'; Y1(:).', Y2(:).'];
        end
    end
end

