classdef Rural < macroscopicPathlossModel.PathlossModel
    %RURAL pathloss for rural area
    %   according to 3GPP TS 36.942, subclause 4.5.3
    %   uses Hata model from work item UMTS900
    % This model is designed mainly for distance between UE and BS antenna
    % from few hundred meters to kilometers. It is not very accurate for
    % short distances.
    %
    % initial author: Lukas Nagel
    %
    % see also macroscopicPathlossModel.Urban

    methods
        function pathlossdB = getPathloss(~, frequencyGHz, distance2Dm, distance3Dm, ~, antennaHeightm)
            % returns the pathloss value for each link
            %
            % input:
            %   frequencyGHz:   [1 x nLinks]double frequency in GHz
            %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
            %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
            %   userHeightm:    [1 x nLinks]double user height in m
            %   antennaHeightm: [1 x nLinks]double antenna height in m
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % convert frequency to MHz
            frequencyMHz = frequencyGHz * 1e3;

            % calculate pathloss
            pathlossdB = 69.55 + 26.16*log10(frequencyMHz)...
                - 13.82*log10(antennaHeightm) ...
                + (44.9 - 6.55*log10(antennaHeightm)) .* log10(distance2Dm*1e-3)...
                - 4.78 * log10(frequencyMHz).^2 + 18.33*log10(frequencyMHz) - 40.94;

            % verifiy that the pathloss is no less than the free space pathloss
            FSPL = 20 * log10(4 * pi * distance3Dm .* frequencyGHz*1e9 / parameters.Constants.SPEED_OF_LIGHT);
            pathlossdB = max(pathlossdB, FSPL);
        end
    end
end

