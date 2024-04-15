classdef DynamicTraffic < scheduler.spectrumScheduler.Super
    % DynamicTraffic, use this class if dynamic spectrum scheduling based on users traffic
    % per technology is desired

    methods
        function obj = DynamicTraffic(params, attachedBS, sinrAverager)
            %Dynamic traffic constructs an instance of this class
            % input:
            %   params:       [1x1] parameters.Parameters
            %   attachedBS:   [1x1] networkElements.bs.BaseStation
            %   sinrAverager: [1x1] tools.MiesmAverager
            %
            % see also: scheduler.spectrumScheduler.Super

            obj = obj@scheduler.spectrumScheduler.Super(params, attachedBS, sinrAverager);
        end
    end

    methods
        function dlTrafficPerSub = getDLTrafficPerSub(obj)
            % returns list of remaining bits in the downlink to transmit
            % per subscheduler
            %
            % output:
            %   trafficPerSub:  [1x nSub] integer

            nSub = size(obj.schedulerSplitter,2);
            dlTrafficPerSub = zeros(1,nSub);

            % get traffic models from users
            users = [obj.attachedUsers];
            if isempty(users)
                return
            end
            userTM = [users.trafficModel];
            bitsPerUsers = [userTM.nBitsQueue];

            % get assignment from user to sub scheduler
            userSplitters = obj.attachedBS.getNetworkElementSplitter(users);
            % calculate number of remaining bits per sub scheduler
            for iSub = 1:nSub
                dlTrafficPerSub(iSub) = sum(bitsPerUsers(userSplitters == obj.schedulerSplitter(iSub)));
            end
        end

        function updateRbGridMaskDL(obj)
            % updateRBGridMaskDL is used update the rbGridMask of the
            % the subSchedulers.
            % This Spectrum Scheduler assigns the rbGrid
            % dynamically based on the user traffic

            % reset rbGridMasks
            obj.rbGridMaskDL = false(size(obj.rbGridMaskDL));

            % getGridParams
            [nFreq,~,nSub] = size(obj.rbGridMaskDL);

            % get Traffic in each subScheduler
            trafficPerSub = obj.getDLTrafficPerSub();

            % if full buffer traffic model is selected trafficPerSub will
            % be infinite therefore it is overwritten in here with some
            % default values which will result in an equal distribution
            if any(isinf(trafficPerSub))
                trafficPerSub = ones(size(trafficPerSub));
            end

            traffic = sum(trafficPerSub,2);
            if ~traffic
                % no traffic at all
                % equal distribution of resources
                initialRate = ones(1,nSub) ;
            else
                % calculate rate of rb associated with each subScheduler
                initialRate = trafficPerSub / traffic;
            end

            % apply weighting to give a priority
            biasedRate = initialRate .* obj.weights;
            % renormalise
            normRate = biasedRate / sum(biasedRate);
            subRate = floor(normRate * nFreq);

            index = cumsum(subRate);
            % generate boundry lists
            index(end) = nFreq;
            index = [0,index];
            lower = index(1:end-1)+1;
            upper = index(2:end);

            % set allowed entries
            for iSub = 1 : nSub
                % Schedule only in nFreq

                obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub) ...
                    = true(size(obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub)));
            end
        end
    end
end

