classdef Super3D <  macroscopicPathlossModel.PathlossModel
    % pathloss according to 3GPP TR 36.873 V12.0.0
    %   The model is for urban macro and micro cells for LOS, NLOS and
    %   Indoor to Outdoor cases.
    %   This path loss model is applicable for frequencies ranging from
    %   2 ... 6 GHz.
    %
    %   LOS: Line-Of-Sight
    %   NLOS: Non-Line-Of-Sight
    %   UMa: Urban Macro cell
    %   UMi: Ueban Micro cell
    %
    % initial author: Agnes Fastenbauer

    properties
        % isLOS [1x1]logical true if the model is used for line of sight
        % links
        isLOS

        % isIndoor [1x1]logical true if the model is used for indoor links
        isIndoor
    end

    methods (Abstract)
        % calculates the NLOS pathloss
        %
        % output:
        %   NLOSpathloss:   [1 x nLinks]double NLOS pathloss for all links
        NLOSpathloss = getNLOSpathloss(obj);
    end

    methods
        function obj = Super3D(isLOS, isIndoor)
            % set constants
            obj = obj@macroscopicPathlossModel.PathlossModel();
            obj.isLOS = isLOS;
            obj.isIndoor = isIndoor;
        end

        function indoorPathLoss = getIndoorPathLoss(~, distanceIndoor)

            % get indoor pathloss for all links
            indoorPathLoss = 0.5 .* distanceIndoor;
        end

        function losPathloss = getLOSpathloss(~, ...
                frequencyGHz, distancesInMeter2D, distancesInMeter3D, ...
                UEantennaHeightm, BSantennaHeightm, evironmentHeightm)
            % calculates the LOS pathloss
            %
            % output:
            %   LOSpathloss:	[1 x nLinks]double LOS pathloss for Link

            % initialize output
            nLinks      = size(distancesInMeter2D,1);
            losPathloss = zeros(1, nLinks);
            distancesBreakPoint = macroscopicPathlossModel.PathlossModel.getdistanceBreakPoint(...
                BSantennaHeightm, UEantennaHeightm, frequencyGHz, evironmentHeightm);

            % get indicators for which case we use
            belowBreakpoint = distancesInMeter2D < distancesBreakPoint;
            aboveBreakpoint = distancesInMeter2D >= distancesBreakPoint;

            % below breakpoint
            losPathloss(belowBreakpoint) = 22.0.*log10(distancesInMeter3D(belowBreakpoint)) + 28.0 + 20.*log10(frequencyGHz(belowBreakpoint));
            % above breakpoint
            losPathloss(aboveBreakpoint) = 40.*log10(distancesInMeter3D(aboveBreakpoint)) + 28 + 20.*log10(frequencyGHz(aboveBreakpoint)) ...
                - 9.*log10((distancesBreakPoint(aboveBreakpoint)).^2 + (BSantennaHeightm(aboveBreakpoint) - UEantennaHeightm(aboveBreakpoint)).^2);
        end
    end

    methods (Access = protected)
        function setRandUEantennaHeigthm3D(obj)
            % Sets the UE antenna height according to the standard.
            %
            % input:
            %   pathlossModel:  [1x1]struct with pathloss model parameters
            %       used parameters: indoorUEfraction
            %
            % set properties: outdoor2indoor, distanceIndoor,
            % UEantennaHeightm

            % set floor number
            floorNo = ones(1, obj.nLinks);
            maxNumFloor = randi(5, 1, sum(obj.outdoor2indoor)) + 3;
            floorNo(obj.outdoor2indoor) = randi(maxNumFloor);

            % set antenna height
            obj.UEantennaHeightm = 3 * (floorNo - 1) + 1.5;
        end
    end
end

