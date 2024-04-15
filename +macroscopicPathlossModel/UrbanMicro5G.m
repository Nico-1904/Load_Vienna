classdef UrbanMicro5G < macroscopicPathlossModel.PathlossModel
    %UMi Street Canyon Scenario from TR 38.901
    % Parameter Ranges
    % Frequency           0.5 - 100 GHz
    % User Antenna Height 1.5 - 22.5 m
    % BS Antenna Height    10 - 150 m
    % distance2D           10 - 5000 m

    properties
        % [1x1] logical indicator is true if model is used in Line Of Sight scenario
        isLOS
    end

    methods
        function obj = UrbanMicro5G(isLOS)
            %UMA TR 38.901 Construct an instance of this class
            %
            % input:
            %   isLOS: [1x1]logical indicator for LOS model

            obj.isLOS                   = isLOS;
        end

        function pathlossdB = getPathloss(obj,frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm)
            % calculates the pathloss in dB for a set of links
            % used in all subclasses
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % initialize output:

            nLinks                   = size(distancesInMeter2D,1);
            indoorPathLoss           = zeros(1, nLinks);

            % get LOS pathloss
            pathlossdB  = obj.getLOSpathloss(frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm);

            if ~obj.isLOS
                % get nlos pathloss
                nlosPathloss = obj.getNLOSpathloss(frequencyGHz,distancesInMeter3D,UEantennaHeightm);
                pathlossdB   =  max(nlosPathloss, pathlossdB);
            end

            % calculate total pathloss
            pathlossdB          = pathlossdB + indoorPathLoss;
        end

        function pathlossdB = getNLOSpathloss(~, frequencyGHz, distancesInMeter3D, UEantennaHeightm)
            % calculates pathloss for NLOS scenario
            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            %
            %NOTE: the NLOS pathloss should not be smaller than the LOS
            %pathloss. This is assured in modelPathloss.

            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            pathlossdB = 22.4 ...
                + 35.3*log10(distancesInMeter3D)  ...
                + 21.3*log10(frequencyGHz) ...
                - 0.3*(UEantennaHeightm-1.5);
        end

        function pathlossdB = getNLOSpathlossOptional(~, frequencyGHz, distancesInMeter3D)
            % calculates pathloss for NLOS scenario
            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            pathlossdB = 32.4 ...
                + 20*log10(frequencyGHz) ...
                + 31.9*log10(distancesInMeter3D);
        end

        function pathlossdB = getLOSpathloss(obj,frequencyGHz, distancesInMeter2D, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm)
            % calculates pathloss for LOS scenario

            % output:
            % pathlossdB:   [1 x nLinks]double LOS pathloss for all links

            environmentHeight = ones(size(frequencyGHz));
            % dBp ... distanceBreakPoint
            dBp     = obj.getdistanceBreakPoint(frequencyGHz, UEantennaHeightm, BSantennaHeightm, environmentHeight);
            % indBp ... index for 2d distance greater than distanceBreakPoint
            indBp   = distancesInMeter2D > dBp;

            %Pathloss before breakpoint PL1
            pathlossdB = 32.4 ...
                + 21*log10(distancesInMeter3D) ...
                + 20*log10(frequencyGHz);

            %additional pathloss after breakpoint PL2
            pathlossdB(indBp) = pathlossdB(indBp) ...
                + 19  * log10(distancesInMeter3D(indBp)) ...
                - 9.5 * log10(dBp(indBp).^2+(BSantennaHeightm(indBp)-UEantennaHeightm(indBp)).^2);
        end
    end
end

