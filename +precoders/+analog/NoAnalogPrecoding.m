classdef NoAnalogPrecoding < precoders.analog.AnalogPrecoderSuperclass
    % class for use of no analog precoder
    % In case no analog precoder is needed, this class produces an analog
    % precoder equal to the identity matrix of size nTX.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also precoders.analog, parameters.setting.PrecoderAnalogType,
    % precoders.analog.MIMO

    methods (Static)
        function W_a = calculatePrecoder(Antenna)
            % CALCULATEPRECODER returns analog precoding matrix
            % This function returns an identity matrix of size nTX in case
            % no analog precoding is performed.
            %
            % input:
            %   Antenna:   [1x1]handleObject antenna for which the precoder is calculated
            %
            % output:
            %   W_a:	[nTXelements x nTX]integer identity matrix

            % create an identity matrix of size nTX = nTXelements
            W_a = eye(Antenna.nTX);
        end
    end

    methods (Static, Access = protected)
        function checkConfig(antenna)
            % checks if parameter config for precoder and antenna are compatible
            %
            % input:
            %	antenna:	[1x1]handleObject networkElements.bs.Antenna

            % check that the number of antenna elements is equal to the number of RF chains
            if antenna.nTXelements ~= antenna.nTX
                error('analogPRECODER:notEnoughAntenna','No analog precoder is chosen, but the number of transmit RF chains is not equal to the number of transmit antenna elements.');
            end
        end
    end
end

