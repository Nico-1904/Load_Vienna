classdef Random < tools.HiddenHandle
    %RANDOM indoor/outdoor property is decided randomly with a set probability
    % This parameter class defines how to decide if the users of a user
    % group are indoor or outdoor.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.ChunkSimulation.setIsIndoor

    properties
        % probability that a user is indoor
        % [1x1]double indoor probability
        indoorProbability = 0.5;
    end

    methods
        function obj = Random(indoorProbability)
            % class constructor
            % Sets indoorProbability if an indoorProbability is handed to
            % the class constructor.
            %
            % input:
            %   indoorProbability:  [1x1]double probability that a user is indoor

            if exist('indoorProbability', 'var')
                obj.indoorProbability = indoorProbability;
            end % if an indoorProbability is set
        end
    end
end

