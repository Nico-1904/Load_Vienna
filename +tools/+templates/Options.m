classdef Options < tools.HiddenHandle
    %Options holds the options for template replacement

    properties
        replacements = containers.Map();
        outputFile = '';
    end

    methods
        function addReplacement(obj, key, value)
            obj.replacements(key) = value;
        end

        function [keys, values] = getReplacements(obj)
            keys = obj.replacements.keys();
            values = obj.replacements.values();
        end
    end

end

