classdef ResultsNetwork < tools.HiddenHandle
    %RESULTSNETWORK Class for network results.
    %   Saves network results and implement ploting for them.
    %   This is part of the simulator result if network results
    %   are saved. It is used in the ResultsSuperclass.
    %
    % See also: simulation.results.ResultsSuperclass.networkResults,
    % parameters.Parameters
    %
    % initial author: Alexander Bokor

    properties
        % Building list
        % [1 x nBuildings]handleObject blockages.Building
        buildingList
        % Wall blockage list
        % [1 x nWallBlockages]handleObject blockages.WallBlockage
        wallBlockageList
        % Street system list
        % [1x1]handleObject blockages.StreetSystem
        streetSystemList
        % Basestation list
        % [1 x nBS]handleObject networkElements.bs.BaseStation
        baseStationList
        % User list
        % [1 x nUser]handleObject networkElements.ue.User
        userList
    end

    properties
        % Simulation parameters
        % [1x1]handleObject parameters.Parameters
        params
    end

    methods
        function obj = ResultsNetwork(params, networkElements)
            % Initialize with parameters and networkElements
            %
            % input:
            %   params:             [1x1]handleObject parameters.Parameters
            %   networkElements:    [1x1]struct with network elements
            %       -buildingList:      [1 x nBuildings]handleObject blockages.Building
            %       -wallBlockageList:  [1 x nWallBlockages]handleObject blockages.WallBlockage
            %       -streetSystemList:  [1x1]handleObject blockages.StreetSystem
            %       -baseStationList:   [1 x nBS]handleObject networkElements.bs.BaseStation
            %       -userList:          [1 x nUser]handleObject networkElements.ue.User

            obj.params = params;
            obj.buildingList = networkElements.buildingList;
            obj.wallBlockageList = networkElements.wallBlockageList;
            obj.streetSystemList = networkElements.streetSystemList;
            obj.baseStationList = networkElements.baseStationList;
            obj.userList = networkElements.userList;
        end

        function plotAllNetworkElements(obj, time, iFigure)
            % Plot all network elements in the lists in networkElements in
            % the ith figure.
            %
            % input:
            %   time:       [1x1]integer index of time slot to be plotted
            %   iFigure:    [1x1]integer index of the figure in which to plot in
            %           if i is empty, then a new figure is created

            % create figure if no figure is specified
            if exist('i','var')
                figure(iFigure)
            else
                figure();
            end

            % plot all network elements in the same figure
            for iChunk =1:obj.params.time.numberOfChunks
                obj.plotUsers(time+(iChunk-1)*obj.params.time.slotsPerChunk);
                hold on;
            end

            obj.plotBaseStations(time);
            hold on;
            obj.plotBuildings();
            hold on;
            obj.plotWalls();
            hold on;
            obj.plotStreets();

            % set plot axis and add labels
            hold on;
            axis("equal");
            xlabel('x');
            ylabel('y');
            zlabel('z');
        end

        function plotUsers(obj, time)
            % Plot all users positions in the given time slot to the
            % current figure.
            %
            % input:
            %   time:   [1x1]integer index of time slot to plot

            % remove previous plots if hold is off
            obj.userList(1).plot(time, tools.myColors.matlabBlue);

            % keep plotted user positions
            hold on;

            % plot all user positions
            for uu = 2:length(obj.userList)
                obj.userList(uu).plot(time, tools.myColors.matlabBlue);
                hold on;
            end % for all users

            % turn hold off
            hold off;
        end

        function handle = plotBaseStations(obj, time)
            % Plot all antenna positions in the given time slot to the
            % current figure.
            %
            % input:
            %   time:   [1x1]integer index of time slot to plot

            % remove previous plots if hold is off
            handle = obj.baseStationList(1).plotAntennas(time, tools.myColors.matlabRed);

            % keep plotted antenna positions
            hold on;

            % plot all antenna positions
            for bb = 2:length(obj.baseStationList)
                obj.baseStationList(bb).plotAntennas(time, tools.myColors.matlabRed);
            end % for all antennas

            % turn hold off
            hold off;
        end

        function plotBuildings(obj)
            % Plot all buildings to the current figure.

            % plot all buildings
            for bu = 1:length(obj.buildingList)
                obj.buildingList(bu).plot([0.9,0.9,0.9], 0.5);
                hold on;
            end % for all buildings

            % turn hold off
            hold off;
        end

        function plotWalls(obj)
            % Plot all walls in the wallBlockageList to the current figure.

            % plot all walls
            for ww = 1:length(obj.wallBlockageList)
                obj.wallBlockageList(ww).plotWall([0.95,0.95,0.95], 1);
                hold on;
            end % for all walls

            % turn hold off
            hold off;
        end

        function plotStreets(obj)
            % Plot all streets in the streetSystemList to the current
            % figure.

            % plot all streets
            for ii = 1:length(obj.streetSystemList)
                obj.streetSystemList(ii).plot();
                hold on;
            end % for all streets

            % turn hold off
            hold on;
        end

        function plotBuildingsFloorPlan(obj)
            % Plot the building floor plan for all buildings.

            % plot floor plan for all buildings
            for bb = 1:length(obj.buildingList)
                obj.buildingList(bb).plotFloorPlan(tools.myColors.black);
                hold on;
            end % for all buildings

            % turn hold off
            hold off;
        end
    end

    methods(Static)
        function mem = estimateResultSize(params)
            % Estimate result size.
            %
            % Estimates how many bytes will be needed to
            % save network results for the given parameters. Is called by the
            % postprocessor estimateMemory method.
            %
            % input:
            %   params: [1x1]parameters.Parameters
            % output:
            %   mem: [1x1]double estimated result size in bytes
            %
            % See also:
            % simulation.postprocessing.PostprocessorSuperclass.estimateResultSize
            %
            % initial author: Alexander Bokor

            mem = 0;

            nSlotsTotal = params.time.nSlotsTotal;

            % number of users
            nUsers = 0;
            for upa = params.userParameters.values
                nUsers = nUsers + upa{1}.getEstimatedUserCount(params);
            end

            % is in roi
            mem = mem + nSlotsTotal * nUsers;

            % position list
            mem = mem + nSlotsTotal * 3;

            % size of double
            mem = mem * 8;
        end
    end
end

