classdef Indoor < macroscopicPathlossModel.Cost231Indoor
    %INDOOR pathloss model for indoor user according to 3GPP TR 25.952 V5.2.0
    % NOTE: Different models are applied depending on the specified
    %       wall loss Lw_i in the constructor
    %
    % Model for small cells/pico cells in indoor environments.
    % The model is derived from the COST 231 Indoor model.
    %
    % Based on LTE SL simulator by Martin Taranetz, INTHFT, 2015
    %
    % initial author: Agnes Fastenbauer
    % extended by: Christoph Buchner (parameters)
    %
    % see also macroscopicPathlossModel.PathlossModel

    methods
        function obj = Indoor()
            % Constructor specifies the generated model depeneding on the
            % wall loss Lw_i of each wall type. If no wall loss is
            % specified a different models is generated according to the
            % standard P. 7

            obj = obj@macroscopicPathlossModel.Cost231Indoor();

            % overwrite default parameters from superclass
            obj.L0  = 37;
            obj.n   = 2;
        end

        function pathlossdB = getPathloss(obj, ~, ~, distance3Dm, ~, ~)
            % returns the pathloss value for each component carrier
            % according to TR 25.952 V5.2.0
            %
            % input:
            %   frequencyGHz:   [1 x nLinks]double frequency in GHz
            %   distance2Dm:    [1 x nLinks]double UE-BS distance on the ground in m
            %   distance3Dm:    [1 x nLinks]double UE-BS distance in m
            %   userHeightm:    [1 x nLinks]double user height in m
            %   antennaHeightm: [1 x nLinks]double antenna height in m
            %
            % output:
            %   pathlossdB: [1 x nLinks]double pathloss of each link

            % calculate path loss without wall loss
            pathlossdB = obj.L0 + obj.n * tools.todB(distance3Dm);
        end
    end
end

