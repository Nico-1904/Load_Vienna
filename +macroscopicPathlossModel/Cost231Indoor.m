classdef Cost231Indoor < macroscopicPathlossModel.PathlossModel
    %INDOOR pathloss model for indoor user according to 3GPP TR 25.952 V5.2.0 section 5.1.1
    % NOTE: The wall penetration loss is not accounted for in this
    % implementation.
    %
    % Model for small cells/pico cells in indoor environments.
    % The model is derived from the COST 231 Indoor model.
    %
    % Based on LTE SL simulator by Martin Taranetz, INTHFT, 2015
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    properties
        L0      = 33;
        n       = 4;
        Lw_i    = [3.4,6.9];
        Lf      = 18.3;
        b       = 0.46;
        a       = 0.62;
    end

    methods
        function obj = Cost231Indoor()
            % Constructor

            obj = obj@macroscopicPathlossModel.PathlossModel();
        end

        % default values defiend by various scenarios
        function setDefaultOpen(obj)
            % set a default parametrisation based on COST231 project page 178
            % table 4.7.2 based on a open environment

            obj.L0      = 42;
            obj.n       = 1.9;
            obj.Lw_i    = [3.4;6.9];
            obj.Lf      = 18.3;
            obj.b       = 0.46;
            obj.a       = 0.22;
        end

        function setDefaultLarge(obj)
            % set a default parametrisation based on COST231 project page 178
            % table 4.7.2 based on a large environment

            obj.L0      = 37.5;
            obj.n       = 2;
            obj.Lw_i    = [3.4;6.9];
            obj.Lf      = 18.3;
            obj.b       = 0.46;
            obj.a       = nan;
        end

        function setDefaultCorridor(obj)
            % set a default parametrisation based on COST231 project page 178
            % table 4.7.2 based on a corridor like environment

            obj.L0      = 39.2;
            obj.n       = 1.4;
            obj.Lw_i    = [3.4;6.9];
            obj.Lf      = 18.3;
            obj.b       = 0.46;
            obj.a       = nan;
        end

        function setDefaultDense(obj, nFloors)
            % set a default parametrisation based on COST231 project page 178
            % table 4.7.2 based on a dense environment
            % input:
            %   nFloors: [1x1]double number of floors in the scenario

            if varagin == 0
                nFloors = 1;
            end
            obj.Lw_i    = [3.4;6.9];
            obj.Lf      = 18.3;
            obj.b       = 0.46;

            if nFloors == 1
                obj.L0  = 33;
                obj.n   = 4;
                obj.a   = 0.62;

            elseif nFloors == 2
                obj.L0  = 21.9;
                obj.n   = 5.2;
                obj.a   = 0.62;

            else
                obj.L0  = 44.9;
                obj.n   = 5.4;
                obj.a   = 2.8;
            end
        end

        % define setter for different models
        function setParametersOneSlopeModel(obj, L0, n)
            % defines parameters other than the default parameters when
            % using the OneSlopeModel
            %
            % input:
            %   L0: [1x1]double path loss at 1 meter distance in dB
            %   n:  [1x1]double power decay index
            %        defines the exponential dependency on the distance

            obj.L0 = L0;
            obj.n = n;
        end

        function setParametersLinearAttenuationModel(obj, a)
            % defines parameters other than the default parameters when
            % using the LinearAttenuationModel
            % input:
            %   a:      [1x1]double linear attenuation coefficient
            obj.a = a;

        end

        % different models specified in the COST231 Project
        function L = oneSlopeModel(obj,d)
            % Calculates indoor loss based on a one sloped model defined in
            % the COST231 Project on page 176 Eq 4.7.1
            % input:
            %   d:  [1xnLinks]double distance between receiver and transmitter
            %
            % other properties:
            %   L0: [1x1]double path loss at 1 meter distance
            %   n:  [1x1]double power decay index
            % output:
            %   L: [1xnLinks] loss value on each link

            L = obj.L0 + 10*obj.n*log10(d);
        end

        function L = multiWallModel(obj, d, kw_i, kf)
            % Calculates indoor loss based on a multiple wall and floor traversal model defined in
            % the COST231 Project on page 176 Eq 4.7.2
            % input:
            %   d:      [1 x nLinks]double distance between receiver and transmitter
            %   kw_i:   [nWalltypes x nLinks]double number of type i walls traversed
            %   kf:     [1 x nLinks]double number of penetrated floors
            % other properties:
            %   L0:     [1x1]double constant path loss in dB
            %   n:      [1x1]double power decay index
            %           defines the exponential dependency on the distance for
            %           free space propagation
            %   Lw_i:   [1x nWallTypes]double wall loss of type i in dB
            %   Lf:     [1x1]double loss between adjacent floors in dB
            %   b:      [1x1]double super parameters for floor loss dependecy
            % output:
            %   L:      [1xnLinks] loss value on each link

            Lfs = 10 * obj.n * log10(d);
            L   = Lfs + obj.L0 +  obj.Lw_i * kw_i  + kf.^((kf+2)./(kf+1)-obj.b) * obj.Lf;
        end

        function L = linearAttenuationModel(obj, d)
            % Calculates indoor loss based on a multiple wall and floor traversal model defined in
            % the COST231 Project on page 177 Eq 4.7.3
            % input:
            %   d:      [1xnLinks]double distance between receiver and transmitter
            % other properties:
            %   a:      [1x1]double linear attenuation coefficient
            %   n:      [1x1]double power decay index
            %           defines the exponential dependency on the distance for
            %           free space propagation

            % output:
            %   L:      [1xnLinks] loss value on each link
            Lfs = obj.n * 10 * log10(d);
            L   = Lfs + obj.a * d;
        end
    end
end

