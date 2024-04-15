classdef (Abstract) Cost231WI < macroscopicPathlossModel.PathlossModel
    % COST231 pathloss according to Cost231 Walfisch Ikegami
    % according to COST 231 Chapter 4 P.136
    % Pathloss for large and small macro-cells, i.e. base station
    % antenna heights above rooftop levels adjacent to the base station.
    % This model must not be used formicro-cells.
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    properties
        buildingHeightM     = 12;
        streetOrientation   = 90;
        buildingSeperationM = 20;
        streetWidthM        = 10;
        isUrban             = true;
    end

    methods
        function obj = Cost231WI(streetOrientation, buildingSeperationM, streetWidthM, buildingHeightM, isUrban)
            % class constructor for macroscopicPathlossModel.Cost231

            obj = obj@macroscopicPathlossModel.PathlossModel();
            %obj.limitFrequencyMhz   = [800 ,2000];
            %obj.limitAntHeightM     = [4,50];
            %obj.limitUEHeightM      = [1,3];
            %obj.limitDistance2DKm   = [0.02,20];

            % set parameters
            obj.streetOrientation   = streetOrientation;
            obj.streetWidthM        = streetWidthM;
            obj.buildingSeperationM = buildingSeperationM;
            obj.buildingHeightM     = buildingHeightM;
            obj.isUrban             = isUrban;
        end

        function Lb = losWIPathloss(~,distances2Dm,frequencyArrayMHz)
            % returns the pathloss value for each component carrier for LOS link
            %
            % input:
            %   distances2Dm: [1 x losLink]double distances for links with LOS connection
            % used properties: frequencyArrayMHz
            %
            % output:
            %   Lb: [1 x losLink]double LOS pathloss in dB for each
            %               component carrier attached to the base station.

            % Eq 4.4.5
            distances2DKm = distances2Dm/1e3;
            Lb = 42.6 + 26*log10(distances2DKm)+ 20*log10(frequencyArrayMHz);
        end

        function Lb = nlosWIPathloss(obj,distances2Dm,frequencyArrayMHz, antHeightsM, ueHeightsM)
            % returns the pathloss value for each component carrier for NLOS link
            %
            % input:
            %   distances2Dm:	[1 x nlosLink]double distances for links with NLOS connection
            % used properties: frequencyArrayMHz
            %
            % output:
            %   Lb: [1 x nlosLink]double NLOS pathloss in dB for each
            %               component carrier attached to the base station.
            nLinks = size(distances2Dm,2);
            dUe  = obj.buildingHeightM  - ueHeightsM;
            dAnt = antHeightsM          - obj.buildingHeightM;
            distances2DKm = distances2Dm /1e3;
            % defines the loss due to multiple screen diffraction.
            % It  takes  intoaccount the width of the street and its orientation
            % defines loss due to street orientation and los component

            if ((0  <= obj.streetOrientation) && (obj.streetOrientation < 35))
                LOri = -10 + 0.354 *  obj.streetOrientation ;
            elseif  ((35 <= obj.streetOrientation) && (obj.streetOrientation < 55))
                LOri = 2.5 + 0.075 * (obj.streetOrientation - 33);
            elseif  ((55 <= obj.streetOrientation) && (obj.streetOrientation < 90))
                LOri = 4   + 0.114 * (obj.streetOrientation - 55);
            end

            % Defines the loss due to rooftop to street diffraction and
            % scattering.
            % The term ka represents the increase of the path loss for base station antennas
            % below  the  roof  tops  of  the  adjacent  buildings.
            % The  terms  kd  and  kf  control the dependence of the multi-screen diffraction loss
            % versus distance and radiofrequency,  respectively.

            isAntBelow = antHeightsM <= obj.buildingHeightM;
            is500M = distances2DKm > 0.5;

            kd   = 18 * ones(1,nLinks);
            ka   = 54 * ones(1,nLinks);
            kf   = -4 * ones(1,nLinks);
            Lbsh = zeros(1,nLinks);

            % set parameter dependancies
            if any(isAntBelow)
                kd(isAntBelow) = kd(isAntBelow) - 15 * dAnt/ obj.buildingHeightM;
                ka(isAntBelow) = ka(isAntBelow) - 0.8 * dAnt;

            elseif any(isAntBelow.*is500M)
                ka(isAntBelow.*is500M) = ka(isAntBelow*is500M) * obj.distances2Dkm /0.5;
            end
            if any(~isAntBelow)
                Lbsh( ~isAntBelow) = -18 * log10(1 + dAnt( ~isAntBelow));
            end
            kf   = kf  + (0.7+ obj.isUrban*0.8) *(frequencyArrayMHz /925 - 1);

            Lmsd = Lbsh+ka+kd.*log10(distances2DKm)+kf.*log10(frequencyArrayMHz)-9*log10(obj.buildingSeperationM);

            Lrts = -16.9-10*log10(obj.streetWidthM)+10*log10(frequencyArrayMHz)+20*log10(dUe)+LOri;

            LA = Lrts + Lmsd;
            % defines free space propagation effect for non line of sight links
            L0 = 32.4 + 20*log10(distances2DKm) +20*log10(frequencyArrayMHz);

            Lb = L0 + LA;
        end
    end
end

