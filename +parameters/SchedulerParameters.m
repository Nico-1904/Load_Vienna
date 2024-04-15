classdef SchedulerParameters < tools.HiddenHandle
    %SCHEDULERPARAMETERS scheduler settings
    % This class contains all parameters necessary to set a scheduler.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also scheduler.Scheduler, scheduler.RoundRobinScheduler,
    % scheduler.BestCQIScheduler, parameters.setting.SchedulerType

    properties
        % scheduler type
        % [1x1]enum parameters.setting.SchedulerType
        type = parameters.setting.SchedulerType.roundRobin;
    end
end

