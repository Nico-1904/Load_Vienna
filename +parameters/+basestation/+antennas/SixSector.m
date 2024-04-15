classdef SixSector < parameters.basestation.antennas.Parameters
    %SIXSECTOR Six Sector antenna
    % 6 sector antenna
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
    % This is a 6 sector antenna with:
    % 17 dBi antenna gain
    % 23 dB maximum attenuation
    % 35deg 3dB beam width
    %
    % initial author: Agnes Fastenbauer
    % extended by: Thomas Lipovec, Changed to a single six sector antenna
    %
    % see also parameters.basestation.antennas.Parameters,
    % networkElements.bs.Antenna,
    % networkElements.bs.antennas.SixSector,
    % networkElements.bs.Antenna.generateSixSector

    properties (SetAccess = protected)
        % 3 dB beam width
        % [1x1]integer 3dB beam width as defined by standard
        theta3dB = 35;
    end

    methods
        function obj = SixSector()
            % SixSector class constructor

        end

        function checkParameters(obj)
            % check antenna parameters

            % check superclass parameters
            obj.checkParametersSuperclass;
        end
    end

    methods (Static)
        function createAntenna(antennaParameters, positionList, BS, params)
            % creates a single six sector antenna with antennaParameters
            %
            % input:
            %   antennaParameters:  [1 x 1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   BS:                 [1x1]handleObject networkElements.BaseStation
            %   params:             [1x1]handleObject parameters.Parameters

            % preallocate antenna object
            antenna = networkElements.bs.antennas.SixSector();

            % set antenna parameters
            antenna.setGenericParameters(antennaParameters, positionList, params);

            % extend antennaList at the BS
            BS.antennaList(end+1) = antenna;
        end
    end
end

