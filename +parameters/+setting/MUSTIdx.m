classdef MUSTIdx < uint32
    % MUSTIdx enum of MUST indices
    %
    % initial author: Agnes Fastenbauer
    %
    % see also scheduler.NomaScheduler

    enumeration
        % no MUST and no NOMA transmission
        %
        % see also scheduler.NomaAdditionalNear
        Idx00	(0)

        % schedule far NOMA user on top of resources scheduled for near
        % NOMA user
        %
        % see also scheduler.NomaAdditionalFar
        Idx01	(1)

        % schedule far NOMA user on top of resources scheduled for near
        % NOMA user
        %
        % see also scheduler.NomaAdditionalFar
        Idx10	(2)

        % schedule far NOMA user on top of resources scheduled for near
        % NOMA user
        %
        % see also scheduler.NomaAdditionalFar
        Idx11	(3)
    end
end

