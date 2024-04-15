classdef ChunkConfig < tools.HiddenHandle
    %ChunkConfig is a container class for chunk specific configuration.
    %   SimulationSetup creates a ChunkConfig for each ChunkSimulation.
    %   All information required for the simulation of one Chunk have to be
    %   included in the ChunkConfig such that the ChunkSimulation can run
    %   independently.
    %
    % initial author: Lukas Nagel

    properties
        % copy of the simulation parameters
        %[1x1]handleObject parameters.Parameters
        params

        % array with all base stations in this chunk
        % [1 x nBS]handleObject networkElements.bs.BaseStations
        baseStationList

        % array with all users in this chunk
        %[1 x nUser]handleObject networkElements.ue.User
        userList

        % objects that maps all antennas to the base station they belong to
        % [1x1]handleObject tools.AntennaBsMapper
        antennaBsMapper

        % list of all buildings in the scenario
        % [1 x nBuilding]handleObject blockages.Building
        buildingList

        % list of individual walls in the scenario
        % [1 x nWalls]handleObject blockages.WallsBlockage
        %NOTE: this is not a list of all walls in the scenario, the list of
        %all walls is made up of the walls in WallBlockageList and the
        %walls from buildingList.
        wallBlockageList

        % list of street systems
        % [x]handleObjct blockages.StreetSystem
        streetSystemList

        % new segment indicator for all slots
        % [1 x nSlots]logical indicates if slot is first in a segment
        % true: this slot is the first one in a new segment, the macroscale parameters have to be updatet
        % false: this slot is in the same segment as the previous slot
        isNewSegment

        % ini factors
        % [1x1]handleObject linkQualityModel.IniCache
        iniFactors
    end

    properties (Dependent)
        % total number of buildings in this chunk
        % [1x1]integer number of buildings
        nBuilding

        % total number of blockages in this chunk
        % [1x1]integer number of buildings
        nWallBlockages
    end

    methods
        function nBuilding = get.nBuilding(obj)
            % getter function for number of buildings in this chunk
            %
            % output:
            %   nBuilding:  [1x1]integer number of buildings in this chunk

            % get number of buildings
            nBuilding = length(obj.buildingList);
        end

        function nWallBlockages = get.nWallBlockages(obj)
            % getter function for number of blockages in this chunk
            %
            % output:
            %   nWallBlockages:  [1x1]integer number of blockages in this chunk

            % get number of blockages
            nWallBlockages = length(obj.wallBlockageList);
        end
    end
end

