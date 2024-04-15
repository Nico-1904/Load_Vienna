classdef HexRing < parameters.basestation.Parameters
    %HEXRING scenario of base stations positioned in rings of a (flat
    % topped) hexagonal grid.
    % This class creates the specified amount of rings of base stations.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkElements.bs.BaseStation,
    % networkGeometry.HexGridRing,
    % parameters.basestation.antennas.Parameters

    properties
        % distance between two neighbouring base stations in m
        % [1x1]double vertical distance between two base stations in the hexagonal grid in m
        interBSdistance = 150;

        % number of rings of base stations
        % [1x1]integer number of base station rings
        % If this is set to zero only one base station at the center of the
        % ROI will be created. If this is set to one, a base station at the
        % center and 6 base stations in a ring around the center will be
        % created. For higher numbers more rings of base stations will be
        % added.
        nRing = 1;
    end

    methods
        function obj = HexRing()
            % HexGrid's constructor

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters;
        end

        function newBaseStations = createBaseStations(obj, params, ~)
            % Create base station network elements from this base station
            % parameters.
            %
            % input:
            %   params:               [1 x 1]parameters.Parameters
            %   ~
            %
            % output:
            %   newBaseStations:      [1 x nBasestations]networkElements.bs.BaseStation
            %
            % see also networkGeometry.HexGridRing

            % get positions
            positionCreator = networkGeometry.HexGridRing(params.regionOfInterest.interferenceRegion, obj);
            locationStruct = positionCreator.getLocations();
            positions = locationStruct.locationMatrix;

            %sort positions by radius
            [~, r]              = cart2pol(positions(1,:), positions(2,:));
            [~ , sortIndices]   = sort(r);
            positions(:,1:size(positions,2))= positions(:,sortIndices);
            % find BSindex for regular BS
            nRegularBS   = sum(1:obj.nRing)*6 + 1;

            %create only the regular BS
            newBaseStations = obj.createBaseStationsCommon(positions(:,1:nRegularBS),params);
        end

        function nBs = getEstimatedBaseStationCount(obj, ~)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor
            nBs = 6 * obj.nRing + 1;
        end

        function checkParameters(obj)
            % check base station parameters

            % check superclass parameters
            obj. checkParametersSuperclass;

            % check inter base station distance
            if obj.interBSdistance <= 0
                warning('interBSdist:small', 'The inter base station distance is too small to generate a realistic network.');
            end

            % check if number of base station rings to generate is sensible
            if obj.nRing <= 0
                warning('nRingBS:small', 'At most one base station of type HexRing will be positioned in the network.');
            end
        end
    end
end

