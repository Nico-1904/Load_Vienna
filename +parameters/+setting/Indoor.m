classdef Indoor < uint32
    %INDOOR indoor/outdoor position of network elements
    % This setting will be used to choose the pathloss model for a link.
    %
    %NOTE: new types should be added to this enumeration
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.indoorDecision.Geometry,
    % parameters.indoorDecision.Random, parameters.indoorDecision.Static

    enumeration
        %NOTE: numbers have to be 1,2,3, ... n since they will be mapped to
        %a cell array

        % outdoor - outside of all houses
        outdoor (1)
        % indoor - inside a house
        indoor  (2)
    end

    methods (Static)
        function num = getLength()
            % gets the number of Indoor possibilites
            %
            % output:
            %   num:    [1x1]integer number of options for Indoor
            %           It should be 2 options: indoor and outdoor

            num = length(enumeration(parameters.setting.Indoor.outdoor));
        end
    end
end

