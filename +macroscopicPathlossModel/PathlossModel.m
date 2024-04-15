classdef PathlossModel < tools.HiddenHandle & matlab.mixin.Heterogeneous
    % superclass for all path loss models

    methods (Abstract)
        % returns an array of pathlosses for a set of links
        %
        % input:
        %   frequencyGHz:   [1 x nLinks]double frequency in GHz
        %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
        %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
        %   userHeightm:    [1 x nLinks]double user height in m
        %   antennaHeightm: [1 x nLinks]double antenna height in m
        %
        % output:
        %   pathlossdB: [1 x nLinks]double pathloss of each link in dB
        pathlossdB = getPathloss(obj, frequencyGHz, distance2Dm, distance3Dm, userHeightm, antennaHeightm);
    end

    methods (Static)
        function distancesBreakPoint = getdistanceBreakPoint(frequencyGHz, UEantennaHeightm, BSantennaHeightm, environmentHeight)
            % sets Distance Breakpoint and Indicator for UMa Scenario
            % according to Table 7.4.1-1, Note 1

            BSantennaHeightsEffective = BSantennaHeightm - environmentHeight;
            UEantennaHeightsEffective = UEantennaHeightm - environmentHeight;
            distancesBreakPoint = ...
                4 * BSantennaHeightsEffective .* UEantennaHeightsEffective ...
                .* frequencyGHz*1e9 ./ parameters.Constants.SPEED_OF_LIGHT;
        end
    end

    methods (Static, Sealed, Access = protected)
        %NOTE: this is necessary to build arrays of PathlossModel objects
        function default_object = getDefaultScalarElement
            default_object = macroscopicPathlossModel.FreeSpace(0);
        end
    end
end

