classdef ThreeSectorBerger < networkElements.bs.antennas.Sector
    %BERGER a Berger antenna with 14 dB maximum gain
    % This antenna is very similar to the ThreeSector antenna, but with a
    % different theta3dB and a different gaindBmax.
    % This is the 3 sector antenna from the following paper:
    % Performance Evaluation of 6-Sector-Site Deployment for Downlink UTRAN Long Term Evolution, 2008
    % @INPROCEEDINGS{4657216,
    % author={Kumar, S. and Kovacs, I.Z. and Monghal, G. and Pedersen, K.I. and Mogensen, P.E.},
    % booktitle={Vehicular Technology Conference, 2008. VTC 2008-Fall. IEEE
    % 68th}, title={Performance Evaluation of 6-Sector-Site Deployment for
    % Downlink UTRAN Long Term Evolution},
    % year={2008},
    % month={sept.},
    % doi={10.1109/VETECF.2008.384},
    % }
    % http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=4657216
    %
    % see also networkElements.bs.Antenna
    %
    % initial author: Agnes Fastenbauer
    % based on DL Systemlevel Simulator function by Josep Colom Ikuno

    methods
        function obj = ThreeSectorBerger()
            % calls superclass constructor and sets properties for Berger Antenna

            % call superclass constructor
            obj = obj@networkElements.bs.antennas.Sector;

            % set properties for Berger antenna according to table 1 in paper mentioned above
            obj.gaindBmax       = 14;   % in dBi
            obj.maxAttenuation	= 20;   % in dB
            obj.theta3dB        = 70;   % in degrees
        end
    end
end

