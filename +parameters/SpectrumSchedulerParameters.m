classdef SpectrumSchedulerParameters < tools.HiddenHandle
    %SpectrumSchedulerParameters spectrum scheduler settings
    %   This class contains all parameters necessary to set a spectrum scheduler.
    %
    % initial author: Christoph Buchner
    %
    % see also scheduler.spectrumScheduler.Super,
    % scheduler.spectrumScheduler.None,
    % scheduler.spectrumScheduler.Static,
    % scheduler.spectrumScheduler.DynamicUser,
    % scheduler.spectrumScheduler.DynamicTraffic

    properties
        % scheduler type
        % [1x1]enum parameters.setting.SchedulerType
        type = parameters.setting.SpectrumSchedulerType.static;

        % Specifies the weight of a given key
        % [1x1] container.Map
        % if the key is not inside of this map the weight is assumed to be 1
        weigths = containers.Map;
    end

    methods
        function checkParameters(obj)
            % check parameters compability - empty for now

        end
    end
end

