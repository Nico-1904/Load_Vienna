classdef NetworkElementTechnology < uint32
    % NetworkElementTechnology allows the user to assign a technology to a
    % Networkelement which restricts the cellAssociation to only link up
    % antennas and user of the same technology
    %
    % see also: simulation.ChunkSimulation.cellAssociation,
    % networkElement.NetworkElementWithPosition
    %
    % initial author: Christoph Buchner

    enumeration
        % specifies the Networkelement to be a LTE element
        LTE	(1)

        % specifies the Networkelement to be a 5G element
        NRMN_5G	(2)
    end
end

