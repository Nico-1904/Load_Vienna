classdef OnBuildings < networkGeometry.NodeDistribution
    % generates nodes on top of rectangular buildings
    % A building gets a node based on a occupation probability.
    % The node is placed on a randomly selected edge of the building.
    % A margin between the edge and the node can be defined.
    % At least one node will always be generated.
    %
    % initial author: Alexander Bokor, moved code from Parameters class
    % to network geometry
    %
    % see also networkGeometry.NodeDistribution,
    % parameters.basestation.MacroOnBuildings

    properties (Access = private)
        % height above the building roof in meters
        % [1x1]double height of node above the roof in meters
        antennaHeight

        % probability that a building has a node
        % At least one node will always be generated on a random
        % building.
        % [1x1]double 0...1 occupation probability
        occupationProbability

        % margin from the edge to the node
        % the margin is applied randomly either in x or y direction
        % If the margin is bigger than the building size it will be ignored
        % for this building.
        % [1x1]double margin in meters
        margin

        % list of buildings
        % buildingList: [1 x nBuilding]blockages.Building
        buildingList
    end

    methods
        function obj = OnBuildings(placementRegion, GridParameters)
            % class constructor for OnBuildings
            % Sets the grid parameters.
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]struct with grid parameters
            %       -antennaHeight:         [1x1]double height of antennas
            %                               above the roof in meters
            %       -occupationProbability: [1x1]double 0...1 occupation probability
            %       -margin:   [1x1]double margin from the edge to the
            %       -buildingList: [1 x nBuilding]blockages.Building list
            %                      of buildings

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set grid parameters
            obj.antennaHeight = GridParameters.antennaHeight;
            obj.occupationProbability = GridParameters.occupationProbability;
            obj.margin = GridParameters.margin;
            obj.buildingList = GridParameters.buildingList;
        end

        function Locations = getLocations(obj)
            % returns locations of nodes on the edges of the top of the
            % buildings.
            %
            % output:
            %   Locations:  [1x1]struct with locations of network elements
            %       -locationMatrix:    [3 x nPositions]double array with
            %                           (x;y;z)-postitions of network elements

            buList = obj.buildingList;

            % get total number of buildings
            nBuildings = length(buList);

            % decide which buildings will have a node on them
            buildingsMask = rand(nBuildings,1) < obj.occupationProbability;

            % create at least one node on a random building if no
            % building was occupied
            if ~any(buildingsMask)
                buildingsMask(randi(length(buildingsMask))) = true;
            end

            selectedBuildings = buList(buildingsMask == 1);

            % total number of nodes to create
            nPositions = length(selectedBuildings);

            % calculate positions
            positions = zeros(3, nPositions);
            for iPos = 1:nPositions
                bu = selectedBuildings(iPos);

                % probability to apply margin on the x side
                p = bu.xSize /(bu.xSize + bu.ySize);
                marginOnX = rand() < p;
                if marginOnX
                    % set the margin on the x dimension
                    xDeviation = min(bu.xSize, obj.margin);
                    yDeviation = 0;
                else
                    % set the margin on the y dimension
                    xDeviation = 0;
                    yDeviation = min(bu.ySize, obj.margin);
                end

                % randomly position the node at one of the building corners
                x = bu.x + (bu.xSize / 2 - xDeviation) * sign(rand() - 1/2);
                y = bu.y + (bu.ySize / 2 - yDeviation)* sign(rand() - 1/2);

                positions(:, iPos) = [x; y; bu.height + obj.antennaHeight];
            end % for all base stations positions

            Locations = struct("locationMatrix", positions);
        end
    end
end

