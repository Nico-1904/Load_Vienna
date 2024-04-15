classdef User < networkElements.NetworkElementWithPosition
    %USER superclass for all user types
    % User is the class that is a receiver in the downlink and a
    % transmitter in the uplink.
    %
    % initial author: Lukas Nagel
    % extended by: Christoph Buchner, added technology parameter
    % extended by: Areen Shiyahin, added traffic model parameter
    % extended by: Jan Nausner, added scheduling weight parameter
    %
    % see also networkElements.NetworkElementWithPosition

    properties
        % user id
        % [1x1]integer identification number for this user
        % This can be used to index the user.
        id

        % number of receive antennas of this user
        % [1x1]integer number of receive antennas
        nRX

        % number of transmit antennas of this user
        % [1x1]integer number of transmit antennas
        nTX

        % channel model
        % [1x1]enum parameters.setting.ChannelModel channel model for this user
        %
        % see also parameters.setting.ChannelModel
        channelModel

        % user speed
        % [1x1]double speed of user for Doppler frequency calculations
        speed

        % transmit mode
        % [1x1]struct with uplink and downlink transmit modes
        %   -DL:    [] downlink transmit mode information
        %   -UL:    [] uplink transmit mode information
        txMode

        % indicates for each antenna which wrap around sector is used
        % [nAnt x nSegments]integer indicates which wrap around sector the antenna is taken from for this user
        % 1 ... 9 where 1 is the central sector
        wrapIndicator

        % scheduler information of this user in this slot
        % [1x1]handleObject scheduler.signaling.UserScheduling
        scheduling

        % number of resources the user gets when scheduled with Round Robin
        % [1x1]integer
        schedulingWeight

        % user feedback for uplink and downlink
        % [1x1]struct with user feedback
        %   -DL:    [1x1]handleObject feedback.Feedback
        userFeedback
    end

    properties (SetAccess = protected)
        % traffic model
        % [1x1]handleObject trafficModels.PacketProcessing
        % The traffic model for this user in the current slot
        % which indicates the data that is need to be generated or
        % transmitted for this user
        %
        % see also parameters.user.Parameters
        % parameters.user.trafficModel.TrafficModel
        trafficModel
    end

    methods
        function copyPrivate(obj,old)
            % copy object
            %
            % input:
            %   old:    [1x1]handleObject networkElements.ue.User

            obj.transmitPower   = old.transmitPower;
            obj.userFeedback.DL = old.userFeedback.DL.clone();
            obj.numerology      = old.numerology;
            obj.trafficModel    = old.trafficModel;
            obj.scheduling      = old.scheduling.copy;
        end

        function handle = plot(obj, timeIndex, color)
            % plot plots the User at a specific time Index in a color
            % either color triplet [r g b] or 'm', 'y' ...
            for elem = obj
                p = elem.positionList(:,timeIndex);
                hold on;
                handle = scatter3(p(1), p(2), p(3), 10, color, 'filled');
                hold off;
            end
        end

        function handle = plot2D(obj, timeIndex, color)
            % plot plots the User at a specific time Index in a color
            % either color triplet [r g b] or 'm', 'y' ...
            for elem = obj
                p = elem.positionList(:,timeIndex);
                hold on;
                handle = scatter(p(1), p(2), 10, color, 'filled');
                hold off;
            end
        end

        function setGenericParameters(obj, userParameters, params)
            % copies user parameters from parameters to user object
            % This function is called for each user in the user generation
            % functions.
            %
            % input:
            %   params:         [1x1]parameters.Parameters
            %   userParameters:	[1x1]parameters.user.Parameters
            %
            % set properties: id, nRX, nTX, speed, transmitPower, isInROI,
            % rxNoiseFiguredB
            %
            % see also simulation.SimulationSetup.createUsers

            % set number of antennas
            obj.nRX	= userParameters.nRX;
            obj.nTX = userParameters.nTX;

            % set possible channel model types
            obj.channelModel = userParameters.channelModel;

            % set user speed
            obj.speed = userParameters.speed;

            % set transmit power
            obj.transmitPower           = userParameters.transmitPower;
            obj.numerology              = userParameters.numerology;

            % set technology parameter
            obj.technology              = userParameters.technology;

            % set transmit mode
            obj.txMode.DL = params.transmissionParameters.DL.txModeIndex;

            % set noise figure
            obj.rxNoiseFiguredB = userParameters.rxNoiseFiguredB;
            obj.setThermalNoisePower(params.transmissionParameters.DL.resourceGrid.sizeRbFreqHz);

            % set traffic model
            obj.trafficModel = obj.setModel(userParameters.trafficModel, userParameters.trafficModelType);

            % set user scheduling information
            obj.scheduling      = scheduler.signaling.UserScheduling();
            obj.schedulingWeight = userParameters.schedulingWeight;

            % set isInROI
            obj.checkRegionOfInterest(params.regionOfInterest);

            % initialize user feedback
            obj.userFeedback.DL = feedback.Feedback.generateFeedback(...
                params.transmissionParameters.DL.feedbackType, params.transmissionParameters.DL.cqiParameters, obj.txMode.DL);
        end

        function model = setModel(~,trafficModelParams, trafficType)
            % choose the traffic model for the user
            %
            % input:
            %   trafficModelParams: [1x1]handleObject parameters.user.trafficModel.TrafficModel
            %   trafficType:        [1x1]enum parameters.setting.TrafficModelType
            %
            % initial author: Areen Shiyahin
            %
            % see also trafficModels.PacketProcessing
            % trafficModels.ConstantRate
            % trafficModels.FullBuffer
            % trafficModels.FTP
            % trafficModels.HTTP
            % trafficModels.VideoStreaming
            % trafficModels.Gaming
            % trafficModels.VoIP

            switch trafficType
                case parameters.setting.TrafficModelType.ConstantRate
                    model = trafficModels.ConstantRate(trafficModelParams);

                case parameters.setting.TrafficModelType.FullBuffer
                    model = trafficModels.FullBuffer();

                case parameters.setting.TrafficModelType.FTP
                    model = trafficModels.FTP();

                case parameters.setting.TrafficModelType.HTTP
                    model = trafficModels.HTTP();

                case parameters.setting.TrafficModelType.Video
                    model = trafficModels.VideoStreaming();

                case parameters.setting.TrafficModelType.Gaming
                    model = trafficModels.Gaming();

                case parameters.setting.TrafficModelType.VoIP
                    model = trafficModels.VoIP();
            end
        end

        function isActive = isActive(obj)
            % check if user has data to transmit
            %
            % output:
            %   isActive: [1x1]logical indicates if user has data to transmit

            % initialize output
            isActive = false;

            % read out user buffer
            [bufferedPackets,~,~] = obj.trafficModel.getBufferState;

            % set isActive if any traffic is in the transmit buffer
            if bufferedPackets
                isActive = true;
            end % if this user has traffic to transmit
        end
    end

    methods (Static)
        %% movement functions
        function setMovementRandConstDirection(users, userParameters, params)
            nUser = length(users);
            direction = 2*pi*(rand(nUser,1)-.5);
            direction = [sin(direction), cos(direction), zeros(nUser,1)];
            speed = userParameters.speed*ones(nUser,1);
            t = reshape(reshape(0:params.time.nSlotsTotal-1,params.time.slotsPerChunk,[])+params.time.timeBetweenChunksInSlots*(0:params.time.numberOfChunks-1),1,1,params.time.nSlotsTotal);
            offset = params.time.slotDuration*repmat(direction .* speed,1,1,params.time.nSlotsTotal) .* repmat(t,nUser,3,1);
            for iUser = 1:nUser
                users(iUser).positionList = users(iUser).positionList(:,1)+squeeze(offset(iUser,:,:));
            end
        end

        function setMovementConstPosition(users, params)
            nUser = length(users);
            for uu = 1:nUser
                % set position
                users(uu).positionList = repmat(users(uu).positionList(:,1), ...
                    1, params.time.nSlotsTotal);
            end
        end

        function setMovementConstSpeedRandomWalk(users, userParameters, params)
            nUser = length(users);
            if isfield(userParameters.userMovement,'correlation')
                c = userParameters.userMovement.correlation;
            else
                c = 0;
            end
            cM = toeplitz([sqrt(1-c^2),zeros(1,params.time.nSlotsTotal-2)],[sqrt(1-c^2),c,zeros(1,params.time.nSlotsTotal-3)]);
            cM(1) = 1;
            direction = 2*pi*(rand(nUser,params.time.nSlotsTotal-1)-.5)*cM;
            speed = userParameters.speed;
            for iUser = 1:nUser
                direction_ = [sin(direction(iUser,:)); cos(direction(iUser,:)); zeros(1,params.time.nSlotsTotal-1)];
                Doffset = direction_*speed*params.time.slotDuration;
                offset = cumsum(Doffset,2);
                users(iUser).positionList(:,2:end) = users(iUser).positionList(:,1)+offset;
            end
        end

        function setMovementPredefinedPosition(Users, userParameters, params)
            % set user movement to predefined positions
            %
            % input:
            %   Users:          [1 x nUser_type]handleObject users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %       -userMovement.positionList:	[3 x nSlotsTotal x nUser]double
            %   params:         [1x1]handleObject parameters.Parameters

            % check if predefined user positions are in the placement region

            % get placement region -  the region in which the users are allowed to move
            placementRegion = params.regionOfInterest.placementRegion;

            % check if user positions are in the placement region
            allPositions = reshape(userParameters.userMovement.positionList, 3, []);
            if any(allPositions(1,:) < placementRegion.xMin) || any(allPositions(1,:) > placementRegion.xMax) ...
                    || any(allPositions(2,:) < placementRegion.yMin) || any(allPositions(2,:) > placementRegion.yMax)
                warning('warn:outsideROI', 'The predefined user positions are outside of the user placement region.');
            end

            % set user positions
            for iUser = 1:length(Users)
                % set user position list to predefined positions
                Users(iUser).positionList = userParameters.userMovement.positionList(:,:,iUser);
            end % for all users
        end

        function keepUserInRegion(users, params)
            % keeps users in the ROI (or interference region - depending on setting)
            % This function mirrors the positions of the users leaving the
            % simulation region.
            %
            % input:
            %   users:  [1 x nUsers]handleObject networkElements.ue.User
            %   params: [1x1]handleObject parameters.Parameters

            % get placement region -  the region in which the users are allowed to move
            placementRegion = params.regionOfInterest.placementRegion;

            % get number of users
            nUser = length(users);

            % set mirror matrix
            u = [0  1  0 -1    % x-coordinate
                1  0  -1 0     % y-coordinate
                0  0  0  0];   % z-coordinate

            % number of borders of the placement region
            nu = size(u,2);

            % get abolute value of the limits of the placement region in a vector
            b = [placementRegion.yMax;
                placementRegion.xMax;
                -placementRegion.yMin;
                -placementRegion.xMin];

            for iUser = 1:nUser
                % get position array of this user
                p = users(iUser).positionList;

                % flag for users whose positions have mirrored
                % The following loop mirrors all positions after the first
                % user position outside of the placement region. This if a
                % position has been mirrored the loop needs to check again
                % if it has set positions to outside the placement region.
                hasMirrored = true;
                while hasMirrored
                    hasMirrored = false;
                    for i = 1:nu
                        % get absloute value of position to compare with placement region limit
                        pp = u(:,i)' * p;
                        % find positions where this user leaves placement region
                        iMirror = find(pp>b(i),1,'first');
                        if ~isempty(iMirror)
                            % mirror positions at the border of the placement region
                            p(:,iMirror:end) = p(:,iMirror:end) + 2 * u(:,i)*(b(i) - pp(iMirror:end));
                            % set hasMirriored to true to check if all
                            % positions are now in the placement region
                            hasMirrored = true;
                        end % if this user has to be brought back from outside the placement region
                    end % for all region limits - 4 sides of a rectangle (xMIn, xMax, yMin, yMax)
                end

                % set mirrored position array for this user
                users(iUser).positionList = p;
            end % for all users
        end

        function setMovement(users, userParameters, params)
            % set positions per slot for all users according to movement model
            %
            % input:
            %   users:          [1 x nUser_type]handleObject array of users with this movement model
            %   userParameters: [1x1]handleObject parameters.user.Parameters
            %   params:         [1x1]handleObject parameters.Parameters

            switch userParameters.userMovement.type
                case parameters.setting.UserMovementType.RandConstDirection
                    networkElements.ue.User.setMovementRandConstDirection(users, userParameters, params);
                    networkElements.ue.User.keepUserInRegion(users, params);

                case parameters.setting.UserMovementType.ConstPosition
                    networkElements.ue.User.setMovementConstPosition(users, params);

                case parameters.setting.UserMovementType.ConstSpeedRandomWalk
                    networkElements.ue.User.setMovementConstSpeedRandomWalk(users, userParameters,params);
                    networkElements.ue.User.keepUserInRegion(users, params);

                case parameters.setting.UserMovementType.Predefined
                    networkElements.ue.User.setMovementPredefinedPosition(users, userParameters, params);

                otherwise
                    warning('No user movment function specified!');
                    networkElements.ue.User.setMovementConstPosition(users,params);
            end % switch for movement model
        end
    end
end

