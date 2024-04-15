classdef MIMO < precoders.analog.AnalogPrecoderSuperclass
    %MIMO analog precoder for full dimension MIMO
    % This implementation follows the antenna port mapping in 3GPP TR 38.901 section 7.3.1.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.setting.PrecoderAnalogType,
    % precoders.analog.AnalogPrecoderSuperclass

    methods
        function obj = MIMO()
            %MIMO Construct an instance of this class
        end
    end

    methods (Static)
        function W_a = calculatePrecoder(Antenna)
            % CALCULATEPRECODER returns analog precoding matrix
            %
            % input:
            %   Antenna:   [1 x 1]handleObject array of all antennas
            %
            % output:
            %   W_a:	[nTXelements x nTX]complex analog precoder

            % this is the legacy model for 1D arrays
            w = 1/sqrt(Antenna.nTXelements)*exp(-1j*((1:Antenna.nV)-1)*2*pi*cos(Antenna.elevation+Antenna.elevationOffset)*Antenna.dV);

            % repeat the mapping to fill all columns of the antenna array
            w = repmat(w, 1, Antenna.nH/Antenna.nTX);

            % repeat mapping for all RF chains
            W_a = kron(eye(Antenna.nTX), w');

            % repeat mapping for all panels in the antenna array
            W_a = repmat(W_a, Antenna.nPV*Antenna.nPH, 1);
        end
    end

    methods (Static, Access = protected)
        function checkConfig(antenna)
            % checks if parameter config for precoder and antenna are compatible
            %
            % input:
            %	antenna:	[1x1]handleObject networkElements.bs.Antenna

            % check if number of antenna elements is set
            if antenna.nTXelements < 1
                error('analogPRECODER:noAntenna','No transmit antenna elements are set.');
            end

            % give out warning if MIMO precoder is set to 1
            if antenna.nTXelements == 1
                warning('analogPRECODER:oneAntenna','The beamforming MIMO analog precoder is chosen in combination with one transmit antenna element. The analog precoder will return 1.');
            end

            % check that number of antenna columns per panel can be divided
            % by number of transmit RF chains nTX
            if mod(antenna.nH, antenna.nTX)
                error('antannaArray:columns', 'The analog precoder maps the RF chains to the antenna element columns of each panel. The number of columns per panel nH needs to be a multiple of the number of RF chains nTX.');
            end

            % check that there are more nTXelements than nTX
            if antenna.nTXelements < antenna.nTX
                error('analogPrecoder:setting', 'The number of transmit RF chains nTX is larger than the number of transmit antenna elements. The analog precoder can not map several RF chains to the same antenna element.');
            end
        end
    end
end

