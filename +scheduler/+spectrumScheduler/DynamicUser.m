classdef DynamicUser < scheduler.spectrumScheduler.Super
    % DynamicUser, use instance of this class if dynamic spectrum scheduling based on
    % attached users per technology is desired

    methods
        function obj = DynamicUser(params, attachedBS, sinrAverager)
            % DynamicUser Construct an instance of this class
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
        function updateRbGridMaskDL(obj)
            % updateRBGridMaskDL is used update the rbGridMask for the
            % subSchedulers
            % the DynamicUser Spectrum Scheduler assignes the rbGrid
            % dynamical based on the numebr of users in each technology
            % attached to this scheduler

            % reset rbGridMask
            obj.rbGridMaskDL  = false(size(obj.rbGridMaskDL));

            [nFreq, ~ ,nSub]=size(obj.rbGridMaskDL);

            % get number of users per SubScheduler
            nUserPerSub = obj.getNUsersPerSubDL();
            nUser = sum(nUserPerSub,2);
            if ~nUser
                % default equal distribution when not a single active user
                initialRate = ones(1,nSub) ;
            else
                % calculate rate of rb associated with each subScheduler
                initialRate = nUserPerSub / nUser;
            end

            % apply weighting to give a priority
            biasedRate = initialRate .* obj.weights;
            %renormalise
            normRate = biasedRate /sum(biasedRate);
            subRate = floor(normRate * nFreq);
            index = cumsum(subRate);

            % handle borders
            lower = [1,index(1:end-1)];
            upper = [index(1:end-1)-1,nFreq];
            % set allowed entries
            for iSub = 1 : nSub
                obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub) ...
                    = true(size(obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub)));
            end
        end
    end
end

