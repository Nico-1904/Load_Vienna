classdef CellAssociationStrategy < uint32
    %CellAssociationStrategy enum of different cell association strategies
    % Defines different strategies that can be used to choose the serving
    % base stations for a user.
    %
    % initial author: Christoph Buchner
    %
    % see also +cellManagement,
    % parameters.PathlossModelContainer.cellAssociationBiasdB

    enumeration
        % assign user to cells based on receive power
        % The macroscopic receive power is used to choose the cell a user
        % is served by. The macroscopic receive power considers the
        % transmit power, antenna gain, path loss, wall loss, and
        % shadowing.
        %
        % see also cellManagement, simulation.ChunkSimulation.receivePower
        maxReceivePower	(1)

        % assign user to cells based on wideband SINR
        % The wideband SINR is calculated and the cell with the strongest
        % SINR is chosen as the serving cell. The wideband SINR considers
        % the transmit power, antenna gain, path loss, wall loss, and
        % shadowing.
        %
        % see also cellMangement, simulation.ChunkSimulation.widebandSINR
        maxSINR	(2)
    end
end

