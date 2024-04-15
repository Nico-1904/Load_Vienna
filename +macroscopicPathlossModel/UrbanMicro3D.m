classdef UrbanMicro3D < macroscopicPathlossModel.Super3D
    %pathloss for 3D Urban microcell according to 3GPP TR 36.873 V12.0.0
    % This pathloss model is applicable for frequencies ranging from
    % 2 GHz to 6 GHz.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macrosscopicPathlossModel.UrbanMicro3D

    methods
        function obj = UrbanMicro3D(isLOS, isIndoor)
            % UMi constructor creates a TR 36.873 object

            % call superclass constructor
            obj = obj@macroscopicPathlossModel.Super3D(isLOS, isIndoor);
        end

        function pathlossdB = getPathloss(obj,frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm)
            % calculates the pathloss in dB for a set of links
            % used in all subclasses
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % initialize output:

            nLinks = size(distancesInMeter2D, 2);

            if obj.isIndoor
                distanceIndoor           = 25 * rand(1,nLinks);
                indoorPathLoss           = obj.getIndoorPathLoss(distanceIndoor);
            else
                distanceIndoor           = zeros(1, nLinks);
                indoorPathLoss           = zeros(1, nLinks);
            end

            distanceOutdoor          = distancesInMeter2D - distanceIndoor;
            evironmentHeightm        = ones(1, nLinks);

            % get LOS pathloss
            pathlossdB = obj.getLOSpathloss(frequencyGHz,distanceOutdoor,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm,evironmentHeightm);

            if ~obj.isLOS
                % get nlos pathloss
                nlosPathloss = obj.getNLOSpathloss(frequencyGHz,distancesInMeter3D,UEantennaHeightm);
                pathlossdB   = max(nlosPathloss, pathlossdB);
            end

            % calculate total pathloss
            pathlossdB          = pathlossdB + indoorPathLoss;
        end

        function NLOSpathloss = getNLOSpathloss(~,distancesInMeter3D,frequencyGHz,UEantennaHeightm)
            % calculates pathloss for NLOS scenario
            % according to 3GPP TR 36.873 V12.0.0 Table 7.2-1

            NLOSpathloss = 36.7*log10(distancesInMeter3D) + 22.7 ...
                + 26*log10(frequencyGHz) - 0.3 * (UEantennaHeightm - 1.5);
        end
    end
end

