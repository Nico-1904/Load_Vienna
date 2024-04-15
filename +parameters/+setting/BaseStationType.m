classdef BaseStationType < uint32
    %BASESTATIONTYPE enum of base station types (macro, femto, ...)
    %
    %NOTE: new types should be added to this enumeration and a minimal
    %coupling loss  and a cell association bias for this base station type
    %has to be set in parameters.PathlossModelContainer
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.PathlossModelContainer, networkElements.bs.BaseStation

    enumeration
        %NOTE: numbers have to be 1,2,3, ... n (they are mapped to a cell array)

        % macro base station
        macro	(1)
        % pico base station
        pico	(2)
        % femto base station
        femto	(3)
    end

    methods (Static)
        function num = getLength()
            % get the total number of possible base station types
            %
            % output:
            %   num:    [1x1]integer total number of possible base station types

            num = length(enumeration(parameters.setting.BaseStationType.macro));
        end
    end
end

