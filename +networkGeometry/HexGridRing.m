classdef HexGridRing < networkGeometry.NodeDistribution
    %HEXAGONALGRID returns coordinates of base stations in hexagonal rings
    %   Creates the locations of the centres of the given number of rings
    %   of a flat topped hexagonal grid with the centre location at (0,0)
    %   coordinates.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkGeometry.NodeDistribution,
    % networkGeometry.HexagonalGrid

    properties
        % side length of a hexagon
        % [1x1]double length of the edge of a hexagon
        sideLength
        % smallest radius of a hexagon / height of a triangle constituing a hexagon
        % [1x1]double half of the width of the inter BS distance
        height
        % number of rings of base stations
        % [1x1]integer number of base station rings
        nRing
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
        function obj = HexGridRing(placementRegion, GridParameters)
            % class constructor, sets grid parameters
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]handleObject parameters.basestation.HexRing
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
            obj.nRing               = GridParameters.nRing;
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

            % initialize locations
            nPositions = sum(1:obj.nRing)*6 + 1;
            Locations.locationMatrix = zeros(2, nPositions);

            %total nr. of eNodeBs
            % each ring consists of 6 NodeBs at the corners of the hexagon
            % each edge then has "i-1" further NodeBs, where "i" is the ring index
            % total_nr_eNodeB = sum(6*(1:n_rings))+1;

            % create regular grid
            [xGrid, yGrid] = meshgrid(-obj.nRing:obj.nRing, (-obj.nRing:obj.nRing)*sin(pi/3));

            if mod(obj.nRing,2) == 0
                % shift all even rows
                shiftIndices = 2:2:2*obj.nRing+1;
            else
                % shift all odd rows
                shiftIndices = 1:2:2*obj.nRing+1;
            end

            % shift x grid
            xGrid(shiftIndices,:) = xGrid(shiftIndices,:) + 0.5;

            % rotation operator
            rotate = @(w_) [cos(w_), -sin(w_); sin(w_), cos(w_)];

            tmp_hex = zeros(7,2);
            for i_ = 1:7
                %border of the network
                tmp_hex(i_,:) = ((obj.nRing+0.5)*rotate(pi/3)^(i_-1)*[1;0]).';
            end

            % cut off positions, that do not beong to the rings
            tmp_valid_positions = inpolygon(xGrid, yGrid, tmp_hex(:,1), tmp_hex(:,2));
            Locations.locationMatrix(2,:) = xGrid(tmp_valid_positions).*obj.verticalDistance + obj.origin2D(2);
            Locations.locationMatrix(1,:) = yGrid(tmp_valid_positions).*obj.verticalDistance + obj.origin2D(1);

            obj.checkLocationRange(Locations.locationMatrix);
        end
    end
end

