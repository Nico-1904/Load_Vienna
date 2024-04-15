classdef ThreeSectorBerger < parameters.basestation.antennas.ThreeSector
    %THREESECTORBERGER Three Sector Berger antenna
    % 3 sector antenna
    % according to:
    % Performance Evaluation of 6-Sector-Site Deployment for Downlink UTRAN Long Term Evolution, 2008
    % @INPROCEEDINGS{4657216,
    % author={Kumar, S. and Kovacs, I.Z. and Monghal, G. and Pedersen, K.I. and Mogensen, P.E.},
    % booktitle={Vehicular Technology Conference, 2008. VTC 2008-Fall. IEEE 68th}, title={Performance Evaluation of 6-Sector-Site Deployment for Downlink UTRAN Long Term Evolution},
    % year={2008},
    % month={sept.},
    % doi={10.1109/VETECF.2008.384},
    % }
    % http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=4657216
    %
    % This is a 3 sector antenna with:
    % 14 dBi antenna gain
    % 20 dB maximum attenuation
    % 70deg 3dB beam width
    %
    % initial author: Agnes Fastenbauer
    % extended by: Thomas Lipovec, Changed to a single three sector antenna
    %
    % see also parameters.basestation.antennas.Parameters,
    % networkElements.bs.Antenna,
    % networkElements.bs.antennas.ThreeSectorBerger,
    % networkElements.bs.Antenna.generateThreeSectorBerger

    methods
        function obj = ThreeSectorBerger()
            % ThreeSectorBerger class constructor
            obj.theta3dB = 70;
        end

        function checkParameters(obj)
            % check antenna parameters

            % check superclass parameters
            obj.checkParametersSuperclass;
        end
    end

    methods (Static)
        function createAntenna(antennaParameters, positionList, BS, params)
            % creates a single ThreeSectorBerger antenna with antennaParameters
            %
            % input:
            %   antennaParameters:  [1 x 1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   BS:                 [1 x 1]handleObject networkElements.BaseStation
            %   params:             [1 x 1]handleObject parameters.Parameters

            % preallocate antenna objects
            antenna = networkElements.bs.antennas.ThreeSectorBerger();

            % set antenna parameters
            antenna.setGenericParameters(antennaParameters, positionList, params);

            % extend antennaList at the BS
            BS.antennaList(end+1) = antenna;
        end
    end
end

