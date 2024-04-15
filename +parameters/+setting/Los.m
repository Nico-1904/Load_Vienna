classdef Los < uint32
    % LOS LOS/NLOS state of links
    % Indicates if a link has a LOS connection or is blockked.
    %
    %NOTE: new types should be added to this enumeration
    %
    % LOS:  line of sight
    % NLOS: non line of sight
    %
    % initial author: Lukas Nagel

    enumeration
        % numbers have to be 1,2,3, ... n (they are mapped to a cell array)

        % Non-Line Of Sight
        NLOS  (1)
        % Line Of Sight
        LOS   (2)
    end

    methods (Static)
        function num = getLength()
            % gets the total number of options for Los
            %
            % output:
            %   num:    [1x1]integer number of options for Los setting

            num = length(enumeration(parameters.setting.Los.NLOS));
        end
    end
end

