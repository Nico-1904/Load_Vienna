classdef Rural < parameters.pathlossParameters.Parameters
    % parameter class for rural environment path loss according to 3GPP TS 36.942 subclause 4.5.3
    % uses Hata model from work item UMTS900
    %
    % This model is designed mainly for distance between UE and BS antenna
    % from few hundred meters to kilometers. It is not very accurate for
    % short distances.
    %
    % Applicability range:
    %   Distance UE to BS antenna:  few hundred meters ... kilometers
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.Rural,
    % parameters.PathlossModelContainer

    methods
        function pathLossModel = createPathLossModel(~)
            % creates the macroscopic fading object that will calculate the path loss
            %
            % input:
            %   pathLossParams: [1x1]handleObject parameters.pathlossParameters.Parameters

            pathLossModel = macroscopicPathlossModel.Rural;
        end
    end
end

