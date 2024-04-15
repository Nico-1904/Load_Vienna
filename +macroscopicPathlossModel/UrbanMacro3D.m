classdef UrbanMacro3D < macroscopicPathlossModel.Super3D
    %UMA3D pathloss for UMa3D scenario according to 3GPP TR 36.873 V12.0.0
    % Pathloss for urban macro cell with high UE density.
    % This pathloss model is applicable for frequencies ranging from
    % 2 GHz ... 6 GHz.
    %
    % UMa3D: 3D Urban Macro cell
    %
    % initial author: Agnes Fastenbauer

    properties
        % width of streets in meter
        % [1x1]double street width in meter
        % Only necessary for NLOS scenario.
        streetWidthm

        % average building height in meter
        % [1x1]double average building height in meter
        % Only necessary for outdoor to indoor scenario.
        averageBuildingHeightm
    end

    methods
        function obj = UrbanMacro3D(streetWidth, averageBuildingHeight, isLOS, isIndoors)
            % UMa constructor creates a TR 36.873 object and appends specific parameters
            %
            % input:
            %   params: [1x1]handleObject parameters.Parameters

            % call superclass constructor
            obj = obj@macroscopicPathlossModel.Super3D(isLOS, isIndoors);

            % set UMa specific parameters
            obj.streetWidthm            = streetWidth;
            obj.averageBuildingHeightm	= averageBuildingHeight;
        end

        function pathlossdB = getPathloss(obj,frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm)
            % calculates the pathloss in dB for a set of links
            % used in all subclasses
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % initialize output:

            nLinks                   = size(distancesInMeter2D,2);
            indoorPathLoss           = zeros(1, nLinks);
            distanceOutdoor          = distancesInMeter2D;

            if obj.isIndoor
                distanceIndoor           = 25 * rand(1, nLinks);
                distanceOutdoor          = distancesInMeter2D - distanceIndoor;
                indoorPathLoss           = obj.getIndoorPathLoss(distanceIndoor);
            end

            C                       = obj.getC(nLinks,distanceOutdoor,UEantennaHeightm);
            environmentHeightm       = obj.getEnvironmentHeight(C,nLinks);

            % get LOS pathloss
            pathlossdB = obj.getLOSpathloss(frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm,environmentHeightm);

            if ~obj.isLOS
                % get nlos pathloss
                nlosPathloss = obj.getNLOSpathloss(frequencyGHz,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm);
                pathlossdB   =  max(nlosPathloss, pathlossdB);
            end

            % calculate total pathloss
            pathlossdB          = pathlossdB + indoorPathLoss;
        end

        function pathlossdB = getNLOSpathloss(obj,frequencyGHz,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm)
            % calculates pathloss for NLOS scenario
            % according to 3GPP TR 36.873 V12.0.0 Table 7.2-1
            %
            %NOTE: the NLOS pathloss should not be smaller than the LOS
            %pathloss. This is assured in modelPathloss.

            pathlossdB = 161.04 - 7.1*log10(obj.streetWidthm) + 7.5*log10(obj.averageBuildingHeightm) ...
                - (24.37 - 3.7 * (obj.averageBuildingHeightm./BSantennaHeightm).^2) .* log10(BSantennaHeightm) ...
                + (43.42 - 3.1*log10(BSantennaHeightm)) .* (log10(distancesInMeter3D) - 3) ...
                + 20*log10(frequencyGHz)...
                -(3.2*(log10(17.625))^2 - 4.97) - 0.6 * (UEantennaHeightm - 1.5);
        end
    end

    methods(Hidden = true)
        function environmentHeight	= getEnvironmentHeight(~,C,nLinks)
            % sets environmentHeightEffective according to probability
            % The effective environment height equals 1 m with a
            % probability of 1/(1 + C) and is chosen from a discrete
            % uniform distribution uniform(12, 15,..., (h_UE-1.5))
            % otherwise.
            % For more information see table 7.2-2: LOS probabilities in
            % 3GPP TR 36.873 V12.0.0

            environmentHeight    = ones(1, nLinks);

            isHOne              = binornd(1, 1 ./ (1 + C));
            nSamples            = sum(isHOne);

            % sample from uniform distribution (12,15,18,21), heights in [m]
            values              = [12, 15, 18, 21];
            nValues             = size(values,2);
            environmentHeight(isHOne) = values(randi(nValues,1,nSamples));
        end
    end

    methods(Static)
        function C = getC(nLinks, outDistance, UEantennaHeightm)
            % sets C and the effectiveProbability
            % according to 3GPP TR 36.873 V12.0.0 Table 7.2-2
            % C is used to determine environment probabilitiy (=
            % effectiveProbability) and LOS probability
            %
            % used properties: distancesInMeter2D, UEantennaHeightm
            %
            % set properties: C, effectiveProbability

            % initialize C and g to 0
            g = zeros(1, nLinks);
            C = zeros(1, nLinks);
            % get indicator array for links for which g needs to be calculated
            isUEhigh = UEantennaHeightm > 13 & UEantennaHeightm < 23;
            iCalcG =  outDistance > 18;
            iCalcG = iCalcG & isUEhigh;
            %NOTE: The notation for g in the standard is ambiguous, but 1.25e-6 is in fact correct
            g(iCalcG) = (1.25e-6 * outDistance(iCalcG).^3 .* exp(-outDistance(iCalcG)/150));
            C(isUEhigh)  = ((UEantennaHeightm(isUEhigh) - 13)/10).^1.5 .* g(isUEhigh);
        end
    end
end

