classdef Geometry < tools.HiddenHandle
    %GEOMETRY parameter class that defines how to decide if the users of a user group are indoor or outdoor
    % If this class is instanciated the indoor outdoor decision is based
    % on the actual geometry.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.ChunkSimulation.setIsIndoor

    methods
        function obj = Geometry()
        end
    end
end

