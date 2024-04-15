classdef CompositeBasestation < networkElements.bs.BaseStation
    %CompositeBasestation base station class with sub base stations
    % This CompositeBasestation is used to generate dependencies between
    % several BS. It allows usage of a Dynamic Spectrum Scheduler
    % linking up several BS using more than one technology.
    %
    % initial author: Christoph Buchner
    %
    % see also networkElements.bs.BaseStation,
    % scheduler.dynamicSpectrumScheduler

    properties
        % list of all attached subBaseStations for the subscheduler of the spectrumscheduler
        % [1 x nBS]handleObject networkElements.bs.BaseStation
        subBaseStationList
    end

    methods (Abstract)
        % returns an assignment value for each network element
        % This assignment is used in several functions to distribute
        % resources based on properties of a network element.
        %
        % input:
        %   networkelement:  [1 x nNE]handle networkElements
        %
        % output:
        %   splitter:   [1 x nNE] property of NE
        %               normally used for spectrum scheduling then it would be string
        %
        % overwrite this function to define your own resource scheduling
        splitter = getNetworkElementSplitter(~, networkelement);
    end

    methods
        function obj = CompositeBasestation(originalBaseStation)
            % class constructor converts an BasestationList into a composite BS
            %
            % input:
            %   originalBaseStation: [1x nSubBS]handle networkElements.bs.BaseStation
            %
            % see also: networkElements.bs.BaseStation

            % call superclass constructor
            obj = obj@networkElements.bs.BaseStation();

            if nargin == 0 || isempty(originalBaseStation)
                % early exit if originalBaseStation is empty
                % this is the case if a list of CompositeBasestation is
                % preallocated
                return
            end

            % get splitters to determine antenna to sub base station mapping
            antennaSplitter     = obj.getNetworkElementSplitter(originalBaseStation.antennaList);
            baseStationSplitter = unique(antennaSplitter);
            nSubBaseStation = size(baseStationSplitter,2);

            % preallocation of new sub base stations
            subBaseStations(nSubBaseStation) = networkElements.bs.BaseStation;

            % assignment of antennas to subBS based on splitter
            for iSubBS = 1:nSubBaseStation
                % get act Bs and antennas
                iSplitter = baseStationSplitter(iSubBS);
                actAntennas = originalBaseStation.antennaList(iSplitter == antennaSplitter);

                % set same properties as in the original BS
                subBaseStations(iSubBS) = originalBaseStation.copy();
                % set antennas with same splitters
                subBaseStations(iSubBS).antennaList = actAntennas;
            end
            obj.subBaseStationList = subBaseStations;
        end
    end

    methods (Access = protected)
        function newAntennaList = antennaListSubclassGetterHelper(obj,~)
            % returns the antennaList combining all antennas attached to the subBaseStations
            %
            % used properties: antennaList, subBaseStationList
            %
            % input:
            %   antennaList:    [1 x nAnt]handleObject networkElements.bs.Antenna
            %
            % output:
            %   newAntennaList: [1 x nAnt]handleObject networkElements.bs.Antenna

            if isempty(obj.subBaseStationList)
                newAntennaList = [];
            else
                newAntennaList = [obj.subBaseStationList.antennaList];
            end
        end
    end
end

