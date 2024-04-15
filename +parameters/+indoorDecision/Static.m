classdef Static < tools.HiddenHandle
    %STATIC indoor/outdoor decision for users is constant
    % Static is a parameter class that defines how to decide if the users
    % of the user group are indoor or outdoor, all users will be either
    % indoor or outdoor.
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.setting.Indoor,
    % simulation.ChunkSimulation.setIsIndoor,
    % parameters.indoorDecision.Geometry, parameters.indoorDecision.Random

    properties
        % indicator for indoor users
        % [1x1]logical indicates if user is indoor
        % This is true if users are indoor and false if users are outdoor.
        isIndoor
    end

    methods
        function obj = Static(isIndoor)
            % static indoor/outdoor decision for a user class
            % The users will be treated as indoor or outdoor users,
            % depending on the setting made with isIndoor input, during the
            % simulation. No indoor/outdoor will be made for these users.
            %
            % input:
            %   isIndoor:   [1x1]enum parameters.setting.Indoor

            if exist('isIndoor', 'var')
                switch isIndoor
                    case parameters.setting.Indoor.indoor
                        obj.isIndoor = true;
                    case parameters.setting.Indoor.outdoor
                        obj.isIndoor = false;
                    otherwise
                        error('indoorDecision.Static needs to be "indoor" or "outdoor"');
                end
            else
                error('noSetting:IndoorOrOutdoor','Static indoor/outdoor decision requires the parameters.setting.Indoor input for decision.');
            end
        end
    end
end

