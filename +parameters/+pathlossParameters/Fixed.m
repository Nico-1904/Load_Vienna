classdef Fixed < parameters.pathlossParameters.Parameters
    % parameter class for fixed path loss
    % Sets the path loss to the fixed value set here in fixedPathLossdB.
    %
    % see also macroscopicPathlossModel.Fixed,
    % parameters.PathlossModelContainer, fixedPathLossdB

    properties
        % fixed pathloss value for Fixed pathloss model
        % [1x1]double fixed value for pathloss
        %
        % see also macroscopicPathlossModel.Fixed
        fixedPathLossdB = 50;
    end

    methods
        function pathLossModel = createPathLossModel(obj)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.Fixed(obj.fixedPathLossdB);
        end

        function checkParameters(obj)
            % check that path loss is positive

            if obj.fixedPathLossdB < 0
                warning('warn:negativeLoss', 'The fixed path loss has a negative value, this will be a path gain in the simulation.');
            end
        end
    end
end

