classdef ThreeSector < networkElements.bs.antennas.Sector
    %THREESECTOR Base station antenna according to 3GPP 36.942 section 4.2.1
    %   The maximum gain for this antenna type is defined in Table 4.3 of
    %   3GPP 36.942 subclause 4.2.1 for 900 MHZ and 2000 MHz carrier
    %   frequency, for rural and urban area.
    %   This antenna model is for 3 sector cell sites, where each of the
    %   sites has an antenna with this radiation pattern.
    %
    %NOTE: no min max gain function has been implemented in the 5G
    %simulator, for this antenna the minimum gain is at theta = 180 deg
    %
    % see also networkElements.bs.Antenna,
    % networkElements.bs.antennas.Sector
    %
    % initial author: Agnes Fastenbauer
    % based on DL Systemlevel Simulator function by Josep Colom Ikuno

    methods
        function obj = ThreeSector()
            %THREESECTOR calls superclass constructor and sets properties for Three Sector Antenna

            % call superclass constructor
            obj = obj@networkElements.bs.antennas.Sector;

            % set theta3dB and maximum attenuation according to standard
            obj.theta3dB        = 65; % in degrees
            obj.maxAttenuation  = 20; % in dB
        end

        function setGenericParameters(obj, antennaParameters, positionList, params)
            % set generic parameters with standardvalues for an antenna
            % and sets maximum antenna gain according to table 4.3 in 3GPP
            % TS 36.942, or to 15 dB if the settings of the scenario are
            % not standard compliant.
            %
            % input:
            %   antennaParameters:  [1x1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   params:             [1x1]handleObject parameters.Parameters
            %
            % See Also: networkElements.bs.Antenna.setGenericParameters

            %set standard values
            setGenericParameters@networkElements.bs.Antenna(obj, antennaParameters, positionList, params)
            % set specific values
            obj.setGain(obj.usedCCs(1).centerFrequencyGHz)
            %NOTE: the maximum antenna gain has to be set here because it
            %depends on the carrier frequency  which is set in the
            %superclass method setGenericParameters
        end

        function setGain(obj, frequencyGHz)
            % set gaindBmax according to standard for the given frequency

            % set maximum antenna gain according to standard
            switch obj.positionList(3,1,1) %NOTE: it is assumed that the antenna height does not change over time
                case 30
                    switch frequencyGHz
                        case 2
                            obj.gaindBmax = 15;
                        case 0.9
                            obj.gaindBmax = 12;
                        otherwise
                            % throws a warning if settings are not standard compliant but continues simulation
                            warning('WARN:Freq', 'The carrier frequency does not match the standard, 2 GHz is assumed for setting of maximum gain.');
                            obj.gaindBmax = 15;
                    end
                case 45
                    % rural area scenario with 900MHz carrier frequency
                    obj.gaindBmax = 15;
                    if frequencyGHz ~= 0.9
                        % throws a warning if settings are not standard compliant but continues simulation
                        warning('WARN:Freq', 'The carrier frequency does not match the standard defined 900 MHz.');
                    end
                otherwise
                    % throws a warning if settings are not standard compliant but continues simulation
                    warning('WARN:ANTpattern', 'The settings of this antenna do not match the standard, urban area with 2 GHz and 30 m antenna height is assumed for setting of maximum gain.');
                    obj.gaindBmax = 15;
            end
        end
    end
end

