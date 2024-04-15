classdef Indoor < parameters.pathlossParameters.Parameters
    % parameter class for indoor path loss model 3GPP TR 25.952 (V5.2.0)
    % Indoor environment with small/pico cells.
    %
    % The model is derived from the COST 231 indoor model.
    %
    % No additional parameters have to be set for this model.
    %
    %NOTE: The wall penetration loss is not accounted for in this
    %implementation.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.Indoor,
    % parameters.PathlossModelContainer

    methods
        function pathLossModel = createPathLossModel(~)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.Indoor;
        end
    end
end

