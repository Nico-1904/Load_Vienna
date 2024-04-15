classdef LiteNoNetworkPP < simulation.postprocessing.PostprocessorSuperclass
    %LiteNoNetworkPP Postprocessor for lite simulations with no network saving
    % This postprocessor is for lite simulation, with no importance of the
    % network positions.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.results.ResultsLite

    methods (Static)
        function result = combineResults(chunkResultList)
            % combines the results of all slots to a results object
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
            % lite no network simulations
            %
            % does not save network elements
            %
            % output:
            %   networkSetup:   [1x1]double 0 - no network setup is saved

            % save no network setup-just the segments configuration to extract the SINR
            networkSetup.isNewSegment= simulationObject.chunkConfig.isNewSegment;
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

            mem = simulation.results.ResultsLite.estimateResultSize(params);
        end
    end
end

