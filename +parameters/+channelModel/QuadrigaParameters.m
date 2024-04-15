classdef QuadrigaParameters < handle
    % QUADRIGAPARAMETERS contains all channel model parameters specific to
    % Quadriga. This file is part of the interface for the Quadriga Channel
    % Model.
    %
    % see also smallScaleFading.QuadrigaContainer

    properties
        % Quadriga scenario
        % String
        % Available scenarios are shown in quadriga_src/config.
        scenario = '3GPP_38.901_UMi_LOS';

        % Use 3GPP compliant settings and disable Quadriga's unique
        % features
        % [1x1] boolean
        enable3gppPreset = false;
    end
end

