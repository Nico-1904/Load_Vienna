classdef HexGrid < parameters.basestation.Parameters
    %HEXGRID scenario of base stations positioned in a (flat topped) hexagonal grid
    % To place rings of base stations use the HexRing class. This class
    % places base station in a grid that stretches the whole simulation
    % region.
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.bs.BaseStation,
    % networkGeometry.HexagonalGrid,
    % parameters.basestation.antennas.Parameters

    properties
        % distance between two neighbouring base stations in m
        % [1x1]double vertical distance between two base stations in the hexagonal grid in m
        interBSdistance
    end

    methods
        function obj = HexGrid()
            % HexGrid's constructor

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters;
        end

        function newBaseStations = createBaseStations(obj, params, ~)
            % Create basestation network elements from this basestation
            % parameters.
            %
            % input:
            %   params:               [1 x 1]parameters.Parameters
            %   ~
            %
            % output:
            %   basestationList:      [1 x nBasestations]networkElements.bs.BaseStation
            %
            % See also networkGeometry.HexagonalGrid

            % get positions
            positionCreator = networkGeometry.HexagonalGrid(params.regionOfInterest.interferenceRegion, obj);
            locationStruct = positionCreator.getLocations();
            positions = locationStruct.locationMatrix;

            newBaseStations = obj.createBaseStationsCommon(positions,params);
        end

        function nBs = getEstimatedBaseStationCount(obj, params)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor

            roi = params.regionOfInterest;
            proi = roi.placementRegion;

            nElementsX = proi.xSpan * roi.interferenceRegionFactor / (obj.interBSdistance * sqrt(3) / 2);
            nElementsY = proi.ySpan * roi.interferenceRegionFactor / (obj.interBSdistance);
            nBs = nElementsX * nElementsY;
        end

        function checkParameters(obj)
            % check antenna parameters

            % check superclass parameters
            obj.checkParametersSuperclass;

            % check if inter base station distance is reasonable
            if obj.interBSdistance <= 0
                warning('interBSdist:small', 'The inter base station distance is too small to generate a realistic network.');
            end
        end
    end
end

