classdef AntennaBsMapper < tools.HiddenHandle
    %ANTENNABSMAPPER maps the global to local anntenna indices
    %
    % example:
    % For two composite base stations with two sub base stations each with
    % 1 or 2 antennas, the antennaBsMap looks like the following matrix:
    %  BS   Ant subBS   Ant iSubBS
    %  1    1   1       1   1   % 1st BS, 1st antenna at this BS, 1st sub BS, 1st antenna at this sub BS, 1st sub base station at this base station
    %  1    2   2       1   2   % 1st BS, 2nd antenna at this BS, 2nd sub BS, 1st antenna at this sub BS, 2nd sub base station at this base station
    %  1    3   2       2   2   % 1st BS, 3rd antenna at this BS, 2nd sub BS, 2nd antenna at this sub BS, 2nd sub base station at this base station
    %  2    1   3       1   1   % 2nd BS, 1st antenna at this BS, 3rd sub BS, 1st antenna at this sub BS, 1st sub base station at this base station
    %  2    2   3       2   1   % 2nd BS, 2nd antenna at this BS, 3rd sub BS, 2nd antenna at this sub BS, 1st sub base station at this base station
    %  2    3   4       1   2   % 2nd BS, 3rd antenna at this BS, 4th sub BS, 1st antenna at this sub BS, 2nd sub base station at this base station
    %
    % initial author: Lukas Nagel
    % extended by Christoph Buchner and Agnes Fastenbauer for composite BSs
    %
    % see also networkElements.bs.Antenna, networkElements.bs.BaseStation,
    % networkElements.bs.CompositeBaseStation

    properties
        % antenna to base station mapping
        % [nAntenna x 4]integer with global base station index in 1st column and antenna index at the base station in 2nd column
        % Each row represents an antenna:
        %   -[:, 1] base station index this antenna belongs to
        %   -[:, 2] local antenna index at its base station
        %   -[:, 3] sub base station index this antenna belongs to
        %   -[:, 4] local antenna index at its sub base station
        antennaBsMap
    end

    methods
        function obj = AntennaBsMapper(baseStationList)
            % creates the look-up table with all base stations and antennas
            %
            % set properties antennaBsMap
            %
            % see also antennaBsMap, networkElements.bs.CompositeBaseStation

            % initialize antenna- base station map
            nAntennas = length([baseStationList.antennaList]);
            obj.antennaBsMap = zeros(nAntennas, 5);

            % initialize antenna counter
            iAntTot = 1;
            % initialize (sub)-base station counter
            iSubBsTot = 1;

            % fill the antenna-base station map
            for iBS = 1:length(baseStationList)
                % for each base station, we loop over all sub base stations
                % and then we loop over all antennas to fill the map with
                % antenna and base station indices

                if isa(baseStationList(iBS), 'networkElements.bs.CompositeBasestation')
                    % this is a composite base station with sub base
                    % station, which requires an additional loop ober the
                    % sub base stations

                    % reset counter for number of antennas at this base station
                    iAntSuper = 1;

                    for iSubBS = 1:length([baseStationList(iBS).subBaseStationList])
                        for iAnt = 1:length([baseStationList(iBS).subBaseStationList(iSubBS).antennaList])
                            % set map
                            obj.antennaBsMap(iAntTot, :) = [iBS, iAntSuper, iSubBsTot, iAnt, iSubBS];

                            % increase total antenna counter
                            iAntTot = iAntTot + 1;
                            % increase super base station antenna counter
                            iAntSuper = iAntSuper + 1;
                        end % for all antennas at this sub base station

                        % increase base station counter
                        iSubBsTot = iSubBsTot + 1;

                    end % for all sub base stations at this composite base station

                else % this base station has no sub base stations

                    for iAnt = 1:length([baseStationList(iBS).antennaList])
                        % set map
                        obj.antennaBsMap(iAntTot, :) = [iBS, iAnt, iSubBsTot, iAnt, 1];

                        % increase total antenna counter
                        iAntTot = iAntTot + 1;
                    end % for all antennas at this base station

                    % increase base station counter
                    iSubBsTot = iSubBsTot + 1;

                end % if this is a composite base station - additional loop over sub base stations
            end % for all base stations (composite or not)
        end

        % conversion functions
        function bsIndex = getBSindex(obj, globalAntennaIndex)
            % get base station index from global antenna index
            %
            % input:
            %   globalAntennaIndex: []integer index of antenna in array of all antennas
            %
            % output:
            %   bsIndex:    []integer index of base station

            bsIndices = obj.antennaBsMap(:, 1);
            bsIndex = bsIndices(globalAntennaIndex);
            bsIndex = reshape(bsIndex, size(globalAntennaIndex));
        end

        function subBsIndex = getSubBSindex(obj, globalAntennaIndex)
            % get sub base station index at composite base station from global antenna index
            %
            % input:
            %   globalAntennaIndex: []integer index of antenna in array of all antennas
            %
            % output:
            %   bsIndex:    []integer index of base station

            subBsIndices = obj.antennaBsMap(:, 5);
            subBsIndex = subBsIndices(globalAntennaIndex);
            subBsIndex = reshape(subBsIndex, size(globalAntennaIndex));
        end

        function globalIndices = getGlobalAntennaIndices(obj, bsIndex)
            % gets the antenna indices of all antennas belonging to the given base station
            %
            % input:
            %   bsIndex:    [1x1]integer index of the base staion, which antennas are searched
            %
            % output:
            %   globalIndices:  [nAnt x 1]integer indices of antennas belonging to this base station

            globalIndices = find(obj.antennaBsMap(:,1) == bsIndex);
        end
    end
end

