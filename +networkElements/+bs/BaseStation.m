classdef BaseStation < matlab.mixin.Heterogeneous & tools.HiddenHandle
    %BASESTATION a base station
    % A base station has physical resources for transmission and attached
    % users, that are served on these resources. A base station can have
    % several antennas that are distributed over space, e.g. remote radio
    % heads (RRH) or a distributed antenna system (DAS). A base station can
    % also be capable of using several different technologies and
    % numerologies and can thus serve different types of users.
    %
    % Note that a site with a sectorized base stations consists of several
    % base stations here. For example a site with three sector antennas
    % consists of three base stations with one antenna at each base
    % station. This is because the base stations here are the container
    % concept for available physical resources.
    %
    %NOTE: scheduling does not yet consider combined power constraints for
    %several antennas of one base station.
    %
    % see also networkElements.bs.Antenna, tools.AntennaBsMapper,
    % networkElements.bs.CompositeBasestation,
    % networkElements.bs.compositeBsTyps.CompositeBsTech

    properties
        % list of all attached antennas
        % [1 x nAnt]handleObject networkElements.bs.Antenna
        %
        % see also networkElements.bs.Antenna
        antennaList = networkElements.bs.Antenna.empty;

        % users that are connected to this basestation
        % [1 x nUE]handleObject networkElements.ue.User
        %
        % see also networkElements.ue.User
        attachedUsers

        % user pairing for NOMA transmission
        % [2 x nNOMA]integer user pairs for NOMA transmission
        % (1,:) user with bad channel condition that will suffer additional interference
        % (2,:) user with good channel condition that will perform SIC
        % If a user in (1,:) is scheduled, then the matching user in (2,:)
        % gets scheduled on top of this resource block.
        %
        % see also parameters.Noma
        nomaPairs

        % indicator for base stations in ROI
        % [1x1]logical indicates if this BS is in the ROI
        % A base station is considered to be in the ROI if at least one of
        % its antennas has at least one user in the ROI attached to it. If
        % this indicator is set to false, that means that no antenna
        % attached to this base station has any ROI user attached.
        isRoi

        % baseband precoder used for this base station
        % [1x1]struct with baseband precoder
        %   -DL:    [1x1]handleObject precoders.Precoder
        %
        % see also precoders.Precoder
        precoder = struct();
    end

    properties (Dependent, Hidden)
        % technology used by this base station
        % [1x1]enum parameters.setting.NetworkElementTechnology
        %
        % see also networkElements.bs.CompositeBasestation,
        % parameters.setting.NetworkElementTechnology
        technology

        % number of attached antennas
        % [1x1]integer number of different antennas
        % This can be the number of antennas in a DAS or the number of RRHs
        % or the different antennas in an MBSFN or one for a single antenna
        % for a regular base station.
        %
        % DAS: Distributed Antennas System
        %
        % see also antennaList
        nAnt
    end

    methods
        function obj = BaseStation()
            % empty class constructor for easy object array construction

        end

        function handle = plotAntennas(obj, timeIndex, color)
            % plot plots basestation's antennas in a color (eg.: 'm', 'y')
            % See also scatter3.

            hold on;
            for ii = 1:length(obj.antennaList)
                handle = obj.antennaList(ii).plot(timeIndex, color);
            end
            hold off;
        end

        function setDLsignaling(obj, rbGrid)
            % sets new scheduling information of each antenna
            %
            % input:
            %   rbGrid: [1x1]object scheduler.rbGrid

            for iAntenna = 1:obj.nAnt
                obj.antennaList(iAntenna).rbGrid = rbGrid;
            end
        end

        function setIsRoi(obj, isInROI, iSlot)
            % sets isInROI for all antennas
            % For DL isInROI is only set to false for all base station
            % antennas if all users of all antennas attached to this base
            % station are in the interference region. It does not
            % necessarily mean that the antenna positions are in the ROI
            % or in the interference region.
            %
            % input:
            %   isInROI:    [1x1]logical indicates if base station antennas are in ROI or in interference region
            %
            % used properties: nAnt, antennaList

            obj.isRoi = isInROI;

            for iAnt = 1:obj.nAnt
                obj.antennaList(iAnt).isInROI(iSlot) = isInROI;
            end
        end

        %% getter and setter functions
        function antennaList = get.antennaList(obj)
            % returns the antennaList
            % depending on the subclass the antennaListSubclassGetterHelper
            % might be overwritten
            %
            % used properties: antennaList
            %
            % output:
            %   antennaList:   [1 x nAnt]handleObject networkElements.bs.Antenna

            antennaList = obj.antennaListSubclassGetterHelper(obj.antennaList);
        end

        function nAnt = get.nAnt(obj)
            % returns the number of antennas in the antenna list
            % depending on the subclasss the nAntSubclassGetterHelper
            % might be overwriten
            %
            % used properties: nAnt
            %
            % output:
            %   nAnt:   [1x1]integer number of antennas attached to this base station

            nAnt = length(obj.antennaList);
        end

        function technology = get.technology(obj)
            % returns the unique technology used by the transmit antennas
            %
            % used properties: technology
            %
            % output:
            %   technology:   [1x1]enum parameters.setting.NetworkElementTechnology

            technology = unique([obj.antennaList.technology]);
        end
    end

    methods (Access = protected)
        % following functions should be overwritten for subclasses with
        % different set get properties
        function newAntennaList = antennaListSubclassGetterHelper(~,antennaList)
            % returns the antennaList
            %
            % used properties: antennaList
            %
            % input:
            %   antennaList: [1 x nAnt]handleObject networkElements.bs.Antenna
            % output:
            %   newAntennaList:   [1 x nAnt]handleObject networkElements.bs.Antenna

            newAntennaList = antennaList;
        end
    end
end

