classdef ResultsLite < simulation.results.ResultsSuperclass
    %RESULTSLITE Class for lite results.
    %   Saves the preliminary SNR and SINR and provides plotting.
    %   Optionally also network elements can be saved and plotted. Lite
    %   results are produced by lite post processors.
    %
    % initial author: Lukas Nagel
    % extended by: Alexander Bokor, clean up results folder
    %
    % See also simulation.results.ResultsSuperclass,
    % simulation.results.ResultsNetwork,
    % simulation.postprocessing
    % simulation.postprocessing.LiteNoNetworkPP,
    % simulation.postprocessing.LiteWithNetworkPP,

    methods
        function showAllPlots(obj)
            % Show all plots that can be produced.

            % if network results were saved, plot the initial scene
            if obj.isNetworkSaved
                obj.networkResults.plotAllNetworkElements(1);
            end

            obj.plotUserLiteSinrEcdf;
            obj.plotUserWidebandSinr;
            %by Nico Kabongo
            obj.plotUserLoadCell;
            %-------------------------
        end
    end

    methods(Static)
        function mem = estimateResultSize(params)
            % Estimate result size for lite result.
            %
            % Estimates how many bytes will be needed to
            % save results for the given parameters.
            %
            % This function does NOT calculate result size used by the
            % networkResults object.
            %
            % input:
            %   params: [1x1]parameters.Parameters
            % output:
            %   mem: [1x1]double estimated result size in bytes
            %
            % See also:
            % simulation.postprocessing.LiteNoNetwork.estimateResultSize,
            % simulation.postprocessing.LiteWithNetwork.estimateResultSize,
            % simulation.results.ResultsNetwork.estimateResultSize,
            %
            % initial author: Alexander Bokor

            mem = simulation.results.ResultsLite.estimateSnrResultSize(params);
        end
    end
end

