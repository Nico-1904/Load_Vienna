classdef SixSector < networkElements.bs.antennas.Sector
    %SIXSECTOR six sector antenna
    %   Values for gain calculation are taken from:
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
    % see also networkElements.bs.Antenna,
    % networkElements.bs.antennas.Sector,
    % networkElements.bs.antennas.ThreeSectorBerger
    %
    % initial author: Agnes Fastenbauer
    % based on DL Systemlevel Simulator function by Josep Colom Ikuno

    methods
        function obj = SixSector()
            %SIXSECTOR sets properties for six sector antenna and calls superclass constructor

            % call superclass constructor
            obj = obj@networkElements.bs.antennas.Sector;

            % set properties for six sector antenna according to table 1 in paper mentioned above
            obj.gaindBmax       = 17;   % in dBi
            obj.maxAttenuation	= 23;   % in dB
            obj.theta3dB        = 35;   % in degrees
        end
    end
end

