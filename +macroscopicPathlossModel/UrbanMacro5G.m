classdef UrbanMacro5G < macroscopicPathlossModel.PathlossModel
    % UMa Scenario from TR 38.901
    % Parameter Ranges
    % Frequency           0.5 - 100 GHz
    % User Antenna Height 1.5 - 22.5 m
    % BS Antenna Height    10 - 150 m
    % distance2D           10 - 5000 m

    properties
        % [1x1]logical indicator is true if model is used in Line Of Sight scenario
        isLOS
    end

    methods
        function obj = UrbanMacro5G(isLOS)
            %UMA TR 38.901 Construct an instance of this class
            %
            % input:
            %   isLOS: [1x1]logical indicator for LOS model

            obj.isLOS = isLOS;
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

            C                       = obj.getC(distancesInMeter2D, UEantennaHeightm, nLinks);
            evironmentHeightm       = obj.getEnvironmentHeight(C, nLinks);

            % get LOS pathloss
            pathlossdB  = obj.getLOSpathloss(frequencyGHz,distancesInMeter2D,distancesInMeter3D,UEantennaHeightm,BSantennaHeightm,evironmentHeightm);

            if ~obj.isLOS
                % get nlos pathloss
                nlosPathloss = obj.getNLOSpathloss(frequencyGHz,distancesInMeter3D,BSantennaHeightm);
                pathlossdB   =  max(nlosPathloss, pathlossdB);
            end

            % calculate total pathloss
            pathlossdB          = pathlossdB + indoorPathLoss;
        end

        function pathlossdB = getNLOSpathloss(~, frequencyGHz, distancesInMeter3D, UEantennaHeightm)
            % calculates pathloss for NLOS scenario
            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            pathlossdB = 13.54 + 39.08*log10(distancesInMeter3D) ...
                + 20*log10(frequencyGHz) ...
                - 0.6*(UEantennaHeightm-1.5);
        end

        function pathlossdB = getNLOSpathlossOptional(~, frequencyGHz, distancesInMeter3D)
            % calculates pathloss for NLOS scenario
            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            pathlossdB = 32.4 ...
                + 20*log10(frequencyGHz) ...
                + 30*log10(distancesInMeter3D);
        end

        function pathlossdB = getLOSpathloss(obj,frequencyGHz, distancesInMeter2D, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm, environmentHeight)
            % calculates pathloss for LOS scenario

            % output:
            % pathlossdB:   [1 x nLinks]double LOS pathloss for all links

            % dBp ... distanceBreakPoint
            dBp     = obj.getdistanceBreakPoint(frequencyGHz, UEantennaHeightm, BSantennaHeightm, environmentHeight);
            % indBp ... index for 2d distance greater than distanceBreakPoint
            indBp   = distancesInMeter2D > dBp;

            %Pathloss before breakpoint PL1
            pathlossdB = 28 ...
                + 22*log10(distancesInMeter3D) ...
                + 20*log10(frequencyGHz);

            %additional pathloss after breakpoint PL2
            pathlossdB(indBp) = pathlossdB(indBp) ...
                + 18*log10(distancesInMeter3D(indBp)) ...
                - 9*log10(dBp(indBp).^2+(BSantennaHeightm(indBp)-UEantennaHeightm(indBp)).^2);
        end
    end

    methods (Hidden = true)
        function evironmentHeight	= getEnvironmentHeight(~, C, nLinks)
            % sets environmentHeightEffective according to probability
            % The effective environment height equals 1 m with a
            % probability of 1/(1 + C) and is chosen from a discrete
            % uniform distribution uniform(12, 15,..., (h_UE-1.5))
            % otherwise.
            % For more information see table 7.2-2: LOS probabilities in
            % 3GPP TR 36.873 V12.0.0
            %
            % used properties: effectiveProbability
            %
            % set properties: evironmentHeightEffective
            evironmentHeight    = ones(1,nLinks);

            isHOne              = binornd(1, 1 ./ (1 + C));
            nSamples            = sum(~isHOne);

            % sample from uniform distribution (12,15,18,21), heights in [m]
            values              = [12, 15, 18, 21];
            nValues             = size(values,2);
            evironmentHeight(~isHOne) = values(randi(nValues,1,nSamples));
        end
    end

    methods(Static)
        function C = getC(outDistance, UEantennaHeightm, nLinks)
            % sets C and the effectiveProbability
            % according to 3GPP TR 36.873 V12.0.0 Table 7.2-2
            % C is used to determine environment probabilitiy (=
            % effectiveProbability) and LOS probability
            %
            % used properties: distancesInMeter2D, UEantennaHeightm
            %
            % set properties: C, effectiveProbability

            % initialize C to 0
            C = zeros(1, nLinks);

            isUEhigh = UEantennaHeightm > 13 & UEantennaHeightm < 23;

            iCalcG =  outDistance > 18;
            iCalcG = iCalcG & isUEhigh;

            C(iCalcG)  = ((UEantennaHeightm(iCalcG) - 13)/10).^1.5;
        end
    end
end

