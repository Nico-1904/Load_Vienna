classdef ResourceGrid < uint32
    % RESOURCEGRID enum of implemented resource grid types
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.resourceGrid.ResourceGrid.generateResourceGrid,
    % parameters.resourceGrid.ResourceGrid, parameters.resourceGrid.LTE

    enumeration
        % LTE standard compliant resource grid
        LTE     (1)
        % Flexible LTE for numerology
        NR5G (2)
    end
end

