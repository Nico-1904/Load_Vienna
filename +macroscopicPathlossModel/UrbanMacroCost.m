classdef UrbanMacroCost < macroscopicPathlossModel.Cost231Hata
    %UrbanMacro pathloss for urban macro base station
    %   according to the used COST-Hata-Models as defined in COST 231 Chapter 4
    %   specified in TR 25.952 V5.2.0
    %
    % initial author: Agnes Fastenbauer
    %
    % see also macroscopicPathlossModel.PathlossModel

    methods
        function obj = UrbanMacroCost()
            % Constructor

            Cdb = 3 ;
            obj = obj@ macroscopicPathlossModel.Cost231Hata(Cdb);
        end

        function pathlossdB = getPathloss(obj, frequencyGHz, distance2Dm, ~, userHeightm, antennaHeightm)
            % returns the pathloss value for each link for urban macro scenarios
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
            pathlossdB = obj.HataPathloss(distance2Dm*1e-3, antennaHeightm, userHeightm, frequencyGHz*1e3);
        end
    end
end

