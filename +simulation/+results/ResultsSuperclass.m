classdef (Abstract) ResultsSuperclass < tools.HiddenHandle
    %RESULTSSUPERCLASS Abstract superclass for all results.
    % Stores results that are obtained for each type of simulation,
    % like preliminary SNR and SINR values and provides functions to plot
    % them. Building the results and selecting which parts are saved is
    % handled by the postprocessors in the package simulation.postprocessing.
    % The class supports to store an optional network results object.
    %
    % inital author: Lukas Nagel
    % extended by: Alexander Bokor, clean up results folder, check results
    %
    % See also simulation.postprocessing.PostprocessorSuperclass,
    % simulation.results.ResultsLite,
    % simulation.results.ResultsFull,
    % simulation.results.ResultsNetwork,
    % parameters.Parameters

    properties
        % Simulation parameters
        % [1x1]handleObject parameters.Parameters
        % Initialized to 0 if not set.
        params = 0;

        % Network results (optional)
        % [1x1] simulation.results.ResultsNetwork
        % Object with network results and network plotting functions.
        % If not set: Contains string indicating that network was not saved.
        networkResults = "no network results saved";

        % new segment indicator for all slots
        % [1 x nSlotsTotal]logical indicates if slot is first in a segment
        % true: this slot is the first one in a new segment, the macroscale parameters have to be updatet
        % false: this slot is in the same segment as the previous slot
        isNewSegment

        % Lite Signal to Noise Ratio in dB
        % [nUser x nSlotsTotal]double uplink SNR in dB
        %
        % This SNR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen small scale fading channel
        % realization.
        %
        % see also simulation.ChunkSimulation.liteSnrDLdB
        liteSnrDLdB

        % Lite Signal to Noise Ratio in dB
        % [nUser x nSlotsTotal]double downlink SNR in dB
        %
        % This SNR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen small scale fading channel
        % realization.
        % A random user in each cell is chosen as interfering user.
        %
        % see also simulation.ChunkSimulation.liteSnrULdB
        liteSnrULdB

        % Lite Signal to Interference and Noise Ratio in dB
        % [nUser x nSlotsTotal]double downlink lite SINR in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        %
        % see also simulation.ChunkSimulation.liteSinrDLdB
        liteSinrDLdB

        % Lite Signal to Interference and Noise Ratio in dB
        % [nUser x nSlotsTotal]double uplink lite SINR in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        % A random user in each cell is chosen as interfering user.
        %
        % see also simulation.ChunkSimulation.liteSinrULdB
        liteSinrULdB

        % wideband SINR in dB
        % [nUsers x nSegmentsTotal]double wideband SINR in dB
        % The wideband SINR considers all macroscopic fading parameters,
        % but no small scale fading, no precoding, no scheduling.
        %
        % see also cellManagement.CellAssociation.setCellAssociationTable
        widebandSinrdB
        
        %by Nico Kabongo
        LoadCell
        %--------------

        % cell association table
        % [nUsers x nSegmentsTotal]integer index of base station this user is associated to
        %
        % Example: the first user is attached to the first base station in
        % the first segment and to the second base station from the second
        % segment onwards. Then, the first line of the userToBSassignment
        % will be [1 2 2 2 2 2], assuming there are 5 segments in a chunk.
        %
        % see also cellManagement.CellAssociation.userToBSassignment,
        % tools.AntennaBsMapper.getBSindex
        userToBSassignment

        % Elapsed time during simulation (in seconds)
        % [1x1] double
        simulationTime = NaN;
    end

    methods (Abstract)
        % Show all plots that can be produced.
        showAllPlots(obj)
    end

    methods (Abstract, Static)
        % Estimate result size.
        %
        % Estimates how many bytes will be needed to
        % save results for the given parameters.
        %
        % input:
        %   params: [1x1]parameters.Parameters
        % output:
        %   mem: [1x1]double estimated result size in bytes
        %
        % see also:
        % simulation.postprocessing.PostprocessorSuperclass.estimateResultSize,
        % simulation.results.ResultsNetwork.estimateResultSize,
        %
        % initial author: Alexander Bokor
        mem = estimateResultSize(params)
    end

    methods (Access=protected)
        function isSaved = isNetworkSaved(obj)
            % Check if network results are saved.
            %
            % output:
            %   isSaved: [1x1]logical

            isSaved = isa(obj.networkResults, "simulation.results.ResultsNetwork");
        end

        function nUsers = getUsers(obj)
            % Number of users from the parameters.
            %
            % output:
            %   nUsers: [1x1]double number of users

            nUsers = 0;
            for upa = obj.params.userParameters.values
                nUsers = nUsers + length(upa{1}.indices);
            end
        end
    end

    methods
        function plotUserLiteSinrEcdf(obj)
            % Plot empirical cumulative distribution function of user liteSINR.
            figure();

            leg = [];
            if ~isempty(obj.liteSnrDLdB)
                tools.myEcdf(obj.liteSinrDLdB(:));
                hold on;
                tools.myEcdf(obj.liteSnrDLdB(:));
                hold on;
                leg = [leg;"DL SINR";"DL SNR"];
            end
            if ~isempty(obj.liteSnrULdB)
                tools.myEcdf(obj.liteSinrULdB(:));
                hold on;
                tools.myEcdf(obj.liteSnrULdB(:));
                leg = [leg;"UL SINR";"UL SNR"];
            end

            xlabel('lite SINR in dB');
            ylabel('ECDF');
            title('user lite SINR');
            legend(leg, 'Location', 'northwest');
        end

        function plotUserWidebandSinr(obj)
            % Plot empirical cumulative distribution function of user liteSINR.
            figure();

            if ~isempty(obj.widebandSinrdB)
                tools.myEcdf(obj.widebandSinrdB(:));
                hold on;
            end

            xlabel('wideband SINR in dB');
            ylabel('ECDF');
            title('user wideband SINR');
        end
        
        %by Nico Kabongo
        function plotUserLoadCell(obj)
            % Plot empirical cumulative distribution function of user liteSINR.
            figure();

            if ~isempty(obj.LoadCell)
                tools.myEcdf(obj.LoadCell(:));
                hold on;
            end

            xlabel('Load ');
            ylabel('ECDF');
            title('Load cell (by Nico KABONGO)');
        end
        %-------------------------------

        function plotScene(obj, time, i)
            % Plot scene at time slot time in figure i.
            %
            % This is a convenience function, which calls the corresponding
            % plot function in the networkResults object. If no network
            % results were saved an error is thrown.
            %
            % input:
            %   time:   [1x1]integer index of time slot to be plotted
            %   i:      [1x1]integer index of the figure in which top lot in.
            %           if i is empty a new figure is created

            % if network results were saved, plot the initial scene
            if ~obj.isNetworkSaved()
                msg = "Network elements not saved in this result. Plot not available.";
                error(msg)
            end

            if exist('i','var')
                hold off
                obj.networkResults.plotAllNetworkElements(time,i);
            else
                obj.networkResults.plotAllNetworkElements(time);
            end
        end
    end

    methods(Static)
        function mem = estimateSnrResultSize(params)
            % Estimate memory demand for SNR and SINR results.
            %
            % Estimates how many memory will be approximatly needed to
            % save SNR and SINR results for the given parameters.
            %
            % Is called by estimateMemory.
            %
            % input:
            %   params: [1x1]parameters.Parameters
            % output:
            %   mem: [1x1]double estimated memory usage in bytes
            %
            % initial author: Alexander Bokor
            %
            % See also:
            % simulation.postprocessing.PostprocessorSuperclass.estimateResultSize,
            % simulation.results.ResultsNetwork.estimateResultSize

            mem = 0;

            % number of users
            nUsers = 0;
            for upa = params.userParameters.values
                nUsers = nUsers + upa{1}.getEstimatedUserCount(params);
            end

            % assume the worst case segment number
            nSegmentsTotal = params.time.nSlotsTotal;

            % add SNR and SINR
            mem = mem + nUsers * nSegmentsTotal;

            % multiply with size of double
            mem = mem * 8;
        end
    end
end

