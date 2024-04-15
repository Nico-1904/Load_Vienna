classdef RuralMacro5G < macroscopicPathlossModel.PathlossModel
    % RMa Scenario from TR 38.901
    % Parameter Ranges
    % Frequency           0.5 - 30 GHz
    % User Antenna Height   1 - 20 m
    % BS Antenna Height    10 - 150 m
    % avg. Building Height  5 - 50 m
    % avg. Street Width     5 - 50 m
    % distance2D           10 - 5000 m

    properties
        % [1 x 1] logical
        % indicator isture if model is used in
        % Line Of Sight scenario
        isLOS

        % average street width
        % [1x1]double average street width
        streetWidthm

        % average building height in meter
        % [1x1]double average building height in meter
        averageBuildingHeightm
    end

    methods
        function obj = RuralMacro5G(streetWidth, averageBuildingHeight, isLOS)
            % class constructor

            % set RMa specific parameters
            obj.streetWidthm            = streetWidth;
            obj.averageBuildingHeightm	= averageBuildingHeight;
            obj.isLOS                   = isLOS;
        end

        function pathlossdB = getPathloss(obj, frequencyGHz, distancesInMeter2D, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm)

            pathlossdB = obj.getLOSpathloss(frequencyGHz, distancesInMeter2D, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm);
            if ~ obj.isLOS
                pathlossNLOSdB  = obj.getNLOSpathloss(frequencyGHz, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm);
                pathlossdB      = max(pathlossdB,pathlossNLOSdB);
            end
        end

        function pathlossdB = getNLOSpathloss(obj, frequencyGHz, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm)
            % calculates pathloss for NLOS scenario
            %
            % output:
            % pathlossdB:   [1 x nLinks]double NLOS pathloss for all links

            pathlossdB = 161.04 - 7.1*log10(obj.streetWidthm)  ...
                + 7.5*log10(obj.averageBuildingHeightm) ...
                - (24.37 - 3.7*(obj.averageBuildingHeightm./BSantennaHeightm).^2).*log10(BSantennaHeightm)...
                + (43.42 - 3.1*log10(BSantennaHeightm)).*(log10(distancesInMeter3D)-3) ...
                + 20*log10(frequencyGHz) ...
                -(3.2*(log10(11.75*UEantennaHeightm)).^2 - 4.97);
        end

        function pathlossdB = getLOSpathloss(obj, frequencyGHz, distancesInMeter2D, distancesInMeter3D, UEantennaHeightm, BSantennaHeightm)
            % calculates pathloss for NLOS scenario
            %
            % output:
            %   pathlossdB: [1 x nLinks]double LOS pathloss for all links

            % sets breakpoint distance and Indicator for RMa Scenario
            % according to Table 7.4.1-1, Note 5
            % The break point distance depends on the frequency, thus there is
            % a distinct break point distance for each component carrier.
            distanceBreakPoint = 2 * pi * BSantennaHeightm .* UEantennaHeightm .* frequencyGHz*1e9 ./ parameters.Constants.SPEED_OF_LIGHT;
            % indBp ... index for 2d distance greater than distanceBreakPoint
            indBp   = distancesInMeter2D > distanceBreakPoint;

            % dL1 ... valid distance for PL1
            dL1         = distancesInMeter3D;
            dL1(indBp)  = distanceBreakPoint(indBp);

            % path loss before breakpoint
            pathlossdB = 20*log10(40*pi*dL1.*frequencyGHz/3) ...
                + min(0.03*obj.averageBuildingHeightm.^1.72,10).*log10(dL1) ...
                - min(0.044*obj.averageBuildingHeightm.^1.72,14.77) + 0.002*log10(obj.averageBuildingHeightm) ...
                .*dL1;

            % path loss after breakpoint
            pathlossdB(indBp) = pathlossdB(indBp)+40*log10(distancesInMeter3D(indBp)./distanceBreakPoint(indBp));
        end
    end

    methods(Static)
        function LOS = getLOS(distancesInMeter2D, nLinks)
            % applies the LOS probability from table 7.4.2-1 to the isLOS parameter

            LOS_prob = min(exp(-(distancesInMeter2D-10)/1000),1);

            LOS = LOS_prob >= rand(1,nLinks);
        end
    end
end

