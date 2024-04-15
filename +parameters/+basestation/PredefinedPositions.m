classdef PredefinedPositions < parameters.basestation.Parameters
    %PREDEFINEDPOSITIONS scenario of base stations with predefined base station positions
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.bs.BaseStation,
    % networkGeometry.PredefinedPositions

    properties
        % predefined positions in 2D
        % [2 x nBaseStations]double (x;y)-coordinates of the base stations
        % The height of the base station antennas has to be set as antenna
        % parameter in parameters.basestation.antennas.Parameters.
        positions
    end

    methods
        function obj = PredefinedPositions()
            % PredefinedPositions's constructor

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters;
        end

        function newBaseStations = createBaseStations(obj, params, ~)
            % create BS needed to support this antenna structure
            % antennas with the same number
            % Example: ant1.nBS =3 ant2.nBs=4
            % 4Bs will be created with the following antenna config:
            %       1BS : ant1.1, ant2.1
            %       2BS : ant1.2, ant2.2
            %       3BS : ant1.3, ant2.3
            %       4BS :         ant2.4
            % NOTE Antenna ant1.3 might interfere with ant2.4 because they
            % might not be sceduled to the same user.
            %
            % input:
            %   params:               [1 x 1]parameters.Parameters
            %   ~
            %
            % output:
            %   basestationList:      [1 x nBasestations]networkElements.bs.BaseStation
            %
            %   See also parameters.basestation.PredefinedPositions

            % get positions

            positionCreator = networkGeometry.PredefinedPositions(params.regionOfInterest.interferenceRegion, obj);
            locationStruct = positionCreator.getLocations();
            calculatedPositions = locationStruct.locationMatrix;

            newBaseStations = obj.createBaseStationsCommon(calculatedPositions,params);
        end

        function nBs = getEstimatedBaseStationCount(obj, ~)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor

            nBs = size(obj.positions, 2);
        end

        function checkParameters(obj)
            % check base station parameters

            % check superclass parameters
            obj.checkParametersSuperclass;

            % check position dimension
            if size(obj.positions, 1) ~= 2
                warning('bsPosition:dimension', 'The predefined base station positions should be of dimension [2 x nBaseStations].');
            end
        end
    end
end

