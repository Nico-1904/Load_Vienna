classdef BestCQIScheduler < scheduler.Scheduler
    %BESTCQISCHEDULER Schedules the users with the highest estimated CQI
    %
    % initial author: Thomas Dittrich
    % extended by: Areen Shiyahin, added traffic models and HARQ

    methods
        function obj = BestCQIScheduler(params, attachedBS, sinrAverager)
            % class constructor
            %
            % input:
            %   params:         [1x1]handleObject parameters.Parameters
            %   attachedBS:     [1x1]handleObject networkElements.bs.BaseStation
            %   sinrAverager:   [1x1]handleObject tools.MiesmAverager

            % call superclass constructor
            obj = obj@scheduler.Scheduler(params, attachedBS, sinrAverager);
        end

        function scheduleDL(obj, currentTime)
            % assign resources to users according to the chosen scheduling strategy
            % This function sets the user allocation in the rbGrid
            % and calls scheduleDLCommon to set all dependent scheduling
            % parameters.
            %
            % input:
            %   currentTime:    [1x1]integer slot index

            % get parameters
            nRBTime = obj.transmissionParameters.DL.resourceGrid.nRBTime;
            nRBFreq = obj.transmissionParameters.DL.resourceGrid.nRBFreq;

            % reset the resource grid for this slot
            obj.rbGrid.DL = obj.rbGrid.DL.reset(obj.attachedBS);

            % get users with data in the buffer
            allActiveUsers = obj.getActiveUsers;

            if ~isempty(allActiveUsers)

                % allocate the same RBs, which were used in the
                % previous slot, for users that need a retransmission
                [allocatedRB, harqUsers] = obj.updateHARQMaskDL(allActiveUsers);

                % initialize the RBs over which no user would be scheduled
                unusedRBs = [];

                % get number of resources left for scheduling
                nResourcesForScheduling = sum(obj.rbGrid.DL.rbGridMask(:));

                if nResourcesForScheduling

                    % get active users that do not need retransmissons
                    activeUsers = setdiff(allActiveUsers, harqUsers);

                    if ~isempty(activeUsers)

                        % get parameters of active users
                        nUserActive = size(activeUsers,2);

                        % create 4-dimensional array of CQIs over frequency, time and codewords for each active user
                        CQIsAttached = zeros(nRBFreq, nRBTime, obj.transmissionParameters.DL.maxNCodewords, nUserActive);

                        % update the 3-dimensional arrays of CQIs based on user feedback
                        for iUser = 1:nUserActive
                            thisUser = activeUsers(iUser);
                            thisFeedback = thisUser.userFeedback.DL.getFeedback(obj.feedbackDelay);
                            if thisFeedback.isValid
                                CQIsAttached(:, :, 1:thisFeedback.rankIndicator, iUser) = thisFeedback.estimatedCQI;
                            end
                        end

                        %NOTE: the next steps are to randomly assign a user
                        %in case several users have the highest CQI
                        % find active users with best CQI
                        CQIsAttached = sum(CQIsAttached,3); % sum over codewords
                        [maxCQI, ~] = max(CQIsAttached, [], 4);

                        % logical array indicates which active users have best CQI
                        maxCandidates = maxCQI(:) == reshape(CQIsAttached, nRBFreq*nRBTime, []);

                        % find indices of active users that have best CQI
                        candidates = zeros(nRBFreq*nRBTime, nUserActive);
                        i = ones(nRBFreq*nRBTime,1);
                        for iUser = 1:nUserActive
                            candidates((1:nRBFreq*nRBTime)+(i'-1)*nRBFreq*nRBTime) = maxCandidates(:,iUser).*iUser;
                            i = i + maxCandidates(:,iUser);
                        end

                        % find total number of active users with best CQI
                        nCandidates = sum(maxCandidates,2);

                        % assign resource blocks for active users
                        iCandidate = floor(nCandidates.*rand(nRBFreq*nRBTime,1))+1;
                        userAllocation = candidates((1:nRBFreq*nRBTime)+(iCandidate'-1)*nRBFreq*nRBTime);
                        obj.rbGrid.DL.userAllocation(obj.rbGrid.DL.rbGridMask) = [activeUsers(userAllocation(obj.rbGrid.DL.rbGridMask)).id];

                    else % users that need retransmissions are the only active users
                        unusedRBs = find(obj.rbGrid.DL.userAllocation ~= -1);
                    end
                end

                % reset RB grid mask after user allocation is done all users
                obj.resetHARQMaskDL(allocatedRB, unusedRBs);
            end % if there are users with traffic to transmit

            % set NOMA scheduling for user and base station
            obj.nomaScheduler.scheduleNOMA(obj.attachedBS, obj.rbGrid.DL);

            % perform all calculations of the scheduler
            obj.scheduleDLCommon(currentTime);
        end

        function updateAttachedUsers(obj, newUserList)
            % updates attachedUsers property with new users
            %
            % input:
            %   newUserList: [1 x nUser]handleObject users to be attached to this scheduler
            %
            % see also attachedUsers

            obj.attachedUsers = newUserList;
        end
    end
end

