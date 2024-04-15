classdef Static < scheduler.spectrumScheduler.Super
    % STATIC is a sub class of the superclass of the SpectrumScheduler
    % it is used to define the behavior of the subScheduler based on a one
    % time decision and then keeps the rbGridMask static.

    methods
        function obj = Static(params, attachedBS, sinrAverager)
            %constructor
            % input:
            %   params:       [1x1] parameters.Parameters
            %   attachedBS:   [1x1] networkElements.bs.BaseStation
            %   sinrAverager: [1x1] tools.MiesmAverager

            %call superConstructor
            obj = obj@scheduler.spectrumScheduler.Super(params, attachedBS, sinrAverager);

            %set masks once at the beginning
            obj.updateRbGridMaskDL();

            %forward rbGridMask to subscheduler
            for iSub = 1: size(obj.subScheduler,2)
                obj.subScheduler(iSub).rbGrid.DL.rbGridMask = obj.rbGridMaskDL(:,:,iSub);
            end
        end
    end

    methods
        function updateSubRbGrids(~)
            % this function implements a template to update the rbGrid mask
            % of the subScheduler by calling the updateRbGridMask functions
            % for the ul and dl and assigning the results

            %if Static is used this function does nothing
        end

        function updateRbGridMaskDL(obj)
            % updateRBGridMaskDL is used update the seperation of the rbGrid for
            % the subSchedulers
            % the static Spectrum Scheduler assignes the rbGrid
            % statically

            [nFreq,~,nSub]=size(obj.rbGridMaskDL);
            %reset rbGridMask
            obj.rbGridMaskDL  = false(size(obj.rbGridMaskDL));

            % set rate between subschedulers based on the given weights
            subRate = floor(obj.weights * nFreq);
            index = cumsum(subRate);

            %handle borders
            lower = [1,index(1:end-1) + 1];
            upper = [index(1:end-1),nFreq];
            %set allowed entries
            for iSub = 1 : nSub
                obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub) ...
                    = true(size(obj.rbGridMaskDL(lower(iSub):upper(iSub),:,iSub)));
            end
        end
    end
end

