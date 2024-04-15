classdef SchedulerType < uint32
    % SCHEDULERTYPE enum of implemented schedulers
    %
    % initial author: Thomas Dittrich
    %
    % see also scheduler

    enumeration
        % round robin scheduler
        %
        % see also scheduler.RoundRobinScheduler
        roundRobin  (1)

        % best CQI scheduler
        %
        % see also scheduler.BestCQIScheduler
        bestCqi     (2)
    end
end

