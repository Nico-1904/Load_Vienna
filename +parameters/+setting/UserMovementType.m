classdef UserMovementType < uint32
    %MOVEMENTTYPE types of user movements
    % This is the enum of all possible user movement models. According to
    % the movement model the user positions per slot are generated.
    %
    % initial author: Thomas Dittrich
    %
    % see also +networkGeometry

    enumeration
        % random direction, constant speed
        RandConstDirection (1)

        % constant position - users do not move
        ConstPosition (2)

        % constant speed with random walking pattern
        ConstSpeedRandomWalk (3)

        % predefined user trace
        % The user positions set in the scenario file for each slot are
        % used.
        % The positions are set in the user parameters under
        % userMovement.positionList as a [3 x nSlotsTotal x nUser]double.
        Predefined (4)
    end
end

