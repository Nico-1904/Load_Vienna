classdef ManhattanCity < blockages.City
    % Manhattan style city with rectangular buildings and streets
    % Block dimensions are calculated from streets and buildings.
    %
    % initial author: Lukas Nagel

    properties
        % [1x1]double length of a block (1 block corresponds to 1 building)
        xSize

        % [1x1]double width of a block
        ySize

        % [1x1]double width of the street also defines spacing between buildings
        streetWidth

        % [1x1]double minimal building height
        minBuildingHeight

        % [1x1]double maximal building height
        maxBuildingHeight
    end

    methods
        function obj = ManhattanCity(cityParameter, interferenceRegion)
            % ManhattanCity's constructor that builds the city according to
            % the parameters passed through cityParameter and tries to
            % place everything in the specified interferenceRegion
            %
            % input:
            %   cityParameter:      [1x1]handleObject parameters.city.Manhattan
            %   interferenceRegion: [1x1]handleObject parameters.regionOfInterest.Region
            %                       region in which blockages are placed
            %
            % see also blockages.StreetSystem,
            % blockages.Building

            % call superclass constructor
            obj = obj@blockages.City(cityParameter, interferenceRegion);

            % Set Parameters
            obj.xSize               = cityParameter.xSize;
            obj.ySize               = cityParameter.ySize;
            obj.streetWidth         = cityParameter.streetWidth;
            obj.minBuildingHeight	= cityParameter.minBuildingHeight;
            obj.maxBuildingHeight	= cityParameter.maxBuildingHeight;

            gridParams.xSize        = cityParameter.xSize;
            gridParams.ySize        = cityParameter.ySize;
            gridParams.streetWidth	= cityParameter.streetWidth;

            if ~isempty(obj.loadFile)
                obj.loadCityFromFile();
            else
                posGenerator      = networkGeometry.ManhattanGrid(interferenceRegion, gridParams);
                lTemp             = posGenerator.getLocations();
                positionBuildings = lTemp.locationMatrix;

                % create Buildings
                for iBuild = 1:size(positionBuildings, 2)
                    center      = positionBuildings(:, iBuild);
                    height      = rand(obj.randomHeightStream) * (cityParameter.maxBuildingHeight - cityParameter.minBuildingHeight) ...
                        + cityParameter.minBuildingHeight;

                    regularX  = [-1,  1, 1, -1, -1];
                    regularY  = [-1, -1, 1,  1, -1];
                    wallPathX = center(1) + cityParameter.xSize/2*regularX;
                    wallPathY = center(2) + cityParameter.ySize/2*regularY;
                    floorPlan  = [wallPathX; wallPathY];
                    newBuilding = blockages.Building(floorPlan, height, cityParameter.wallLossdB);

                    obj.buildings = [obj.buildings, newBuilding];
                end

                % create Street System
                obj.streetSystem = blockages.StreetSystem(lTemp.streetLocationMatrix, ...
                    lTemp.connectionMatrix, lTemp.labels', cityParameter.streetWidth);
            end

            if ~isempty(obj.saveFile)
                obj.saveCityToFile();
            end
        end
    end

    methods (Static)
        function city = getCity(cityParameter, params)
            % getCity generates the City according to cityParameters
            % The parameters needed are specified in parameters.city.Manhattan.
            %
            % input:
            %   cityParameter:	[1x1]handleObject parameters.city.Manhattan
            %   params:         [1x1]handleObject parameters.Parameters
            %
            % see also parameters.city.Manhattan

            % create city
            city = blockages.ManhattanCity(cityParameter, params.regionOfInterest.interferenceRegion);
        end
    end
end

