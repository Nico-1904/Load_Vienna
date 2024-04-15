classdef FreeSpace < parameters.pathlossParameters.Parameters
    % parameter class for free space path loss with path loss exponent alpha
    %
    % see also macroscopicPathlossModel.FreeSpace,
    % parameters.PathlossModelContainer, alpha

    properties
        % pathloss exponent for FreeSpace pathloss model
        % [1x1]double pathloss exponent for free space pathloss
        % If the pathloss exponent is set to a value lower than 2, a
        % warning is thrown and the simulation continued.
        %
        % see also macroscopicPathlossModel.FreeSpace
        alpha = 2;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.FreeSpace(obj.alpha);
        end

        function checkParameters(obj)
            % checks pathloss parameters
            %
            % see also parameters.Parameters.checkParameters

            % check free space alpha
            if obj.alpha < 2
                warn = 'The free space pathloss exponent is smaller than 2, this could lead to unreliable results.';
                warning('warn:alpha', warn);
            end
        end
    end
end

