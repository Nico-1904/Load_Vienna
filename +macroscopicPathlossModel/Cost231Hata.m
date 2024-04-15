classdef (Abstract) Cost231Hata < macroscopicPathlossModel.PathlossModel
    %COST231 pathloss according to COST-Hata-Model
    %   according to COST 231 Chapter 4 P.135
    % Pathloss for large and small macro-cells, i.e. base station
    % antenna heights above rooftop levels adjacent to the base station.
    % This model must not be used formicro-cells.
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    properties
        limitFrequency  = [1500,2000];
        limitAntHeight  = [30,200];
        limitUEHeight   = [1,10];
        limitDistance2D = [1E3,20E3];
        % correction factor for dense buildings in dB
        % [1x1]double correctio factor for dense buildings
        %
        % CdB is 0 dB for suburban scenario and 3 dB for urban macro cells.
        CdB
    end

    methods
        function obj = Cost231Hata(CdB)
            % class constructor for macroscopicPathlossModel.Cost231
            %
            % input:
            %   Cdb:        [1x1]double additional constant loss for urban
            %                           scenarios
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link
            obj = obj@macroscopicPathlossModel.PathlossModel();
            obj.CdB = CdB;
        end

        function pathlossdB = HataPathloss(obj, distanceskm, bsHeights, ueHeights, frequencyArrayMHz)
            % returns the pathloss value for each link for urban and suburban macro scenarios
            %
            % input:
            %   distanceskm:        [1 x nLinks]double 2D user-BS distance in km
            %   bsHeights:          [1 x nLinks]double BS antenna height in m
            %   ueHeights:          [1 x nLinks]double user heigth in m
            %   frequencyArrayMHz:  [1 x 1]double frequency in MHz
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % calculate a
            a = (1.1*log10(frequencyArrayMHz) - 0.7) .* ueHeights - (1.56*log10(frequencyArrayMHz)-0.8);

            % calculate pathloss
            pathlossdB = 46.3 + 33.9*log10(frequencyArrayMHz) ...
                - 13.82*log10(bsHeights) - a ...
                + (44.9 - 6.55*log10(bsHeights)).*log10(distanceskm) ...
                + obj.CdB;
        end
    end
end

