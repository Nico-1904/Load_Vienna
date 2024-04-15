classdef SpectrumSchedulerType < uint32
    % SCHEDULERTYPE enum specifying the spectrum scheduler strategy
    % This enum specifies which class is used to determine the resource
    % split between multiple technologies.
    %
    % initial author: Christoph Buchner
    %
    % see also: scheduler.spectrumScheduler

    enumeration
        % no active spectrum scheduling, high interference expected
        none                    (1)

        % single seperation of the rb at the beginning of a simulation
        static                  (2)

        % update spectrum sceduling before user allocation
        % based on attached useres per technology
        dynamicUser             (3)

        % update spectrum sceduling before user allocation
        % based on traffic per technology
        dynamicTraffic          (4)
    end
end

