classdef LiteWithNetworkPP < simulation.postprocessing.PostprocessorSuperclass
    %LiteWithNetworkPP postprocessor for lite simulation with network saved
    % This postprocessor is for simulations where the influence of
    % scheduler, LQM and LPM are not of interest, but the network geometry
    % is.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.results.ResultsLite,
    % simulation.results.ResultsLite

    methods (Static)
        function result = combineResults(chunkResultList)
            % combines the results of all slots to a results object
            %
            % saves also the network elements
            %
            % input:
            %   chunkResultList: [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   result: [1x1]handleObject simulation.results.ResultsLite

            % create results object
            result = simulation.results.ResultsLite();

            % save simulation parameters
            result.params = chunkResultList(1).params;

            % extract network elements from all chunks and save it to
            % network results
            networkElements = simulation.postprocessing.PostprocessorSuperclass.extractNetworkElements(chunkResultList);
            result.networkResults = simulation.results.ResultsNetwork(result.params, networkElements);

            % save preliminary SNR and SINR
            [result.liteSinrDLdB, result.liteSinrULdB, result.liteSnrDLdB, result.liteSnrULdB] ...
                = simulation.postprocessing.PostprocessorSuperclass.extractLiteSINRandSNR(chunkResultList);
            % extract wideband SINR
            result.widebandSinrdB = simulation.postprocessing.PostprocessorSuperclass.extractWidebandSinr(chunkResultList);
            
            %by Nico Kabongo
            result.LoadCell = simulation.postprocessing.PostprocessorSuperclass.extractLoadCell(chunkResultList);
            %-------------

            % extract isNewSegment
            result.isNewSegment = simulation.postprocessing.PostprocessorSuperclass.extractIsNewSegment(chunkResultList);
            % extract assigned base stations
            result.userToBSassignment = simulation.postprocessing.PostprocessorSuperclass.extractUserToBSassignment(chunkResultList);
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
            % See also: simulation.results.ResultsLite.estimateResultSize,
            % simulation.results.ResultsNetwork.estimateResultSize

            mem = simulation.results.ResultsLite.estimateResultSize(params);
            mem = mem + simulation.results.ResultsNetwork.estimateResultSize(params);
        end
    end
end

