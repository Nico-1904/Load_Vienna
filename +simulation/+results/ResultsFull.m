classdef ResultsFull < simulation.results.ResultsSuperclass
    %RESULTSFULL Class for full results.
    % This result saves all general results plus additional results
    % specified in parameters.Parameters.save.
    %
    % initial author: Lukas Nagel
    % extended by: Alexander Bokor, clean up results folder, check results
    %
    % See also simulation.results.ResultsSuperclass,
    % simulation.results.ResultsNetwork, simulation.postprocessing,
    % simulation.postprocessing.FullPP, parameters.SaveObject

    properties
        % User throughput in bit
        % [1x1]struct with user throughput
        %   -DL:        [nUserROI x nSlotsValidTotal]double downlink user throughput in bit
        %   -DLBestCQI:	[nUserROI x nSlotsValidTotal]double maximum possible downlink throughput
        userThroughputBit
        
        %by Nico Kabongo
        debit
        
        userThroughputBit1
        %----------------

        % Effective SINR from LPM
        % [1x1]struct with effective SINR
        %   -DL:    [nUser x nSlotsTotal]double downlink effective SINR
        % The effective SINR is the SINR chosen as transmit SINR by the
        % link performance model.
        effectiveSinr

        % Block error rate from link performance model
        % [1x1]struct with BLER
        %   -DL:    [nUser x nSlotsTotal]double downlink BLER
        BLER

        % packets transmission latency
        % [nUser x nChunk]cell
        % [1 x nPackets]double transmission latency
        transmissionLatency

        % additional - Additional results
        % [1x1]struct with additional results as field
        %   -losMap:          [nAntennas x nUsers x nSegmentsTotal]logical table indicating links blocked by walls
        %   -isIndoor:        [nUser x nSlotsTotal]logical indicator for indoor users
        %   -antennaBsMapper: [nAntenna x 2]integer with antenna index in 1st column and base station index in 2nd column
        %   -pathlossTable:   [nAntenna x nUser x nSegmentTotal]double pathloss for all possible links in dB
        %   -feedback:           [1x1]struct with feedback
        %       -DL:    [nUser x nSlotsTotal]struct downlink feedback
        %   -userScheduling:	[1x1]struct with scheduler signaling
        %       -DL:    [nUser x nSlotsTotal]struct downlink scheduler signaling
        %
        % see also parameters.SaveObject
        additional
    end

    properties (Dependent)
        % User throughput in Mbit/s
        % [1x1]struct with user throughput
        %   -DL:        [nActiveUserROI x nSlotsValidTotal]double downlink user throughput in Mbit/s
        %   -DLBestCQI: [nActiveUserROI x nSlotsValidTotal]double downlink best CQI user throughput in Mbit/s
        userThroughputMBitPerSec
        
        %by Nico Kabongo
        debitMBitPerSec
        
        userThroughputMBitPerSec1
        %--------------------
    end

    methods
        function userThroughputMBitPerSec = get.userThroughputMBitPerSec(obj)
            % Getter function for user throughput.
            %
            % output:
            %   userThroughputBit:  [1x1]struct with user throughput
            %       -DL:	[nActiveUser x nSlotsValidTotal]double downlink user throughput in Mbit/s

            % calculate total user throughput
            userThroughputMBitPerSec.DL = obj.userThroughputBit.DL / 1e6 / obj.params.time.slotDuration;
            userThroughputMBitPerSec.DLBestCQI = obj.userThroughputBit.DLBestCQI / 1e6 / obj.params.time.slotDuration;
            

            % consider the latency of users in ROI only
            Latency        = obj.transmissionLatency;
            nUsers         = size(obj.networkResults.userList,2);
            isInRoi        = reshape([obj.networkResults.userList.isInROI], nUsers, []);
            isInRoi        = isInRoi(:,1);
            usersToDiscard = find(~isInRoi);

            % delete latency results of users that are not in ROI
            if usersToDiscard
                Latency(usersToDiscard,:)= [];
            end

            % check which users are inactive during all the simulation
            [row,~] = find(cellfun(@isempty, Latency));
            if row
                rowsToCheck = unique(row);
                numberOfRows = size(rowsToCheck,1);
                logicalArray = false(numberOfRows,1);

                for ii = 1:numberOfRows
                    logicalArray(ii) = isempty(cell2mat(Latency(rowsToCheck(ii),:)));
                end

                rowsToDiscard = rowsToCheck(logicalArray);

                % delete throughput results for inactive users
                if  rowsToDiscard
                    userThroughputMBitPerSec.DL(rowsToDiscard,:) = [];
                    userThroughputMBitPerSec.DLBestCQI(rowsToDiscard,:) = [];
                    
                end
            end
        end
        
        %by Nico Kabongo
        function debitMBitPerSec = get.debitMBitPerSec(obj)

            debitMBitPerSec = obj.debit / 1e6 / obj.params.time.slotDuration;

            % consider the latency of users in ROI only
            Latency        = obj.transmissionLatency;
            nUsers         = size(obj.networkResults.userList,2);
            isInRoi        = reshape([obj.networkResults.userList.isInROI], nUsers, []);
            isInRoi        = isInRoi(:,1);
            usersToDiscard = find(~isInRoi);

            % delete latency results of users that are not in ROI
            if usersToDiscard
                Latency(usersToDiscard,:)= [];
                %debitMBitPerSec(usersToDiscard) = [];
            end

            % check which users are inactive during all the simulation
            [row,~] = find(cellfun(@isempty, Latency));
            if row
                rowsToCheck = unique(row);
                numberOfRows = size(rowsToCheck,1);
                logicalArray = false(numberOfRows,1);

                for ii = 1:numberOfRows
                    logicalArray(ii) = isempty(cell2mat(Latency(rowsToCheck(ii),:)));
                end

                rowsToDiscard = rowsToCheck(logicalArray);

                % delete throughput results for inactive users
                if  rowsToDiscard
                    debitMBitPerSec(rowsToDiscard) = [];
                end
            end
        end
        
        function userThroughputMBitPerSec1 = get.userThroughputMBitPerSec1(obj)
            
            userThroughputMBitPerSec1.DL = obj.userThroughputBit1.DL / 1e6 / obj.params.time.slotDuration;
            userThroughputMBitPerSec1.DLBestCQI = obj.userThroughputBit1.DLBestCQI / 1e6 / obj.params.time.slotDuration;

            % consider the latency of users in ROI only
            Latency        = obj.transmissionLatency;
            nUsers         = size(obj.networkResults.userList,2);
            isInRoi        = reshape([obj.networkResults.userList.isInROI], nUsers, []);
            isInRoi        = isInRoi(:,1);
            usersToDiscard = find(~isInRoi);

            % delete latency results of users that are not in ROI
            if usersToDiscard
                Latency(usersToDiscard,:)= [];
            end

            % check which users are inactive during all the simulation
            [row,~] = find(cellfun(@isempty, Latency));
            if row
                rowsToCheck = unique(row);
                numberOfRows = size(rowsToCheck,1);
                logicalArray = false(numberOfRows,1);

                for ii = 1:numberOfRows
                    logicalArray(ii) = isempty(cell2mat(Latency(rowsToCheck(ii),:)));
                end

                rowsToDiscard = rowsToCheck(logicalArray);

                % delete throughput results for inactive users
                if  rowsToDiscard
                    
                    userThroughputMBitPerSec1.DL(rowsToDiscard,:) = [];
                    userThroughputMBitPerSec1.DLBestCQI(rowsToDiscard,:) = [];
                end
            end
        end
        %--------------------

        function showAllPlots(obj)
            % Show all plots that can be produced.

            % if network results were saved, plot the initial scene
            if obj.isNetworkSaved()
                obj.networkResults.plotAllNetworkElements(1);
            end

            obj.plotUserThroughputEcdf;
            obj.plotUserLiteSinrEcdf;
            obj.plotUserEffectiveSinrEcdf;
            obj.plotUserBler;
            obj.plotUserWidebandSinr;
            %by Nico Kabongo
            obj.plotUserLoadCell;
            obj.plotUserDebit;
            obj.plotUserThroughput1Ecdf
            %--------------------

            % plot latency ECDF if any user has a traffic model other than full buffer
            for iKey = obj.params.userParameters.keys
                userParam = obj.params.userParameters(iKey{1});
                if userParam.trafficModelType ~= parameters.setting.TrafficModelType.FullBuffer
                    obj.plotUserLatencyEcdf;
                    break;
                end
            end
        end

        function plotUserBler(obj)
            % Plot user block error rate.

            % filter BLER of users that are unscheduled in all slots
            blerValues = obj.BLER.DL;
            rowsOfUnscheduled = all(blerValues == 0,2);

            % filter zeros and exchange them with nan for unscheduled users and
            % users that are not in ROI
            userUnscheduledSlots = (blerValues == 0);
            blerValues(userUnscheduledSlots) = nan;
            user_mean_BLER = mean(blerValues,2,'omitnan');

            % assign zero BLER to unscheduled users and keep nans for
            % users that are not in ROI
            user_mean_BLER(rowsOfUnscheduled) = 0;
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

            if ~isempty(obj.userThroughputMBitPerSec.DL)

                % create new figure
                figure();

                % plot ECDF
                tools.myEcdf(mean(obj.userThroughputMBitPerSec.DL,2,'omitnan'));
                hold on;
                tools.myEcdf(mean(obj.userThroughputMBitPerSec.DLBestCQI,2,'omitnan'));

                % label figure
                xlabel('Throughput (Mbit/s)');
                ylabel('ECDF');
                title('User throughput');
                legend('DLFeedback','DLbestCQI', 'Location', 'southeast');
            else
                warning('Throughput results will not be shown since there are no active users.');
                return;
            end
        end
        
        %By Nico Kabongo
        function plotUserDebit(obj)

            if ~isempty(obj.debitMBitPerSec)

                % create new figure
                figure();

                % plot ECDF
                tools.myEcdf(mean(obj.debitMBitPerSec,2,'omitnan'));
                %hold on;
                %tools.myEcdf(mean(obj.userThroughputMBitPerSec.DLBestCQI,2,'omitnan'));

                % label figure
                xlabel('Debit (Mbit/s)');
                ylabel('ECDF');
                title('Debit utilisateur');
                legend('Debit avant decalage', 'Location', 'southeast');
            else
                warning('Throughput results will not be shown since there are no active users.');
                return;
            end
        end
        
        function plotUserThroughput1Ecdf(obj)
            % Plot empirical cumulative distribuition function of user
            % throughput in Mbit/s.

            if ~isempty(obj.userThroughputMBitPerSec1.DL)

                % create new figure
                figure();

                % plot ECDF
                tools.myEcdf(mean(obj.userThroughputMBitPerSec.DLBestCQI,2,'omitnan'));
                hold on;
                tools.myEcdf(mean(obj.userThroughputMBitPerSec1.DLBestCQI,2,'omitnan'));

                % label figure
                xlabel('Debit (Mbit/s)');
                ylabel('ECDF');
                title('Debit Utilisateur');
                legend('Debit avant decalage','Debit après decalage', 'Location', 'southeast');
            else
                warning('Throughput results will not be shown since there are no active users.');
                return;
            end
        end
        %-------------------

        function plotUserEffectiveSinrEcdf(obj)
            % Plot effective SINR ECDF.
            % Plot empirical cumulative distribuition function of effective
            % user SINR.
            figure();

            % we use the effectiveSinr and logical indexing to get rid of
            % unwanted NaNs. If a user is not in the region of interest
            % (not connected to a BS) or unscheduled, it has all NaNs
            B = sum((~isnan(obj.effectiveSinr.DL)),2);
            B(B~=0)=1;
            C=obj.effectiveSinr.DL(logical(mod(B,2)),:);

            tools.myEcdf(C(:));

            xlabel('SINR (dB)');
            ylabel('ECDF');
            title('Effective user SINR');

            legend('EffectiveSINR','Location', 'southeast');
        end

        function plotUserLatencyEcdf(obj)
            % plot empirical cumulative distribution
            % function of packets latency for all users
            %
            % initial author: Areen Shiyahin

            % get size of latency cell
            cellSize = size(obj.transmissionLatency);

            % get number of users
            nUser = cellSize(1);

            % get latency values for all users
            packetsLatency =  reshape (obj.transmissionLatency, [nUser*obj.params.time.numberOfChunks , 1]);
            Latency = [packetsLatency{:}];

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
    
    %It is a plot create by Nico Kabongo
    function plotUserCellIdLoad(obj)
       
 if ~isempty(obj.userThroughputMBitPerSec.DL)

                % create new figure
                figure();

                % plot ECDF
                tools.myEcdf(mean(obj.userThroughputMBitPerSec.DL,2,'omitnan'));
                hold on;
                tools.myEcdf(mean(obj.userThroughputMBitPerSec.DLBestCQI,2,'omitnan'));

            xlabel('ID Cellule');
            ylabel('Charge Cellule');
            title('Repartion de la charge');

            legend('CellIdLoad', 'dd', 'Location', 'southeast');
                        else
                warning('Throughput results will not be shown since there are no active users.');
                return;

    end
    end
    end

    methods (Static)
        function mem = estimateResultSize(params)
            % Estimate result size for full results.
            %
            % Estimates how many bytes will be needed to
            % save results for the given parameters.
            %
            % This function does NOT calculate memory used by the
            % networkResults object.
            %
            % input:
            %   params: [1x1]parameters.Parameters
            % output:
            %   mem: [1x1]double estimated result size in bytes
            %
            % See also:
            % simulation.postprocessing.PostprocessorSuperclass.estimateResultSize,
            % simulation.results.ResultsNetwork.estimateResultSize
            %
            % initial author: Alexander Bokor

            mem = 0;

            % number of users
            nUsers = 0;
            for upa = params.userParameters.values
                nUsers = nUsers + upa{1}.getEstimatedUserCount(params);
            end

            % number of bs
            nBs = 0;
            for upa = params.baseStationParameters.values
                nBs = nBs + upa{1}.getEstimatedBaseStationCount(params);
            end
            nAnt = nBs;

            % get total slots and valid total slots
            % see also simulation.result.PostProcessorSuperclass.extractUserThroughput
            nSlotsTotal = params.time.nSlotsTotal;
            nSlotsPerChunk = params.time.slotsPerChunk;
            nChunks = params.time.numberOfChunks;
            feedbackDelay = params.time.feedbackDelay;
            nValidSlotsTotal = (nSlotsPerChunk - feedbackDelay) * nChunks;

            % we assume the worst case segment size
            nSegmentsTotal = nSlotsTotal;

            % assume all users in ROI
            nUsersRoi = nUsers;

            % effective sinr
            mem = mem + nUsers * nSlotsTotal * 2;

            % assigned bs
            mem = mem + nUsers * nSlotsTotal * 2;

            % BLER
            mem = mem + nUsers * nSlotsTotal * 2;

            % user throughput
            mem = mem + nUsersRoi * nValidSlotsTotal * 2;

            % check additional results

            if params.save.losMap
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.isIndoor
                mem = mem + nUsers * nSlotsTotal;
            end

            if params.save.antennaBsMapper
                mem = mem + nAnt * 2;
            end

            if params.save.pathlossTable
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.macroscopicFading
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.wallLoss
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.shadowFading
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.antennaGain
                mem = mem + nAnt * nUsers * nSegmentsTotal;
            end

            if params.save.feedback
                mem = mem + nUsers * nSlotsTotal;
            end

            if params.save.userScheduling
                mem = mem + nUsers * nSlotsTotal;
            end

            % multiply with size of double
            mem = mem * 8;

            % add size from superclass SNR results
            mem = mem + simulation.results.ResultsSuperclass.estimateSnrResultSize(params);
        end
    end
end

