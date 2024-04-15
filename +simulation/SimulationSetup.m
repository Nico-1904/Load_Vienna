classdef SimulationSetup < tools.HiddenHandle
    %SimulationSetup prepares a simulation
    %   SimulationSetup handles all parts of the simulation that have to or
    %   should be done outside the ChunkSimulation: the creation
    %   of network elements and network geometry and the initialization of
    %   the small scale fading traces. And after the element creation the
    %   distribution of information to the chunks.
    %
    % initial author: Lukas Nagel
    %
    % see also simulationLauncher, simulate, simulation.ChunkSimulation

    properties
        % simulation parameters
        % [1x1]handleObject parameters.Parameters
        params

        % list of configurations for each chunk
        % [1 x nChunks]handleObject simulation.ChunkConfig
        chunkConfigList

        % matrix with absolute time in each simulated slot
        % [nChunks x nSlotsPerChunk]double absolute time in time slot in s
        timeMatrix

        % list of all buildings in the simulation
        % [1 x nBuildings]handleObject blockages.Building
        buildingList = [];

        % list of all walls in the simulation (excluding walls that make a building)
        % [1 x nWalls]handleObject blockages.WallBlockage
        wallBlockageList = [];

        % list of base stations in the simulation
        % [1 x nBS]handleObject networkElements.bs.BaseStation
        baseStationList = [];

        % list of all users in the simulation
        % [1 x nUE]handleObject networkElements.ue.User
        userList = [];

        % list of all streets in the simulation
        % [1 x nStreets]handleObject blockages.StreetSystem
        streetSystemList = [];

        % antenna-basestation-mapper
        % [1x1]handleObject tools.AntennaBsMapper
        % This maps ech base station to its attached antennas and vice
        % versa.
        antennaBsMapper

        % ini factors
        % [1x1]handleObject linkQualityModel.IniCache
        iniFactors
    end

    methods
        function obj = SimulationSetup(Params)
            % SimulationSetup's constructor
            %
            % input:
            %   parameters: [1x1]handleObject parameters.Parameters

            % set parameters
            obj.params = Params;
        end

        function checkCompatibility(obj)
            % check if parameters fit the generated network elements
            % Everything that can't be checked before the objects are
            % generated, should be checked here.
            %
            % see also parameters.Parameters.checkParameters,
            % simulation.LocalSimulation, simulation.ParallelSimulation

            % check if transmit mode and number of transmit antennas are compatible
            % This needs to be checked after network element generation,
            % because clustered users can add femto base station to the
            % baseStationParameters.

            % get all base station parameters
            bsKeys = obj.params.baseStationParameters.keys;
            nBSGroups = length(bsKeys);

            for bb = 1:nBSGroups
                % get parameters for this base station type
                bsParameters =  obj.params.baseStationParameters(bsKeys{bb});
                createdBs = obj.baseStationList(bsParameters.indices);
                isValid = bsParameters.precoder.DL.checkConfig(obj.params.transmissionParameters.DL, createdBs);

                if ~isValid
                    msg = 'The number of transmit antennas/precoder/txMode combination set might be invalid.';
                    warning('warn:invalidSetting', msg);
                end
            end

            % check number of nTXelemnts for analog precoder
            %NOTE: these config checks are done here because nTXelements is
            %a dependent parameter that is only set after the antenna
            %object is created
            precoders.analog.AnalogPrecoderSuperclass.checkConfigStatic(obj.baseStationList);

            % check antenna heights
            if obj.params.regionOfInterest.zSpan == 0
                antennas = [obj.baseStationList.antennaList];
                pos = [antennas.positionList];
                if any(pos(3,:,:) ~= 0)
                    warn = 'Some NEs are placed higher than the height of the ROI. This might not produce the expected results.';
                    warning('warn:ROIsize', warn);
                end
            end % if the ROI has no height
        end

        function prepareSimulation(obj)
            % prepareSimulation is the function that handles the logic of SimulationSetup
            % This function prepares the simulation by creating the network
            % and initialising the traces.
            %
            % see also networkElements.ue.User.generateGaussCluster,
            % networkElements.ue.User.generateUniformCluster

            % create the actual elements from the parameters passed by the user
            %NOTE: the order of element creation should not be changed
            %because the different elements can be dependent of the
            %previous ones
            obj.createCitiesAndBuildings();
            obj.createWallBlockages();
            obj.createUsers();
            obj.createBaseStations();

            %check for channel models assigned to users
            channelModels = unique(cat(2, obj.userList.channelModel));

            if ~any(channelModels == 'Quadriga') %if no user is assigned the Quadriga Channel Model
                % initialize small scale fading traces
                obj.createSmallScaleTraces;
            end

            % create inter-numerology factors
            obj.calculateInternumerologyFactors();

            % create ChunkConfigList
            obj.chunkConfigList = obj.getChunkConfigs;
        end

        function chunkConfigList = getChunkConfigs(obj)
            % getChunkConfigs returns the ChunkConfig for each chunk
            % This function returns the ChunkConfigs after
            % prepareSimulation has been run.
            %
            % output:
            %   chunkConfigList:    [1 x nChunks]handleObject simulation.ChunkConfig

            % initialise chunkConfigList
            chunkConfigList(obj.params.time.numberOfChunks) = simulation.ChunkConfig;

            % intialize arrays of network elements with reduced parameter sets
            reducedBaseStationList(length(obj.baseStationList)) = networkElements.bs.BaseStation;
            reducedUserList(length(obj.userList)) = networkElements.ue.User;

            % fill in chunk config
            for iChunk = 1:obj.params.time.numberOfChunks

                % set parameters that are constant for the whole simulation
                chunkConfigList(iChunk).params              = obj.params;
                chunkConfigList(iChunk).buildingList        = obj.buildingList;
                chunkConfigList(iChunk).wallBlockageList    = obj.wallBlockageList;
                chunkConfigList(iChunk).streetSystemList	= obj.streetSystemList;
                chunkConfigList(iChunk).antennaBsMapper     = obj.antennaBsMapper;
                chunkConfigList(iChunk).iniFactors          = obj.iniFactors;

                % set number of wraparound regions
                if chunkConfigList(iChunk).params.regionOfInterest.interference == parameters.setting.Interference.wraparound
                    nWrap = 9;
                else
                    nWrap = 1;
                end

                % get time mask indicating the current chunk
                tmp = zeros(obj.params.time.numberOfChunks, 1);
                tmp(iChunk) = 1;
                timeMask = logical(kron(tmp, ones(obj.params.time.slotsPerChunk,1)));
                % remove network element positions not relevant for this chunk
                for iBS = 1:length(reducedBaseStationList)
                    reducedBaseStationList(iBS) = obj.baseStationList(iBS).copy();
                    for aa = 1:size(obj.baseStationList(iBS).antennaList,2)
                        reducedBaseStationList(iBS).antennaList(aa).positionList = reshape(obj.baseStationList(iBS).antennaList(aa).positionList( repmat(timeMask.', 3,1,nWrap) == 1), 3, obj.params.time.slotsPerChunk, nWrap);
                    end
                end
                chunkConfigList(iChunk).baseStationList = reducedBaseStationList;

                for iUser = 1:length(obj.userList)
                    reducedUserList(iUser) = obj.userList(iUser).copy();
                    reducedUserList(iUser).positionList = reshape(obj.userList(iUser).positionList( repmat(timeMask.', 3,1) == 1), 3, []);
                    reducedUserList(iUser).isInROI = obj.userList(iUser).isInROI(timeMask.');
                end
                chunkConfigList(iChunk).userList = reducedUserList;
            end % for all chunks
        end

        function createSmallScaleTraces(obj)
            % creates and saves all needed traces so they do not have to be regnerated in the chunks
            % This function makes sure all traces are saved in the traces
            % folder and that they do not have to be recomputed in the
            % individual chunks. It also sets the regenerate flag to false,
            % because they do not need to be regenerated, unless the file
            % is unavailable in the ChunkSimulation.

            % creates and saves the downlink channel traces
            PdpContainer = smallScaleFading.PDPcontainer;
            PdpContainer.setPDPcontainer(obj.params, obj.params.transmissionParameters.DL.resourceGrid);
            PdpContainer.generateTraces([obj.baseStationList.antennaList], obj.userList);

            % reset recalculating flag
            obj.params.smallScaleParameters.regenerateChannelTrace = false;
        end

        function calculateInternumerologyFactors(obj)
            % calculate inter-numerology factors
            % these are used by the LQM during the simulation
            %
            % initial author: Alexander Bokor (INI)

            % obtain all numerologies
            numerologies = sort(unique([obj.userList.numerology]));
            resourceGrid = obj.params.transmissionParameters.DL.resourceGrid;
            oversampling = obj.params.iniOversampling;

            obj.iniFactors = linkQualityModel.ini.IniCache(resourceGrid, numerologies, oversampling);
        end
    end

    methods (Access = protected)
        function createCitiesAndBuildings(obj)
            % creates cities and buildings
            % This function creates building objects according to the
            % parameters in parameters.Parameters.cityParameters and
            % parameters.Parameters.buildingParameters for the simulation.
            %NOTE: cities consist of buildings and streets, to get a
            %consistent inexing of the buildings in the general building
            %list, cities and buildings have to be created together.
            %Additional streets would also have to be created here.
            %
            % initial author: Lukas Nagel
            %
            % see also parameters.Parameters.cityParameters,
            % parameters.Parameters.buildingParameters

            %% create cities

            % get city parameters
            cityKeys = obj.params.cityParameters.keys;
            nCityGroups = length(cityKeys);

            % initialize index
            buildingsIndex = 0;

            for cc = 1:nCityGroups
                cityParameter =  obj.params.cityParameters(cityKeys{cc});

                % create new city
                newCity = cityParameter.createCityFunction(cityParameter, obj.params);

                newBuildings = newCity.buildings;
                newStreetSystem = newCity.streetSystem;

                % add street system
                obj.streetSystemList = [obj.streetSystemList, newStreetSystem]; % not yet saved to which parameter the streets belong
                obj.params.streetNameToIndexMapping(cityKeys{cc}) = cc; % this needs to change if there are other ways to add streets

                % add buildings of this city
                firstIndex = buildingsIndex + 1;
                for ii = 1:length(newBuildings)
                    buildingsIndex = buildingsIndex + 1;
                    obj.buildingList = [obj.buildingList, newBuildings(ii)];
                end
                lastIndex = buildingsIndex;

                % update the params with indices
                cityParameter.setIndices(firstIndex, lastIndex);
                obj.params.cityParameters(cityKeys{cc}) = cityParameter;
            end % for all types of cities

            %% create buildings
            % get building parameters
            buildingKeys = obj.params.buildingParameters.keys;
            nBuildingGroups = length(buildingKeys);

            for bb = 1:nBuildingGroups
                buildingPlacementParameter = obj.params.buildingParameters(buildingKeys{bb});
                newBuildings = buildingPlacementParameter.createBuildingsFunction(buildingPlacementParameter, obj.params);

                % note that this is the same index as used above to create
                % the cities! (you can create a city and add buildings)
                firstIndex = buildingsIndex + 1;
                for ii = 1:length(newBuildings)
                    buildingsIndex = buildingsIndex + 1;
                    obj.buildingList = [obj.buildingList, newBuildings(ii)];
                end
                lastIndex = buildingsIndex;

                % update the params with indices
                buildingPlacementParameter.setIndices(firstIndex, lastIndex);
                obj.params.buildingParameters(buildingKeys{bb}) = buildingPlacementParameter;
            end % for all building types
        end

        function createWallBlockages(obj)
            % creates walls with the parameters in parameters.Parameters.wallParameters
            % This function creates the wall objects according to the
            % properties set in parameters.Parameters.wallParameters for
            % the simulation
            %
            % initial auhtor: Lukas Nagel
            %
            % see also parameters.Parameters.wallParameters

            % get wall parameters
            wallKeys = obj.params.wallParameters.keys;
            nWallGroups = length(wallKeys);

            % initialize indexing
            wallIndex = 0;

            % create walls
            for ww = 1:nWallGroups

                % get parameters
                wallPlacementParameter = obj.params.wallParameters(wallKeys{ww});

                % this automatically uses the function predifined in the
                % wallParams class to generate the desired wall type
                newWalls = wallPlacementParameter.createWallFunction(wallPlacementParameter, obj.params);

                % add walls to wall list and set wall indexing
                firstIndex = wallIndex + 1;
                for ii = 1:length(newWalls)
                    wallIndex = wallIndex + 1;
                    obj.wallBlockageList = [obj.wallBlockageList, newWalls(ii)];
                end
                lastIndex = wallIndex;

                % update the params with indices
                wallPlacementParameter.setIndices(firstIndex, lastIndex);
                obj.params.wallParameters(wallKeys{ww}) = wallPlacementParameter;
            end % for all types of walls
        end

        function createUsers(obj)
            % createUsers creates users with the parameters in parameters.Parameters.userParameters
            % This function creates the user objects according to the
            % properties set in parameters.Parameters.userParameters.
            %
            % initial author: Lukas Nagel
            %
            % see also parameters.Parameters.userParameters

            % get the different types of users to create
            userKeys = obj.params.userParameters.keys;
            nUserGroups = length(userKeys);

            % intialize index count
            userIndex = 0;
            globalID = 1;

            % create user objects
            for uu = 1:nUserGroups
                userPlacementParameter = obj.params.userParameters(userKeys{uu});

                % this automatically uses the function predifined in the
                % userParams class to generate the desired user type
                newUsers = userPlacementParameter.createUsersFunction(userPlacementParameter, obj.params, obj);

                networkElements.ue.User.setMovement(newUsers, userPlacementParameter, obj.params);

                for iUser = 1:length(newUsers)
                    newUsers(iUser).setGenericParameters(userPlacementParameter, obj.params);
                end

                % get and set user indices for this user type
                firstIndex = userIndex + 1;
                for ii = 1:length(newUsers)
                    userIndex = userIndex + 1;
                    newUsers(ii).id = globalID;
                    globalID = globalID + 1;
                end
                lastIndex = userIndex;

                userPlacementParameter.setIndices(firstIndex, lastIndex);
                obj.params.userParameters(userKeys{uu}) = userPlacementParameter; %update the params with indices

                % add users to user list
                obj.userList = [obj.userList, newUsers];

            end % for all different user types
        end

        function createBaseStations(obj)
            %CREATEBASESTATIONS Creates base stations with the parameters
            %in parameters.Parameters.Parameters
            % The base stations will also create their attached antennas
            % and the used precoders.
            %
            % see also parameters.Parameters.Parameters

            % get all base station parameters
            bsKeys = obj.params.baseStationParameters.keys;
            nBSGroups = length(bsKeys);

            bsIndex = 0;

            for bb = 1:nBSGroups
                % get parameters for this base station type
                bsPlacementparameter =  obj.params.baseStationParameters(bsKeys{bb});

                % create new base stations with their antennas
                newBS = bsPlacementparameter.createBaseStations(obj.params, obj.buildingList);

                % add base stations to baseStationList and set their indices
                firstIndex = bsIndex + 1;
                for ii = 1:length(newBS)
                    bsIndex = bsIndex + 1;
                    obj.baseStationList = [obj.baseStationList, newBS(ii)];
                end
                lastIndex = bsIndex;
                bsPlacementparameter.setIndices(firstIndex, lastIndex);

                % save indices of this type of base stations at the base station parameters
                obj.params.baseStationParameters(bsKeys{bb}) = bsPlacementparameter;

            end % for all different types of base stations

            % check if at least one base station has been created
            if isempty(obj.baseStationList)
                error('SIMULATIONSETUP:noBS','No BS was generated, please check your scenario!!');
            end

            % set antennaBsMapper and antenna ids
            obj.antennaBsMapper = tools.AntennaBsMapper(obj.baseStationList);
            for iBS = 1:length(obj.baseStationList)
                ids = obj.antennaBsMapper.getGlobalAntennaIndices(iBS);
                for iAntenna = 1:length(obj.baseStationList(iBS).antennaList)
                    obj.baseStationList(iBS).antennaList(iAntenna).id = ids(iAntenna);
                end % for all antennas at this base station
            end % for all base stations
        end
    end
end

