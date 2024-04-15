classdef CompositeBsTech < networkElements.bs.CompositeBasestation
    %CompositeBsTech class, special base station that allows usage of a spectrum schedulers
    % linking up several technologies in one BS
    %
    % initial Author: Christoph Buchner
    % see also networkElements.bs.BaseStation,
    % scheduler.dynamicSpectrumScheduler

    methods
        function obj = CompositeBsTech(originalBaseStation)
            % call superclass constructor
            if nargin == 0
                originalBaseStation = [];
            end
            obj = obj@networkElements.bs.CompositeBasestation(originalBaseStation);
        end

        function splitter = getNetworkElementSplitter(~, networkelement)
            % This function returns a string representing the technology
            % which is used in several functions to distribute resources.
            %
            % input:
            %   networkelement [1 x nNE] handle networkElements
            %
            % output:
            %   splitter [1 x nNE] string
            %
            % overwrite this function to define your own spectrum scheduling

            if isempty(networkelement)
                splitter = [];
            else
                NeTechs = string([networkelement.technology]);
                NeNums = int2str([networkelement.numerology]');
                splitter = strcat(NeTechs',':',NeNums)';
            end
        end
    end
end

