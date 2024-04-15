classdef PredefinedPositions < networkGeometry.NodeDistribution
    %PREDEFINEDPOSITIONS returns the given position in struct
    %   Returns the predefined positions in a struct that has the same
    %   structure as those returned by the other NodeDistribution classes.
    %
    % see also networkGeometry.NodeDistribution
    %
    % initial author: Agnes Fastenbauer

    properties
        % positions of the network elements
        % [3 x nPositions]double [x;y]coordinates of network elements
        positions
    end

    methods
        function obj = PredefinedPositions(placementRegion, GridParameters)
            % class constructor for PredefinedPositions
            %
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]struct with grid parameters
            %       -positions: [3 x nPositions]double positions of network elements

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % check and set positions
            obj.positions = GridParameters.positions;
            %obj.transposeLocationsIfNecessary;
            obj.checkLocationRange(obj.positions);
        end

        function Locations = getLocations(obj)
            % returns the predefined positions in a struct
            %
            %   Locations:  [1x1]struct with locations of network elements
            %       -locationMatrix:    [3 x nPositions]double array with
            %                           (x;y)-postitions of network elements

            % return positions
            Locations.locationMatrix = obj.positions;
        end
    end

    methods (Access = private)
        function transposeLocationsIfNecessary(obj)
            % transposes locations if size is [nPositions x 2]
            %
            % used properties: positions
            %
            % set properties: positions

            if (size(obj.positions, 1) ~= 2 && size(obj.positions, 2) == 2) ...
                    || (size(obj.positions, 1) ~= 3 && size(obj.positions, 2) == 3)
                % transpose positions matrix
                obj.positions = obj.positions.';
            end
        end
    end
end

