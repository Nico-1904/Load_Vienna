classdef ResultsCombined < tools.HiddenHandle
    % Class for combined results.
    %   Implements functions to plot data from two or more
    %   simulations results.
    %
    % initial author: Alexander Bokor
    %
    % Example
    % combine results and show plots
    % res = ResultsCombined(result1, result2);
    % res.showAllPlots();
    %
    % See also simulation.results.ResultsSuperclass,
    % simulation.results.ResultsFull,
    % simulation.results.ResultsLite

    properties
        % results in this combination.
        % [1xnResults]simulation.results.ResultsSuperclass
        results

        % Contains full results
        % [1x1]logical indicates if full results are available
        isFullResult
    end

    methods
        function obj = ResultsCombined(result1, result2)
            % Construct an instance of ResultsCombined.
            % Creates a combined result from two results.
            %   input:
            %     result1 [1xsimulation.results.ResultsSuperclass]
            %     result2 [1xsimulation.results.ResultsSuperclass]

            % initialize results array and combine the second result
            obj.results = result1;

            % check if we have full results
            obj.isFullResult = isa(result1,'simulation.results.ResultsFull');

            obj.addResult(result2);
        end

        function addResult(obj, result)
            % Add another result to the combination
            %   input:
            %     result [1xsimulation.results.ResultsSuperclass]

            if class(obj.results(1)) ~= class(result)
                error('Only results of the same type can be combined');
            end
            obj.results = [obj.results, result];
        end

        function showAllPlots(obj)
            % Show all plots.

            obj.plotUserLiteSinrEcdf;
            obj.plotUserWidebandSinr;
            %by Nico Kabongo
            obj.plotUserLoadCell;
            %---------------------------

            % only show the plots if results support it
            if obj.isFullResult
                obj.plotUserBler;
                obj.plotUserThroughputEcdf;
                obj.plotUserEffectiveSinrEcdf;
            end
        end

        function plotUserSinrEcdf(obj)
            % Plot User Sinr ECDF.
            % Works for different amount of users but total segments must
            % be the same.

            figure();

            liteSinrDLdB = vertcat(obj.results.liteSinrDLdB);
            liteSnrDLdB  = vertcat(obj.results.liteSnrDLdB);

            tools.myEcdf(liteSinrDLdB(:));
            hold on;
            tools.myEcdf(liteSnrDLdB(:));

            xlabel('Lite SINR (dB)');
            ylabel('ECDF');
            title('User SINR');
            legend('SINR','SNR','Location', 'southeast');
        end

        function plotUserBler(obj)
            % Plot user block error rate.

            if ~obj.isFullResult()
                error('Can not plot for lite result.');
            end

            nResults = size(obj.results, 2);
            user_mean_BLER = [];
            for i = 1:nResults

                % filter BLER of users that are unscheduled in all slots
                blerValues = obj.results(i).BLER.DL;
                rowsOfUnscheduled = all(blerValues == 0,2);

                % filter zeros and exchange them with nan for unscheduled users and
                % users that are not in ROI
                userUnscheduledSlots = (blerValues == 0);
                blerValues(userUnscheduledSlots) = nan;
                user_mean_BLER = mean(blerValues,2,'omitnan');

                % assign zero BLER to unscheduled users and keep nans for
                % users that are not in ROI
                user_mean_BLER(rowsOfUnscheduled) = 0;
                user_mean_BLER = [user_mean_BLER; user_mean_BLER];
            end

            user_mean_BLER = user_mean_BLER(~isnan(user_mean_BLER));

            figure();
            stem(user_mean_BLER)
            % label figure
            xlabel('User Nr');
            ylabel('Average BLER');
            title('User BLER');
        end

        function plotUserThroughputEcdf(obj)
            % Plot empirical cumulative distribuition function of user
            % throughput in Mbit/s.

            if ~obj.isFullResult()
                error('Can not plot for lite result.');
            end

            % create new figure
            figure();

            nResults = size(obj.results, 2);
            userThroughputMBitPerSecDl = [];
            userThroughputMBitPerSecDlBestCGI = [];
            for i = 1:nResults
                userThroughputMBitPerSecDl = [userThroughputMBitPerSecDl; mean(obj.results(i).userThroughputMBitPerSec.DL,2,'omitnan')];
                userThroughputMBitPerSecDlBestCGI = [userThroughputMBitPerSecDlBestCGI; mean(obj.results(i).userThroughputMBitPerSec.DLBestCQI,2,'omitnan')];
            end

            % plot ECDF
            tools.myEcdf(userThroughputMBitPerSecDl);
            hold on;
            tools.myEcdf(userThroughputMBitPerSecDlBestCGI);

            % label figure
            xlabel('Throughput (Mbit/s)');
            ylabel('ECDF');
            title('User throughput');
            legend('DLFeedback','DLbestCQI','Location', 'southeast');
        end

        function plotUserEffectiveSinrEcdf(obj)
            % Plot effective SINR ECDF.
            % Plot empirical cumulative distribuition function of effective
            % user SINR.

            if ~obj.isFullResult()
                error('Can not plot for lite result.');
            end

            figure();

            nResults = size(obj.results, 2);
            effectiveSinr = [];
            for i = 1:nResults
                effectiveSinr = [effectiveSinr; obj.results(i).effectiveSinr.DL(:)];
            end

            B = sum((~isnan(effectiveSinr)),2);
            B(B~=0) = 1;
            C = effectiveSinr(logical(mod(B,2)),:);

            tools.myEcdf(C(:));

            xlabel('SINR (dB)');
            ylabel('ECDF');
            title('Effective user SINR');

            legend('EffectiveSINR','Location', 'southeast');
        end

        function plotUserLatencyEcdf(obj)
            % plot empirical cumulative distribution
            % function of individual packets latency for
            % all users
            %
            % initial author: Areen Shiyahin

            if ~obj.isFullResult()
                error('Can not plot for lite result.');
            end

            % get size of transmission latency cell
            cellSize = size(obj.results(1).transmissionLatency);

            % get number of users
            nUser   = cellSize(1);

            Latency = [];
            nResults = size(obj.results, 2);
            for i = 1:nResults
                % get latency values for all users
                packetsLatency = reshape(obj.results(i).transmissionLatency, [nUser*obj.results(1).params.time.numberOfChunks , 1]);
                Latency = [Latency, packetsLatency{:}];
            end

            if all(isinf(Latency)) || isempty(Latency)
                warning('Transmission latency plot will not be shown since insufficient number of packets has been transmitted, you may need to increase the simulation time or change the traffic model parameters.');
                return;
            end

            % create new figure
            figure();
            tools.myEcdf(Latency(:));

            % label figure
            xlabel('Latency(ms)')
            ylabel('ECDF')
            title('Packets latency');
        end
    end
end

