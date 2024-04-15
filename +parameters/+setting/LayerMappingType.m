classdef LayerMappingType < uint32
    % LAYERMAPPINGTYPE enum of implemented layer mapping types
    %
    % initial author: Thomas Dittrich
    %
    % see also parameters.trasnmissionParameters.LayerMapping

    enumeration
        % downlink layer mapping according to TS36 211 V13.1.0 (2016-04)
        %
        % see also parameters.transmissionParameters.LteLayerMappingTS36211
        TS36211     (1)
    end
end

