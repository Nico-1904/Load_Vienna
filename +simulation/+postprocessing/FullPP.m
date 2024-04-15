classdef FullPP < simulation.postprocessing.PostprocessorSuperclass
    %FULLPP postprocessor for full results
    %   This postprocessor saves the general results plus the additional
    %   results indicated by the SaveObject.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.results.ResultsFull

    methods (Static)
        function result = combineResults(chunkResultList)
            % combine results from all chunks
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   result: [1x1]handleObject simulation.results.ResultsFull

            % create results object
            result = simulation.results.ResultsFull;

            % extract simulation parameters
            result.params = chunkResultList(1).params;

            % extract network elements from all chunks and save it to
            % network results
            networkElements = simulation.postprocessing.PostprocessorSuperclass.extractNetworkElements(chunkResultList);
            result.networkResults = simulation.results.ResultsNetwork(result.params, networkElements);

            % extract lite SNR and SINR
            [result.liteSinrDLdB, result.liteSinrULdB, result.liteSnrDLdB, result.liteSnrULdB]...
                = simulation.postprocessing.PostprocessorSuperclass.extractLiteSINRandSNR(chunkResultList);
            % extract wideband SINR
            result.widebandSinrdB           = simulation.postprocessing.PostprocessorSuperclass.extractWidebandSinr(chunkResultList);
            
            %by Nico Kabongo
            result.LoadCell                 = simulation.postprocessing.PostprocessorSuperclass.extractLoadCell(chunkResultList);
            result.debit                    = simulation.postprocessing.PostprocessorSuperclass.extractUserDebit(chunkResultList);
            result.userThroughputBit1        = simulation.postprocessing.PostprocessorSuperclass.extractUserThroughput1(chunkResultList);
            %-------------

            % extract isNewSegment
            result.isNewSegment             = simulation.postprocessing.PostprocessorSuperclass.extractIsNewSegment(chunkResultList);
            % calculate user throughput
            result.userThroughputBit        = simulation.postprocessing.PostprocessorSuperclass.extractUserThroughput(chunkResultList);
            % extract effective SINR
            result.effectiveSinr            = simulation.postprocessing.PostprocessorSuperclass.extractEffectiveSinr(chunkResultList);
            % extract assigned base stations
            result.userToBSassignment       = simulation.postprocessing.PostprocessorSuperclass.extractUserToBSassignment(chunkResultList);
            % extract additional results indicated in parameters.Parameters.save
            result.additional               = simulation.postprocessing.PostprocessorSuperclass.extractAdditionalResults(chunkResultList);
            result.BLER                     = simulation.postprocessing.PostprocessorSuperclass.extractBLER(chunkResultList);
            % extract transmission latency of packets
            result.transmissionLatency      = simulation.postprocessing.PostprocessorSuperclass.extractTransmissionLatency(chunkResultList);
        end

        function networkSetup = collectNetworkSetup(simulationObject)
            % collect the network setup for results
            %
            % input:
            %   simulationObject:   [1x1]handleObject simulation.ChunkSimulation
            %
            % output:
            %   networkSetup:   [1x1]struct with network geometry information
            %       -buildingList:      [1 x nBuildings]handleObject blockages.Building
            %       -wallBlockageList:  [1 x nWalls]handleObject blockages.WallBlockage
            %       -userList:          [1 x nUser]handleObject networkElements.ue.User
            %       -baseStationList:   [1 x nBS]handleObject networkElements.bs.BaseStation
            %       -streetSystemList:	[1 x nStreets]handleObject blockages.StreetSystem
            %       -isNewSegment:      [1 x nSlots]logical indicator if slot is first in new segment
            %
            % see also simulation.ChunkConfig

            networkSetup = simulation.postprocessing.PostprocessorSuperclass.collectFullNetworkSetup(simulationObject);
        end

        function mem = estimateResultSize(params)
            % Estimate size of simulation results in bytes
            % input:
            %   params: [1x1]parameters.Parameters
            % output:
            %   mem:    [1x1]double estimated result size in bytes
            %
            % inital author: Alexander Bokor
            %
            % See also: simulation.results.ResultsFull.estimateResultSize,
            % simulation.results.ResultsNetwork.estimateResultSize

            mem = simulation.results.ResultsFull.estimateResultSize(params);
            mem = mem + simulation.results.ResultsNetwork.estimateResultSize(params);
        end
    end
end

