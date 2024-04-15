classdef (Abstract) Cost231 < macroscopicPathlossModel.PathlossModel
    %COST231 pathloss according to COST-Hata-Model
    %   according to COST 231 Chapter 4
    % NLOS pathloss for large and small macro-cells, i.e. base station
    % antenna heights above rooftop levels adjacent to the base station.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    properties
        % correction factor for dense buildings in dB
        % [1x1]double correction factor for dense buildings
        %
        % CdB is 0 dB for suburban scenario and 3 dB for urban macro cells.
        CdB

        % distance between base station and user in km
        % [1x1]double BS antenna to UE distance in km
        distanceskm

        % frequency in MHz
        % [1x1]double frequency in MHz
        frequencyArrayMHz

        % user height for each link in m
        % [1 x nLinks]double height of each user in m
        ueHeights

        % base station antenna height for each link in m
        % [1 x nLinks]double height of each base station antenna in m
        bsHeights
    end

    methods (Access = private)
        function checkParameters(obj)
            % check range of parameters for compliance to the model
            %
            % used properties: frequencyArrayMHz, bsHeights, ueHeights,
            % distancekm

            % check frequency range
            if obj.frequencyArrayMHz < 1500 || obj.frequencyArrayMHz > 2000
                warning('warning:frequency', 'The frequency is out of the scope of this model. Cost231 pathloss model is defined for frequencies in the range of 1.5 GHz to 2 GHz.');
            end

            % check base station antenna heights
            if any(obj.bsHeights < 30) || any(obj.bsHeights > 200)
                warning('warning:BSheight', 'The BS antenna height is out of the scope of this model. Cost231 pathloss model is defined for BS heights in the range of 30 m to 200 m.');
            end

            % check user heights
            if any(obj.ueHeights < 1) || any(obj.ueHeights > 10)
                warning('warning:UEheight', 'The UE height is out of the scope of this model. Cost231 pathloss model is defined for user heights in the range of 1 m to 10 m.');
            end

            % check distances betwen user and base station
            if any(obj.distanceskm < 1) || any(obj.distanceskm > 20)
                warning('warning:distance2D', 'The distance between UE and BS antenna is out of the scope of this model. Cost231 pathloss model is defined for BS-user distances in the range of 1 km to 20 km.');
            end
        end
    end

    methods
        function obj = Cost231(distances2Dm, bsHeights, ueHeights, frequencyGHz)
            % class constructor for macroscopicPathlossModel.Cost231
            %
            % input:
            %   distances2Dm:   [1 x nLinks]double 2D user-BS distance in m
            %   bsHeights:      [1 x nLinks]double BS antenna height in m
            %   ueHeights:      [1 x nLinks]double user heigth in m
            %   frequencyGHz:   [1x1]double frequency in GHz
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % set parameters
            obj.ueHeights = ueHeights;
            obj.bsHeights = bsHeights;

            % convert to needed units
            obj.frequencyArrayMHz	= frequencyGHz*1e3;
            obj.distanceskm         = distances2Dm/1e3;

            % check parameter range
            obj.checkParameters;
        end

        function pathlossdB = modelPathloss(obj)
            % returns the pathloss value for each link for urban and suburban macro scenarios
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % calculate a
            a = (1.1*log10(obj.frequencyArrayMHz) - 0.7).*obj.ueHeights - ...
                (1.56*log10(obj.frequencyArrayMHz)-0.8);

            % calculate pathloss
            pathlossdB = 46.3 + 33.9*log10(obj.frequencyArrayMHz) ...
                - 13.82*log10(obj.bsHeights) - a ...
                + (44.9 - 6.55*log10(obj.bsHeights)).*log10(obj.distanceskm) ...
                + obj.CdB;
        end
    end
end

