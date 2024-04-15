classdef None < scheduler.spectrumScheduler.Super
    %NONE use this class if no dynamic spectrum scheduling is desired
    % If this class is used the resources attached to the subscheduler will
    % fully interfere with each other

    methods
        function obj = None(params, attachedBS, sinrAverager)
            %None Construct an instance of this class
            % input:
            %   params:       [1x1] parameters.Parameters
            %   attachedBS:   [1x1] networkElements.bs.BaseStation
            %   sinrAverager: [1x1] tools.MiesmAverager
            %
            obj = obj@scheduler.spectrumScheduler.Super(params, attachedBS, sinrAverager);
        end
    end

    methods
        function updateSubRbGrids(~)
            % this function implements a template to update the rbGrid mask
            % of the subScheduler by calling the updateRbGridMask functions
            % for the ul and dl and assigning the results

            %if None is used this function does nothing
        end

        function updateRbGridMaskDL(obj)
            % updateRBGridMaskDL is used update the seperation of the rbGrid for
            % the subSchedulers
            % if none is selected as spectrum scheduler the rbGridMask is
            % all true
            obj.rbGridMaskDL = true(size(obj.rbGridMaskDL));
        end
    end
end

