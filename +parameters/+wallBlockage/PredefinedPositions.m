classdef PredefinedPositions < parameters.wallBlockage.Parameters
    % PredefinedPositions - predefined position wall creation parameters
    % Adding these parameters to parameters.Parameters.wallParameters
    % creates walls with the predefined positions in the simulation.
    %
    % initial author: Lukas Nagel
    %
    % see also blockages.WallBlockage, parameters.Parameters.wallParameters

    properties (SetAccess = private)
        % handle to the wall generation function
        createWallFunction = @blockages.WallBlockage.generatePredefinedPositions;
    end
end

