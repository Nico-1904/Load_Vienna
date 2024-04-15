classdef Manhattan < parameters.city.Parameters
    %MANHATTAN defines a scenario of a manhattan city with buildings and streets
    %
    % initial author: Lukas Nagel
    %
    % see also blockages.ManhattanCity

    properties
        % length of a block in meter
        % [1x1]double block length in meter
        xSize

        % width of a block in meter
        % [1x1]double block width in meter
        ySize

        % width of a street in meter
        % [1x1]double street width in meter
        streetWidth

        % minimum building height in meter
        % [1x1]double minimum building height in meter
        minBuildingHeight

        % maximum building height
        % [1x1]double maximum building height in meter
        maxBuildingHeight

        % wall loss in dB
        % [1x1]double wall loss in dB
        wallLossdB
    end

    properties (SetAccess = protected)
        % function that creates the city
        createCityFunction = @blockages.ManhattanCity.getCity;
    end

    methods
        function nBuildings = getEstimatedBuildingCount(obj, params)
            % Estimate the number of buildings in the city
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double estimated building count

            horizontalDistance = obj.streetWidth + obj.ySize;
            verticalDistance   = obj.streetWidth + obj.xSize;

            proi = params.regionOfInterest.placementRegion;
            % number of buildings in horizontal and vertical axis
            nX = floor(proi.xSpan / horizontalDistance);
            nY = floor(proi.ySpan / verticalDistance);

            nBuildings = nX * nY;
        end
    end
end

