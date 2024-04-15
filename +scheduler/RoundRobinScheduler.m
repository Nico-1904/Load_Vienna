classdef RoundRobinScheduler < scheduler.Scheduler
    %ROUNDROBINSCHEDULER Schedules the users in order of attachment
    %
    % initial author: Thomas Dittrich
    % extended by: Areen Shiyahin, added traffic models and HARQ
    %              Jan Nausner, implemented weighted Round Robin

    properties (SetAccess = protected)
        % index of last user scheduled, that does not need retransmission,
        % [1x1]integer position of last non HARQ scheduled user in the queue
        nonHarqLastScheduledDL

        % number of unscheduled resources for last scheduled user in DL
        % [1x1]integer number of unscheduled resources
        unscheduledResourcesDL
    end

    methods
        function obj = RoundRobinScheduler(params, attachedBS, sinrAverager)
            % class constructor
            %
            % input:
            %   params:         [1x1]handleObject parameters.Parameters
            %   attachedBS:     [1x1]handleObject networkElements.bs.BaseStation
            %   sinrAverager:   [1x1]handleObject tools.MiesmAverager

            % call superclass constructor
            obj = obj@scheduler.Scheduler(params, attachedBS, sinrAverager);

            % set parameters
            obj.unscheduledResourcesDL = 0;
            obj.nonHarqLastScheduledDL = 0;
        end

        function scheduleDL(obj, currentTime)
            % This function assigns user to a resource block based on their
            % position inside the waiting queue and the underlying
            % trafficmodel
            %
            % input:
            %   currentTime:    [1x1]integer slot index

            % reset the resource grid for this slot to default for no transmisison
            obj.rbGrid.DL  = obj.rbGrid.DL.reset(obj.attachedBS);

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

                    % get active users that does not need retransmissons
                    activeUsers     = setdiff(allActiveUsers, harqUsers);

                    if ~isempty(activeUsers)

                        % get scheduling weights
                        activeUsersID   = [activeUsers.id];
                        activeUsersWeights = [activeUsers.schedulingWeight];

                        % schedule last scheduled user from previous slot if they
                        % have unscheduled resources left
                        headSeg = [];
                        if obj.unscheduledResourcesDL > 0
                            headSeg = repelem(obj.attachedUsers(obj.nonHarqLastScheduledDL).id, min(obj.unscheduledResourcesDL, nResourcesForScheduling));
                        end

                        % compute the scheduling order for the next users in queue
                        nResourcesForSchedulingLeft = nResourcesForScheduling - length(headSeg);
                        schedulingSeq = repelem(circshift(activeUsersID, -obj.nonHarqLastScheduledDL), circshift(activeUsersWeights, -obj.nonHarqLastScheduledDL));
                        middleSeg = repmat(schedulingSeq, [1,floor((nResourcesForSchedulingLeft)/length(schedulingSeq))]);

                        % compute the tail scheduling order and concatenate all segments
                        tailSeg = schedulingSeq(1:mod(nResourcesForSchedulingLeft, length(schedulingSeq)));
                        scheduledUsers = [headSeg, middleSeg, tailSeg]';

                        % update userAllocation
                        % users outside of the allowed resource blocks are
                        % automatically resetted in the obj.scheduleDLCommon
                        % function
                        obj.rbGrid.DL.userAllocation(obj.rbGrid.DL.rbGridMask) = scheduledUsers;

                        % set index of the last scheduled user in the queue
                        lastActiveID        = scheduledUsers(end);
                        obj.nonHarqLastScheduledDL = find([obj.attachedUsers.id] == lastActiveID);

                        % remember how many resources for the last scheduled user were not scheduled
                        if isempty(tailSeg)
                            if length(headSeg) == nResourcesForScheduling
                                obj.unscheduledResourcesDL = obj.unscheduledResourcesDL - nResourcesForScheduling;
                            else % user scheduling fits perfectly into rbGrid
                                obj.unscheduledResourcesDL = 0;
                            end
                        else
                            obj.unscheduledResourcesDL = obj.attachedUsers(obj.nonHarqLastScheduledDL).schedulingWeight  - sum(tailSeg(:) == lastActiveID);
                        end

                    else % users that need retransmissions are the only active users
                        obj.nonHarqLastScheduledDL = 0;
                        obj.unscheduledResourcesDL = 0;
                        unusedRBs = find(obj.rbGrid.DL.userAllocation ~= -1);
                    end % if there are unscheduled users with traffic

                else % users that need retransmissions occupy all RBs
                    obj.nonHarqLastScheduledDL = 0;
                    obj.unscheduledResourcesDL = 0;
                end % if there are resources available for scheduling

                % reset RB grid mask after user allocation is
                % done all users
                obj.resetHARQMaskDL(allocatedRB, unusedRBs);

            else % no user is scheduled
                obj.nonHarqLastScheduledDL = 0;
                obj.unscheduledResourcesDL = 0;
            end % if there are users that have traffic to transmit

            % set NOMA scheduling for user and base station
            obj.nomaScheduler.scheduleNOMA(obj.attachedBS, obj.rbGrid.DL);

            % perform all calculations of the scheduler
            obj.scheduleDLCommon(currentTime);
        end

        function updateAttachedUsers(obj, newUserList)
            % updates attachedUsers and nonHarqLastScheduledDL property
            %
            % input:
            %   newUserList: [1 x nUser]handleObject users to be attached to this scheduler
            %
            % see also attachedUsers, nonHarqLastScheduledDL

            if ~isempty(newUserList)
                % get position of user that was last scheduled in new array
                newPosition = find(obj.nonHarqLastScheduledDL == [newUserList.id]);
            else
                newPosition = 0;
                obj.unscheduledResourcesDL = 0;
            end

            if newPosition
                % update nonHarqLastScheduledDL to new position in user list
                obj.nonHarqLastScheduledDL = newPosition;
            else
                % last scheduled user is no longer attached -> reset nonHarqLastScheduledDL
                obj.nonHarqLastScheduledDL = 0;
                obj.unscheduledResourcesDL = 0;
            end

            obj.attachedUsers = newUserList;
        end
    end
end

