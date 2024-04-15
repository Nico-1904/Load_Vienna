classdef EquationLoadSolver
    methods (Static)
        function result = computeSum(d, gamma, BW)
            % Calcul de la somme
            n = length(gamma); % Obtention de la taille de gamma
            result = (d * n) / (BW * log2(1 + gamma));
            result = sum(result); % Somme des éléments calculés
        end
    end
end