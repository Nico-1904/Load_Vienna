classdef CyclicPrefix < uint32
    %CYCLICPREFIX enum of implemented cyclic prefix types
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.resourceGrid.ResourceGrid,
    % parameters.resourceGrid.LTE

    enumeration
        % normal cyclic prefix
        normal      (1)

        % extended cyclic prefix
        extended    (2)
    end
end

