classdef PathLossManagement < tools.HiddenHandle
    %PathLossManagement is a mangement class for all the macroscopic path loss
    % modells. It allows an easy way of instancing pathloss modells and
    % using them in the simulation.
    %
    % initial author: Christoph Buchner

    properties
        %% parameters
        % PathLossModels
        % [1 x nPathLossModels] is a list for all the Pathlossmodels in use
        pathLossModels = macroscopicPathlossModel.FreeSpace(2)

        % pathLossParams
        % [nBStypes x nIndoor x nLOS] : cell array class
        % parameters.pathlossParameters.Parameters
        % specifying additional modelling
        % parameters for the given pathlossTypes
        pathLossParams

        % userParameters
        % [nUserGroups] cell   handle obj.chunkConfig.params.userParameters.values
        % is used to determine the user configured LOS decision
        userParameters = {}

        % walls
        % [1 x nWalls] handle of blockages.WallBlockages
        % list of all different walls in the scenario, each may be a member
        % of a building or not. Used to determin the line of sight
        % condition in the function
        % macroscopicPathlossModel.PathLossManagement.createBlockageMapUserAntennas
        walls

        % blockages
        % [1 x nBlockages] handle of blockages.Blockages
        % list of all different blockages in the scenario, each may be a
        % simple wall or a complex building. Used to speed up computation
        % of the line of sight condition of each link.
        % See also: macroscopicPathlossModel.PathLossManagement.createBlockageMapUserAntennas
        blockages

        % buildingList
        % [1 x nBuildings] handle of blockages.Building
        % list of all buildings in the scenario. Used to computate if a
        % user is indoors or outdoors if the geometry option is choosen in
        % indoorDecision.
        % See also: macroscopicPathlossModel.PathLossManagement.computeUsersToBuildingsAssignment
        buildingList

        % blockage map - indicates wall blockages for all links in all segments
        % [nAntennas x nUsers x nWalls x nSegment]logical table indicating links blocked by walls
        % This table indicates for each UE-antenna link if it is blocked by
        % a wall for each wall.
        %NOTE: The third dimension over all walls is saved to calculate the
        %wall loss for each link in case of geometry based LOS-decision.
        blockageMapUserAntennas

        % [nUsers*nAntennas*nSegments x 1]: maps the link to a model id,
        % where the link is a dedicated connection between each antenna and
        % user evaluated at the beginn of each segment. The model id can be
        % used to find the correct pathlossmodel in obj.pathLossModels.
        link2ModelId

        % [1 x nAntennas]handle networkElements.bs.Antenna allow access to
        % antenna specific information
        antennas

        % [1 x nUsers]handle networkElements.ue.User allows access
        % to user information
        users

        % [1 x nSlots]logical indicates the start of a segment
        isNewSegment

        % [nUser x nAnt x nSegment]double 3D distance between each user
        % and antenna in meters
        distance3D

        % [nUser x nAnt x nSegment]double 2D distance between each user
        % and antenna in meters
        distance2D

        % [nLinks x 1] double center frequency of the down link path
        % configured for each antenna in GHz
        frequencyDL

        % [nLinks x 1] double absolute antenna height in meters
        antHeight

        % [nLinks x 1] double absolute user height in meters
        ueHeight

        %% Element Counters

        % [1x1]double number of buildings in the current simulation
        nBuilding

        % [1x1]double number of walls in each blockage
        nWallsPerBuild

        % [1x1]double number of different pathloss models types
        nPathLossModels

        % [1x1]double number of different base station types
        nBSTypes

        % [1x1]double number of different indoor types
        nIndoorTypes

        % [1x1]double number of different line of sight types
        nLosTypes

        % [1x1]double number of users
        nUsers

        % [1x1]double number of antennas
        nAntennas

        % [1x1]double number of segments
        nSegments

        % [1x1]double number of slots
        nSlots

        % [1x1]double number of links,
        % where nLinks =  nSegments * nAntennas * nUsers
        nLinks

        % indicates if users are indoor or outdoor
        % [nUsers x nSlots]logical indicator for indoor users
        % This matrix indicates for each user in each slot if the user is
        % indoor or outdoor. This information is then used to choose a
        % proper pathloss model.
        isIndoor

        % indicates if users are under los or nlos link conditions
        % [nUsers x nAntennas x nSegments]logical indicator for los users to
        % antenna links. This information is used to choose a
        % proper pathloss model.
        isLos
    end

    methods
        function obj = PathLossManagement(pathlossModelContainer, params, buildingList, wallBlockageList)
            % set path loss map for all possible links
            % This is used for cell association and in the link quality
            % model.
            %
            % input:
            %   pathlossModelContainer:     [1x1]handleObject parameters.PathlossModelContainer
            %   params:                     [1x1]handleObject parameters.Parameters
            %   buildingList:               [1x nBuildings]handleObject blockages.Building
            %   wallBlockageList:           [1x nWalls]handleObject blockages.wallBlockages

            obj.nBSTypes = parameters.setting.BaseStationType.getLength;
            obj.nIndoorTypes = parameters.setting.Indoor.getLength;
            obj.nLosTypes = parameters.setting.Los.getLength;
            obj.nBuilding                   = size(buildingList,2);

            obj.pathLossParams              = pathlossModelContainer.modelMap;

            obj.userParameters              = params.userParameters.values;
            obj.nPathLossModels             = numel(obj.pathLossParams);

            % save environment for determination of link conditions
            %create list of walls (buildings and wallblockages)
            blockages       = [];
            walls           = [];
            nWallsPerBuild  = [];

            if ~isempty(buildingList)
                blockages = buildingList;
                walls = [blockages.wallList];
                nWallsPerBuild =[blockages.nWall];
            end
            if ~isempty(wallBlockageList)
                obj.blockages = [blockages,wallBlockageList];
                walls = [walls, wallBlockageList];
                nWallsPerBuild =[nWallsPerBuild,ones(1,size(wallBlockageList,2))];
            end

            obj.walls           = walls;
            obj.blockages       = blockages;
            obj.nWallsPerBuild  = nWallsPerBuild;
            obj.buildingList    = buildingList;

            % initialize models
            obj.pathLossModels(obj.nPathLossModels) = macroscopicPathlossModel.FreeSpace(2);

            for iModel  = 1:obj.nPathLossModels
                obj.pathLossModels(iModel) = obj.pathLossParams{iModel}.createPathLossModel;
            end
        end

        function pathLossTableDL = getPathloss(obj, antennas, users, isNewSegment)
            % set path loss map for all possible links
            %
            % input:
            %   antennas:           [1 x nAnt]handle networkElements.bs.Antenna
            %   users:              [1 x nUsers]handle networkElements.ue.User
            %   isNewSegment:       [1 x nSlots]logical indicates the start of a segment
            %
            % output:
            %   pathLossTableDL:    [nAntennas x nUsers x nSegment]double path loss in dB

            obj.nUsers          = size(users, 2);
            obj.nAntennas       = size(antennas,2);
            obj.nSegments       = sum(isNewSegment);
            obj.nSlots          = size(isNewSegment,2);

            obj.nLinks          = obj.nAntennas * obj.nSegments * obj.nUsers;
            obj.antennas        = antennas;
            obj.users           = users;
            obj.isNewSegment    = isNewSegment;

            antennaIndex        = repelem(1:obj.nAntennas, obj.nUsers * obj.nSegments);
            userIndex           = repmat(1:obj.nUsers, [obj.nSegments, 1, obj.nAntennas]);
            userIndex           = userIndex(:).';
            segmentIndex        = repmat(1:obj.nSegments, [1, obj.nUsers* obj.nAntennas]);

            % [distance3D, distance3D] = [nLinks x 2]
            [obj.distance3D, obj.distance2D] = obj.getDistances(users, antennas, isNewSegment);

            % antCCFreq = [nAntennas x 1]
            antCCFreq           = cat(1,antennas(1:obj.nAntennas).usedCCs);
            antCCFreqDL         = [antCCFreq(:,1).centerFrequencyGHz];

            obj.frequencyDL     = antCCFreqDL(antennaIndex);

            % wrapIndicatorList [nAnt x nSeg x nUsers]wrap
            if obj.nAntennas == 1
                %NOTE: for a single base station, the wrapIndicator
                %somewhere gets transposed
                for iUser = 1:obj.nUsers
                    users(iUser).wrapIndicator = users(iUser).wrapIndicator';
                end
            end
            wrapInd = cat(3,users(1:obj.nUsers).wrapIndicator);
            wrapInd = wrapInd(sub2ind(size(wrapInd),antennaIndex,segmentIndex,userIndex));
            wrapInd = wrapInd(:)';
            % AntPos = [3 x nSlot x nWraps x nAntennas]
            antPos          = cat(4,antennas(1:obj.nAntennas).positionList);
            antennaHeight   = antPos(3,isNewSegment,:,:);
            nWraps          = size(antPos,3);
            antennaHeight   = reshape(antennaHeight,[obj.nSegments, nWraps, obj.nAntennas]);
            antennaHeight   = antennaHeight(sub2ind(size(antennaHeight),segmentIndex, wrapInd, antennaIndex));
            obj.antHeight   = antennaHeight(:)';

            % uePos = [3 x nSlot x nWraps x nUser]
            uePos           = cat(4,users(1:obj.nUsers).positionList);
            userHeight      = uePos(3,isNewSegment,1,:);
            userHeight      = reshape(userHeight,[obj.nSegments,obj.nUsers]);
            userHeight      = userHeight(sub2ind(size(userHeight),segmentIndex,userIndex));
            obj.ueHeight    = userHeight(:)';

            % determine Link conditions and select correct model id based on it

            bsTypeList          = uint32([antennas.baseStationType]);

            obj.isIndoor        = obj.setIsIndoor() + 1;
            indoorList          = obj.isIndoor(:, obj.isNewSegment);

            obj.createBlockageMapUserAntennas();

            obj.isLos           = obj.setIsLOS() + 1;
            obj.link2ModelId    = obj.getModelId(bsTypeList, indoorList, obj.isLos);

            % call pathloss Models
            pathLossTableDL     = obj.getSubPathloss();
        end

        function [distance3D, distance2D] = getDistances(obj, users, antennas, isNewSegment)
            % calculates the 3D and 2D distances between all users and all antennas
            %
            % output:
            %   distance3D:     [nUser x nAnt x nSegment]double 3D distance between each user and antenna in meters
            %   distance2D:     [nUser x nAnt x nSegment]double 2D XY-distance between each user and antenna in meters

            % get number of wrapping regions - 1 for no wraparound
            nWrap    = size(antennas(1).positionList, 3);

            % uePos = [3 x nSlot x 1 x nUser]
            uePos    = cat(4,users(1:obj.nUsers).positionList);
            uePos    = uePos(:,isNewSegment,:,:);
            uePos    = repmat(uePos,[1,1,nWrap,1,obj.nAntennas]);
            uePos    = permute(uePos,[1,3,4,5,2]);

            % antPos = [3 x nSlot x nWrapps x nAntennas]
            antPos   = cat(4,antennas(1:obj.nAntennas).positionList);
            antPos   = antPos(:,isNewSegment,:,:);
            antPos   = repmat(antPos,[1,1,1,1,obj.nUsers]);
            antPos   = permute(antPos,[1,3,5,4,2]);

            % antPos = [3 x  nWrapps x nUser x nAntennas x nSegments]
            % uePos  = [3 x  nWrapps x nUser x nAntennas x nSegments]

            distVec  = uePos - antPos;
            dist3D   = vecnorm(distVec,2,1);
            [distance3D, wrapIndicator] = min(dist3D,[],2);

            % create a logical map
            wrapMap = ((1:nWrap) == wrapIndicator);
            % filter te correct 2D distance based on the map
            dist2D   = vecnorm(distVec(1:2,:,:,:,:),2,1);
            distance2D = dist2D(wrapMap);

            wrapIndicator = reshape(wrapIndicator,[obj.nUsers,obj.nAntennas, obj.nSegments]);
            distance3D = reshape(distance3D,[obj.nUsers,obj.nAntennas, obj.nSegments]);
            distance2D = reshape(distance2D,[obj.nUsers,obj.nAntennas, obj.nSegments]);

            for iUser = 1:obj.nUsers
                users(iUser).wrapIndicator = shiftdim(wrapIndicator(iUser,:,:));
            end
        end

        function isLos = setIsLOS(obj)
            % sets isLos, the los/nLos indicator based on the parameter
            % losDecision. Depending on the user decision several sources
            % for this decision are valid.
            % See also: parameters.losDecision.Contents
            %
            % output:
            %   isLos:      [nUsers, nAntennas, nSegments]logical indicator, ture if a link is under los.

            % get the user parameters
            isLos = zeros(obj.nUsers, obj.nAntennas, obj.nSegments);
            for UserParam = obj.userParameters
                actUserParams = UserParam{:};
                % get the indices of the users with this userParameters
                userIndices = actUserParams.indices;
                nUserIndices = size(userIndices,2);

                uePos               = cat(4,obj.users(userIndices).positionList);
                actUserHeight      = uePos(3,obj.isNewSegment,1,:);
                actUserHeight      = permute(actUserHeight,[4,5,3,1,2]);
                actUserHeight      = repmat(actUserHeight,[1,obj.nAntennas,1]);
                actUserHeight      = actUserHeight(:)';

                actUserAntDistance2D      = obj.distance2D(userIndices,:,:);
                actUserAntDistance2D      = actUserAntDistance2D(:)';

                nModelLinks = size(userIndices,2) * obj.nAntennas * obj.nSegments;

                isLOSTmp = actUserParams.losDecision.getLOS(nModelLinks, nUserIndices, obj.nAntennas, obj.nSegments, obj.blockageMapUserAntennas(:,userIndices,:,:), actUserAntDistance2D, actUserHeight);

                % set temporary results
                isLos(userIndices,:,:) = isLOSTmp;
            end
        end

        function isIndoor = setIsIndoor(obj)
            % sets isIndoor, the indoor/outdoor indicator
            %
            % based ont the indoorDecision Object
            % output:
            %   isIndoor:      [nUsers x nSegments]logical indicator, true if a user is indoors
            %
            % see also: indoorDecision.Static, indoorDecision.Random,
            % indoorDecision.Geometry

            isIndoor = zeros(obj.nUsers, obj.nSlots);
            for UserParam = obj.userParameters
                actUserParams = UserParam{:};

                % get the indices of the users with this userParameters
                userIndices = actUserParams.indices;

                switch class(actUserParams.indoorDecision)
                    case 'parameters.indoorDecision.Geometry'
                        % geometry based indoor/outdoor-decision

                        % get the user placement table for all geometry
                        % users and all buildings for all slots
                        if obj.nBuilding > 0
                            % if there are buildings set indoor/outdoor
                            % indicator, if there are no buildings the
                            % default false setting does not need to be
                            % changed

                            % preallocate userPlacementTable
                            userPlacementTable = false(obj.nBuilding, length(userIndices), obj.nSlots);

                            for ss = 1:obj.nSlots
                                % set user placement table
                                if obj.isNewSegment(ss)
                                    % set table with which building each user is in in each slot
                                    userPlacementTable(:, :, ss) = obj.computeUsersToBuildingsAssignment(obj.users(userIndices), ss);
                                else % if this is not a new segment, the settings from the previous slot can be used
                                    userPlacementTable(:, :, ss) = userPlacementTable(:, :, ss-1);
                                end % if this a new segment

                            end % for all slots

                            % set isIndoor matrix for all slots
                            isIndoorTmp = squeeze(sum(userPlacementTable, 1) > 0);
                        else
                            isIndoorTmp = false;
                        end

                    case 'parameters.indoorDecision.Static'
                        % static indoor/outdoor decision

                        % set isIndoor matrix for all slots
                        isIndoorTmp = actUserParams.indoorDecision.isIndoor;

                    case 'parameters.indoorDecision.Random'
                        % random indoor/outdoor-decision

                        % get random indoor/outdoor-decision according to probability
                        indoorFirst = rand(length(userIndices), 1) > (1 - actUserParams.indoorDecision.indoorProbability);

                        % set isIndoor matrix
                        isIndoorTmp = repmat(indoorFirst, 1, obj.nSlots);

                    otherwise
                        error('unknown indoorDecision type -- this should not happen...');
                end

                isIndoor(userIndices, :) = isIndoorTmp;
            end
        end
    end

    methods(Hidden = true)
        function modelID = getModelId(obj, bsTypeList, indoorList, losType)
            % This function associates the correct pathloss model for each type of link
            %
            %
            % input:
            %   bsTypeList:         [1 x nAnt]integer indecator for the type of
            %                       BaseStation.
            %                       (1) macro (2) femto (3) pico
            %   losType:            [nUser x nAntennas x nSegments] integer
            %                       Indicates if there is a link line of sight
            %                       between antenna and user
            %                       (1) non line of sight (2) line of sight
            %   indoorList:         [nUsers x nSegments]integer
            %                       Indicates if user is inside or outside of a
            %                       building.
            %                       (1) outdoor (2) indoor
            % output:
            %   modelID:            [nUsers*nAntennas*nSegments x 1]: Id
            %                       for scenario in use

            % replicate input data to allow vectorised comparison
            indoorList  = permute(indoorList,[1,3,2]);
            indoorList  = repmat(indoorList, [1,obj.nAntennas,1]);
            bsTypeList  = repmat(bsTypeList, [obj.nUsers,1,obj.nSegments]);
            allModelIds = [bsTypeList(:),indoorList(:),losType(:)];

            % find the unique configurations and return them
            [valModel, ~, indModel] = unique(allModelIds,'rows');
            modelID = sub2ind([obj.nBSTypes, obj.nIndoorTypes, obj.nLosTypes], valModel(:,1),valModel(:,2),valModel(:,3));
            modelID = modelID(indModel);
        end

        function pathLoss = getSubPathloss(obj)
            % Forwards the calculation parameter for each pathlossmodel.
            % The input data is filtered based on the current relevant
            % model and the result is saved into the pathloss.
            %
            % output:
            %   pathLoss:       [nAntennas x nUsers x nSegment]double path loss table in dB
            %
            % see also:
            % macroscopicPathlossModel.PathlossManagement.getPathloss

            % initalize path loss array
            pathLoss        = zeros(1, obj.nLinks);

            % calculate path loss values for each model
            for iModel = 1:obj.nPathLossModels

                % get indices of all links that use the current model
                dataIds = obj.link2ModelId == iModel;

                if sum(dataIds) == 0
                    % skip path loss calculation for this path loss model
                    % if no link uses this model
                    continue;
                end

                % calculate path loss for the links with the current model
                pathLoss(dataIds) = obj.pathLossModels(iModel).getPathloss(...
                    obj.frequencyDL(dataIds), obj.distance2D(dataIds)', ...
                    obj.distance3D(dataIds)', obj.ueHeight(dataIds), obj.antHeight(dataIds));
            end

            % reshape into path loss table
            pathLoss = reshape(pathLoss, [obj.nUsers, obj.nAntennas, obj.nSegments]);
            pathLoss = permute(pathLoss, [2,1,3]);
        end

        % LOS functions
        function createBlockageMapUserAntennas(obj)
            % creates the blockageMapUserAntennas and sets the property
            %
            % set properties: blockageMapUserAntennas

            % preallocate blockage map
            if isempty(obj.nWallsPerBuild)
                nWalls = 0;
            else
                nWalls = sum(obj.nWallsPerBuild);
            end

            obj.blockageMapUserAntennas = false(obj.nAntennas, obj.nUsers, nWalls, obj.nSegments);

            if ~isempty(obj.blockages)
                iSoltSeg = find(obj.isNewSegment);
                for iSegment = 1: obj.nSegments
                    iSlot = iSoltSeg(iSegment);
                    obj.blockageMapUserAntennas(:, :, :, iSegment) = obj.checkLOSUserAndBaseStation(iSlot);
                end % for all slots that are the first in a segment
            end % if there are buildings or walls
        end

        function blockageMap = checkLOSUserAndBaseStation(obj, iSlot)
            % returns a map that indicates if a wall is in the LOS connection of a user and a antenna
            %
            % input:
            %   iSlot:  [1x1]integer index of current slot, for which blockage map is calculated
            %
            % output:
            %   blockageMap:    [nUsers x nAntennas x nWalls]logical map indicating for all
            %                   links and walls if a wall blocks the LOS connection
            %
            %NOTE: we do not wrap the blockages instead we use the LOS/NLOS
            %information of the center region and apply it to the links

            % get positions of users and antennas in an array
            uePos       = zeros(3, obj.nUsers);
            antennaPos  = zeros(3, obj.nAntennas);

            for iUE = 1:obj.nUsers
                uePos(:,iUE) = obj.users(iUE).positionList(:,iSlot);
            end

            for iAnt = 1:obj.nAntennas
                antennaPos(:, iAnt) = obj.antennas(iAnt).positionList(:,iSlot,1);
            end

            % returns blockageMap nUsers x nAntennas x nWalls
            blockageMap = obj.checkBlockagesInLOS(uePos, antennaPos);
        end

        function blockageMap = checkBlockagesInLOS(obj, uePos, antPos)
            % checkBlockagesInLOS checks if there is blockage between two vectors of locations
            % This function returns a blockageMap of dimensions [nVec1 x nVec2 x nWalls]
            %
            % input:
            %   uePos:  [3 x nUser]double vector with 3D positions
            %   antPos: [3 x nAnt]double vector with 3D positions
            %
            % output:
            %   blockageMap:    [nUe x nAnt x nWalls]logical map of blockages
            %
            % initial author: Christoph Buchner

            nAnt	= size(antPos,2);
            nUe     = size(uePos,2);

            % list of all Walls used in the scenario
            localWalls           = obj.walls;
            localBlockages       = obj.blockages;
            % number of walls per building
            nLocalWallsPerBuild  = obj.nWallsPerBuild;

            nBlockages = size(localBlockages,2);
            normDists = [localWalls.normDist];
            normVecs  = [localWalls.normVec ];

            %-------------------------------------------
            % check if both user and antenna are on the same side of the
            % walls, if so there is no blockage possible
            %-------------------------------------------

            % calculate normaldistance between plane and ue/ant
            ueDist = normVecs'*uePos - repmat(normDists',1,nUe);
            antDist = normVecs'*antPos -repmat(normDists',1,nAnt);

            % if sign of ueDist and antDist is the same the LOS is not
            % blocked
            sideIndicator  = permute(repmat(sign(ueDist),1,1,nAnt),[2,3,1]) ~= ...
                permute(repmat(sign(antDist),1,1,nUe),[3,2,1]);

            %-------------------------------------------
            % check which buildings have to be considered
            %-------------------------------------------

            % get the radius and the center position of all buildings
            if ~isempty(localBlockages)
                radiusBuildings=[localBlockages.r];
                buildingPos = [localBlockages.x;localBlockages.y];

                %calculate the line of sight vector pointing from antenna to the user
                ueMat= repmat(uePos,1,1,nAnt);
                losVect = ueMat - permute(repmat(antPos,1,1,nUe),[1,3,2]);
                losVect = reshape(losVect,3,[]);

                %calculate the the 90 deg flipped normalvector by changing x and y  to y and -x
                nLosVect(2,:) = - losVect(1,:);
                nLosVect(1,:) = losVect(2,:);
                nLosVect = nLosVect ./ vecnorm(nLosVect,2,1);
                %duplicate for pairwise computation
                nLosMat = repmat(nLosVect,1,1,nBlockages);

                %create dublicated vectors pointing from each user to each
                %building
                ueMat = repmat(reshape(ueMat(1:2,:,:),2,[]),1,1,nBlockages);
                buildingMat=permute(repmat(buildingPos,1,1,nAnt*nUe),[1,3,2]);
                losBuildingMat= ueMat - buildingMat;
                %normal distance between LOS connection and center of each
                %building
                distance = abs(squeeze(dot(losBuildingMat,nLosMat,1)));
                distance = reshape(distance, nUe*nAnt, []);
                %check if buildingDistance exceeds the radiusBuilding if it
                %does i cant possible obscure the LOS
                buildingIndicator = reshape(distance < repmat(radiusBuildings,nUe*nAnt,1),nUe,nAnt,[]);

                %duplicate entries in the buildingsdimension so that it is
                %equal to the number of walls in the building
                % [nUe x nAnt x nBuild] -> [nUe x nAnt x nWalls(nBuild*wallsPerBuild)]

                buildingIndicator = repelem(buildingIndicator,1,1,nLocalWallsPerBuild);
                %combine both indictor matrices if one of them is true there
                %is a LOS
                indicators	= sideIndicator .* buildingIndicator;
            else
                indicators	= sideIndicator;
            end
            blockageMap	= indicators;
            % find zeros in indicator to determine if there really is a
            % blockage and reformat the returned position to the 3 dimensions

            [iUsers,iAntennas,iWalls] = ind2sub(size(blockageMap),find(blockageMap));
            if ~isempty(iWalls)
                for iiWall = unique(iWalls')
                    index=find(iWalls == iiWall);
                    actUsers    = uePos(:,iUsers(index));
                    actAntennas = antPos(:,iAntennas(index));
                    collisionDecision = localWalls(iiWall).checkBlockage(actUsers,actAntennas);
                    for i = 1:length(index)
                        blockageMap(iUsers(index(i)),iAntennas(index(i)),iiWall)=collisionDecision(i);
                    end
                end
            end
            %blockageMap=~indicators;
            blockageMap = logical(permute(blockageMap,[2,1,3]));
        end

        % Indoor functions
        function userPlacementTable = computeUsersToBuildingsAssignment(obj, geometryUser, iSlot)
            % calculates which user is in what building at a given slot index
            % computeUsersToBuildingsAssignment returns a table indicating
            % in which building the given users are located. This table is
            % then used for the isIndoor decision of these users. The given
            % geometryUser should be users with indoor decision type
            % parameters.indoorDecision.Geometry.
            %
            % input:
            %   geometryUser:   [1 x nGeometryUser]handleObject networkElements.ue.User users with parameters.indoorDecision.Geometry
            %   iSlot:          [1x1]integer index of current slot
            %
            % output:
            %   userPlacementTable: [nBuilding x nGeometryUser]logical table indicating for each user the associated building
            %
            % see also parameters.indoorDecision.Geometry

            nGeometryUser       = length(geometryUser);
            nBuildings          = size(obj.buildingList,2);
            userPlacementTable	= false(obj.nBuilding, nGeometryUser);
            uePos               = zeros(3, nGeometryUser);

            % The following algorithm is based on an fixed height for a
            % building.
            for iUE = 1:nGeometryUser
                uePos(:,iUE) = geometryUser(iUE).positionList(:,iSlot);
            end

            %checkHeight heightIndicator is 1 if  Building is heigher than
            %the userposition
            heightIndicator = repmat([obj.buildingList.height],nGeometryUser,1) > ...
                repmat(uePos(3,:)',1,nBuildings);

            %create a circle around the center of the building with the
            %biggest dimension (width/lenght) as radius
            radiusBuildings=[obj.buildingList.r];

            %checkBoundry for first approximation and to reduce complexity

            %first gather positions in Matrix to compute the pairwise
            %distances
            posBuildings = repmat([obj.buildingList.x;obj.buildingList.y],1,1,nGeometryUser);
            posBuildings = permute(posBuildings,[1,3,2]);
            posUsers     = repmat(uePos(1:2,:),1,1,nBuildings);

            %compute the lenght of the distance
            distance = vecnorm(posUsers - posBuildings,2,1);
            distance = reshape(distance,nGeometryUser,[]);
            %setIndicator
            %distanceIndicator is 1 if user is inside a circle
            %drawn around the center position of the buiulding
            distanceIndicator = squeeze(distance) <= repmat(radiusBuildings,nGeometryUser,1);

            %gather all indicators inside a map
            indicatorMap = distanceIndicator .* heightIndicator;

            %now loop over all elements which are suspected to be inside a building
            [usersInside, buildings] = find(indicatorMap);
            buildings = reshape(buildings,[],1);
            if ~isempty(buildings)
                for iBuilding = unique(buildings)'
                    consideredUsers = usersInside(buildings == iBuilding)';
                    uePosToCheck = uePos(:,consideredUsers);
                    insideDecision = obj.buildingList(iBuilding).checkIsInside(uePosToCheck);
                    userPlacementTable(iBuilding, consideredUsers(insideDecision)) = true;
                end
            end
        end
    end
end

