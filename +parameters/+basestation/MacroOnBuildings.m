classdef MacroOnBuildings < parameters.basestation.Parameters
    % Generates base stations on top of buildings.
    % A building gets a base station based on a occupation probability.
    % The antenna is placed on a randomly selected edge of the building.
    % A margin between the edge and the base station can be defined.
    % At least on base station will always be generated.
    %
    % initial author:  Lukas Nagel
    % extended by: Thomas Lipovec, Moved the actual creation of the BS to
    % the method of the superclass createBaseStationsCommon
    % extended by: Alexander Bokor, Bugfixes and more documentation
    %
    % see also networkElements.bs.BaseStation, networkGeometry.OnBuildings

    properties
        % height above the building roof in meters
        % [1x1]double height of antennas above the roof in meters
        % NOTE: This is not to be confused with
        % parameters.basestation.Parameters.height, which is the height from
        % the ground (z = 0) and is not used for this base station type.
        antennaHeight

        % probability that a building has a base station
        % At least one base station will always be generated on a random
        % building.
        % [1x1]double 0...1 occupation probability
        occupationProbability

        % margin from the edge to the antenna
        % the margin is applied randomly either in x or y direction
        % If the margin is bigger than the building size it will be ignored
        % for this building.
        % [1x1]double margin in meters
        margin
    end

    methods
        function obj = MacroOnBuildings()
            % MacroOnBuildings's constructor

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters;
        end

        function newBaseStations = createBaseStations(obj, params, buildingList)
            % Create basestation network elements from this base station
            % parameters.
            %
            % input:
            %   params:               [1 x 1]parameters.Parameters
            %   buildingList:         [1 x nBuilding]blockages.Building
            %
            % output:
            %   basestationList:      [1 x nBasestations]networkElements.bs.BaseStation
            %
            % initial author: Lukas Nagel
            % extended by: Alexander Bokor, simplified code and added
            % comments

            % set antenna heights from the antenna parameters to zero
            % because antenna heights will be calculated from the building
            % heights + obj.antennaHeight
            obj.antenna.height = 0;

            % create geometry struct
            geometryParams = struct();
            geometryParams.antennaHeight = obj.antennaHeight;
            geometryParams.occupationProbability = obj.occupationProbability;
            geometryParams.margin = obj.margin;
            geometryParams.buildingList = buildingList;

            positionCreator = networkGeometry.OnBuildings(params.regionOfInterest, geometryParams);
            locationStruct = positionCreator.getLocations();
            positions = locationStruct.locationMatrix;

            % set base station parameters and create antennas
            newBaseStations = obj.createBaseStationsCommon(positions, params);
        end

        function nBs = getEstimatedBaseStationCount(obj, params)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor

            % we need to look for buildings in the buildings parameters AND
            % in the city parameters
            nBuildings = 0;
            for upa = params.buildingParameters.values
                nBuildings = nBuildings + upa{1}.getEstimatedBuildingCount(params);
            end
            for upa = params.cityParameters.values
                nBuildings = nBuildings + upa{1}.getEstimatedBuildingCount(params);
            end

            nBs = ceil(nBuildings * obj.occupationProbability);
        end

        function checkParameters(obj)
            % check base station parameters

            % check superclass parameters
            obj.checkParametersSuperclass;

            % fix possible wrong setting if occupation probability is given in percentage
            if obj.occupationProbability > 1
                obj.occupationProbability = obj.occupationProbability/100;
                warning('probability:notAProbability', 'The occupation probabilty for MacroOnBuilding base stations has been divided by 100 to get a value between 0 and 1.');
            end

            % check if probability is a probability
            if obj.occupationProbability < 0 || obj.occupationProbability > 1
                error('probability:notAProbability', 'Please set the occupation probabilty for MacroOnBuilding base stations to a value between 0 and 1.');
            end

            % check antennaHeight
            if obj.antennaHeight > 10
                warning('antennaHeight:veryHigh', 'Note that the antennaHeight for macroOnBuilding base station is the height above the building.');
            end
        end
    end
end

