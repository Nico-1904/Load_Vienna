classdef Super < scheduler.Scheduler
    %SUPER SuperClass of the spectrum scheduler types
    %specifies interfaces for subscheduler and the interface for traffic models

    properties
        % scheduler of each sub BS responsible for only one technology
        % [1 x nSub]handle scheduler.Scheduler
        subScheduler = [];

        % mask which defines which DL rb are accessable by the subScheduler
        % [nFreq x nTime x nSub]logical
        rbGridMaskDL = [];

        % weight of each subScheduler, defined in the scenario setup,
        % this parameter can bias the resource distribution between
        % the subschedulers
        % [1xnSub] double
        weights =[];
    end

    properties (Access=protected)
        % parameter used for splitting users to the seperate subScheduler
        % [1 x nSub]enum parameters.setting.NetworkElementTechnology
        schedulerSplitter = [];
    end

    methods (Abstract)
        % updateRBGridMaskDL is used update the seperation of the rbGrid for
        % the subSchedulers
        updateRbGridMaskDL(obj)
    end

    methods
        function obj = Super(params, attachedBS, sinrAverager)
            %SUPER Construct an instance of this class
            % input:
            %   params:       [1x1] parameters.Parameters
            %   attachedBS:   [1x1] networkElements.bs.BaseStation
            %   sinrAverager: [1x1] tools.MiesmAverager

            obj = obj@scheduler.Scheduler(params, attachedBS, sinrAverager);
            obj.rbGrid=[];
            obj.schedulerSplitter = unique(obj.attachedBS.getNetworkElementSplitter(obj.attachedBS.antennaList));
            for subBS = attachedBS.subBaseStationList
                % no further check is needed if subBS and scheduler have
                % the same splitter because they were build to have the
                % same.
                newSub = scheduler.Scheduler.generateScheduler(params, subBS, sinrAverager);
                obj.subScheduler =[obj.subScheduler,newSub];
                %init rbGridMask
                obj.rbGridMaskDL = cat(3,logical(obj.rbGridMaskDL), true(size(newSub.rbGrid.DL.userAllocation)));
            end
            % store the information to allow assigning users
            obj.setWeights(params.spectrumSchedulerParameters.weigths);
        end

        function updateSubRbGrids(obj)
            % this function implements a template to update the rbGrid mask
            % of the subScheduler by calling the updateRbGridMask functions
            % for the ul and dl and assigning the results
            obj.updateRbGridMaskDL();

            for iSub = 1: size(obj.subScheduler,2)
                obj.subScheduler(iSub).rbGrid.DL.rbGridMask = obj.rbGridMaskDL(:,:,iSub);
            end
        end

        function scheduleDL(obj, currentTime)
            % manages scheduling of the downlink
            obj.updateSubRbGrids();
            for iSub = 1: size(obj.subScheduler,2)
                obj.subScheduler(iSub).scheduleDL(currentTime);
            end
        end

        function updateAttachedUsers(obj, newUserList)
            % updates attachedUsers for all subschedulers
            %
            % input:
            %   newUserList: [1 x nUser]handleObject users to be attached to this scheduler
            %
            % see also attachedUsers

            if ~isempty(newUserList)
                % get splitter variable for the given users
                userSplitters = obj.attachedBS.getNetworkElementSplitter(newUserList);
                % compare user splitter to sub scheduler splitter and assign to subscheduler if matched
                for iSub = 1:size(obj.subScheduler,2)
                    obj.subScheduler(iSub).updateAttachedUsers(newUserList(userSplitters == obj.schedulerSplitter(iSub)));
                end
            else
                for iSub = 1:size(obj.subScheduler,2)
                    obj.subScheduler(iSub).updateAttachedUsers([]);
                end
            end

            % update the users attached to the super scheduler
            obj.attachedUsers = [obj.subScheduler.attachedUsers];
        end

        function plotSubRBGridMasks(obj)
            % Function used to present the actual state of the
            % rbSubGridmask as a plot

            % create a subplot for each subscheduler
            nSubPlots = size(obj.subScheduler(),2);
            for iSubPlot = 1:nSubPlots

                subplot(2,nSubPlots,iSubPlot)

                imshow(obj.subScheduler(iSubPlot).rbGrid.DL.rbGridMask);
                title(replace(string(obj.schedulerSplitter(1)),"_","DL"))
            end
        end

        function print(obj)
            % Print debug information to inspect the structure of the
            % scheduler in use

            fprintf('Spectrum Scheduler : \n');
            for iSub = 1: size(obj.subScheduler,2)
                fprintf('-----Sub Scheduler %i : \n',iSub);
                obj.subScheduler(iSub).print();
            end
        end
    end

    methods (Access = protected)
        function nUsersPerSub = getNUsersPerSubDL(obj)
            % helper function for several scheduling strategies
            % evaluates number of downlink useres per subscheduler
            %
            % output:
            %   [1 x nSubBS]integer number of users attached to each sub base station

            nSub = size(obj.subScheduler,2);
            nUsersPerSub = zeros(1,nSub);
            for iSub = 1: nSub
                attachedDL = obj.subScheduler(iSub).attachedUsers;
                nUsersPerSub(iSub) = size(attachedDL,2);
            end
        end

        function setWeights(obj,weightMap)
            % this function extracts the essential weights from the config given
            % map
            nSub = size(obj.subScheduler,2);
            % preset weights for each subScheduler to 1
            newWeights = ones(1,nSub);

            % assign new weigths where schedulerSplitter is equal to the
            % key in the weightMap
            splitter = obj.schedulerSplitter;
            keys = weightMap.keys;
            values = weightMap.values;
            for iSplitter =1:nSub
                mask = splitter(iSplitter)==keys;
                if(sum(mask,2)==1)
                    newWeights(iSplitter)=values{mask};
                end
            end
            % normalise weights
            newWeights = newWeights/sum(newWeights);
            obj.weights = newWeights;
        end
    end
end

