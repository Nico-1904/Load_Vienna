classdef ShadowFadingParameters < tools.HiddenHandle
    %SHADOWFADINGPARAMETERS shadow fading settings
    % This class collects the shadow fading settings and sets the default
    % values.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also shadowing.ShadowFadingMapLinearFiltering

    properties
        % indicator for use of shadow fading
        % [1x1]logical true when shadow fading is simulated
        on         = false;

        % shadow fading map resolution
        % [1x1]double map resolution
        resolution = 5;

        % map correlation
        % [1x1]double map correlation
        mapCorr    = 0.5;

        % mean shadow fading value
        % [1x1]double mean value of shadow fading
        meanSFV    = 0;

        % standard devaition of shadow fading values
        % [1x1]double standard deviation
        stdDevSFV  = 1;

        % decorrelation distance of shadow fading
        % [1x1]double decorrelation distance
        decorrDist = log(2)*20;
    end
end

