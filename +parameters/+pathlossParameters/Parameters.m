classdef Parameters < tools.HiddenHandle & matlab.mixin.Heterogeneous
    % superclass for path loss model parameters
    %
    % see also parameters.PathlossModelContainer, macroscopicPathlossModel

    methods (Abstract)
        % creates the macroscopic fading object that will calculate the path loss
        %
        % output:
        %   pathLossModel: [1x1]handleObject macroscopicPathlossModel.PathlossModel
        pathLossModel = createPathLossModel(obj)
    end

    methods
        function checkParameters(obj)
            % empty check parameters function
        end
    end
end

