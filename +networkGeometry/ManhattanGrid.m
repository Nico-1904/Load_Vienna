classdef ManhattanGrid < networkGeometry.NodeDistribution
    %MANHATTANGRID creates location at the centre of manhattan grid buildings
    %   Creates the location of the centres of buildings arranged in a
    %   Manhattan grid with the house length and width and street width set
    %   in GridParameters in the given placementRegion. The grid is set in
    %   a way that at (0,0) coordinates a building has its centre.
    %
    % see also networkGeometry.NodeDistribution
    %
    % initial author: Agnes Fastenbauer

    properties
        % x length of a building in the Manhattan grid
        % [1x1]double x-size of a building
        xSize
        % y width of a building in the Manhattan grid
        % [1x1]double y-size of a building
        ySize
        % width of a stree in the Manhattan grid
        % [1x1]double width of a street
        streetWidth
    end

    properties (Access = private)
        % horizontal x distance between two building centres
        % [1x1]double horizontal distance between two network elements
        horizontalDistance

        % vertical y distance between two building centres
        % [1x1]double vertical distance between two network elements
        verticalDistance
    end

    methods
        function obj = ManhattanGrid(placementRegion, GridParameters)
            % class constructor for manhattan grid
            % Sets the grid parameters.
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]struct with grid parameters
            %       -ySize:         [1x1]double horizontal length of a building
            %       -xSize:         [1x1]double vertical width of a building
            %       -streetwidth:   [1x1]double width of a street

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set grid parameters
            obj.ySize	= GridParameters.ySize;
            obj.xSize	= GridParameters.xSize;
            obj.streetWidth = GridParameters.streetWidth;

            % calculate dependant grid parameters
            obj.horizontalDistance  = obj.streetWidth + obj.xSize;
            obj.verticalDistance    = obj.streetWidth + obj.ySize;
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
            %       -locationMatrix:    [2 x nPositions]double array with
            %                           (x;y)-postitions of network elements

            % find number of buildings in horizontal and vertical axis
            nX = floor(obj.xSpan / obj.horizontalDistance);
            nY = floor(obj.ySpan / obj.verticalDistance);

            minX = obj.origin2D(1) - nX*obj.horizontalDistance/2 + obj.horizontalDistance/2;
            minY = obj.origin2D(2) - nY*obj.verticalDistance/2 + obj.verticalDistance/2;
            [X, Y] = meshgrid(minX + (0:nX-1)*obj.horizontalDistance, minY + (0:nY-1)*obj.verticalDistance );

            streetMinX = minX - obj.streetWidth/2-obj.xSize/2;
            streetMinY = minY - obj.streetWidth/2-obj.ySize/2;

            nxStreet = nX+1;
            nyStreet = nY+1;

            streetMatX = repmat((0:nX)*obj.horizontalDistance, nyStreet, 1) + streetMinX;
            streetMatY = repmat((0:nY)*obj.verticalDistance, 1, nxStreet) + streetMinY;

            nStreetNodes = nxStreet*nyStreet;

            labelMatrix = reshape(1:nStreetNodes, nyStreet, nxStreet);
            connectionMatrix = zeros(nStreetNodes, nStreetNodes); % convention for creation: x coordinate "from" y coordinate "to"

            %% first row
            for ii = 2:nxStreet-1
                connectionMatrix(labelMatrix(1, ii-1), labelMatrix(1, ii)) = 1;
                connectionMatrix(labelMatrix(1, ii+1), labelMatrix(1, ii)) = 1;
                connectionMatrix(labelMatrix(2, ii), labelMatrix(1, ii)) = 1;
            end

            %% last row
            for ii = 2:nxStreet-1
                connectionMatrix(labelMatrix(nyStreet, ii-1), labelMatrix(nyStreet, ii)) = 1;
                connectionMatrix(labelMatrix(nyStreet, ii+1), labelMatrix(nyStreet, ii)) = 1;
                connectionMatrix(labelMatrix(nyStreet-1, ii), labelMatrix(nyStreet, ii)) = 1;
            end

            %% first column
            for ii = 2:nyStreet-1
                connectionMatrix(labelMatrix(ii+1, 1), labelMatrix(ii, 1)) = 1; % up
                connectionMatrix(labelMatrix(ii-1, 1), labelMatrix(ii, 1)) = 1; % down
                connectionMatrix(labelMatrix(ii, 2), labelMatrix(ii, 1)) = 1; % right
            end

            %% last column
            for ii = 2:nyStreet-1
                connectionMatrix(labelMatrix(ii+1, nxStreet), labelMatrix(ii, nxStreet)) = 1; % up
                connectionMatrix(labelMatrix(ii-1, nxStreet), labelMatrix(ii, nxStreet)) = 1; % down
                connectionMatrix(labelMatrix(ii, nxStreet-1), labelMatrix(ii, nxStreet)) = 1; % left
            end

            %% inner region
            for ii = 2:nyStreet-1
                for jj = 2:nxStreet-1
                    connectionMatrix(labelMatrix(ii, jj+1), labelMatrix(ii, jj)) = 1; % right
                    connectionMatrix(labelMatrix(ii+1, jj), labelMatrix(ii, jj)) = 1; % up
                    connectionMatrix(labelMatrix(ii, jj-1), labelMatrix(ii, jj)) = 1; % left
                    connectionMatrix(labelMatrix(ii-1, jj), labelMatrix(ii, jj)) = 1; % down

                end
            end

            %% corners
            % lower left
            connectionMatrix(labelMatrix(1, 2), labelMatrix(1, 1)) = 1;
            connectionMatrix(labelMatrix(2, 1), labelMatrix(1, 1)) = 1;

            % lower right
            connectionMatrix(labelMatrix(1, nxStreet-1), labelMatrix(1, nxStreet)) = 1;
            connectionMatrix(labelMatrix(2, nxStreet), labelMatrix(1, nxStreet)) = 1;

            % upper left
            connectionMatrix(labelMatrix(nyStreet, 2), labelMatrix(nyStreet, 1)) = 1;
            connectionMatrix(labelMatrix(nyStreet-1, 1), labelMatrix(nyStreet, 1)) = 1;

            % upper right
            connectionMatrix(labelMatrix(nyStreet, nxStreet-1), labelMatrix(nyStreet, nxStreet)) = 1;
            connectionMatrix(labelMatrix(nyStreet-1, nxStreet), labelMatrix(nyStreet, nxStreet)) = 1;

            % set output
            Locations.locationMatrix = [X(:).'; Y(:).'];

            Locations.streetLocationMatrix = [streetMatX(:).'; streetMatY(:).'];

            Locations.connectionMatrix = connectionMatrix;
            Locations.labels = labelMatrix(:);
        end
    end
end

