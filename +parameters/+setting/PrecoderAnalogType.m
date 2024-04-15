classdef PrecoderAnalogType < uint32
    %PRECODERANALOGTYPE enum of implemented analog precoder types
    % The analog precoder is the wideband precoder that maps the transmit
    % RF chains to antenna elements. For MIMO transmissions the analog
    % precoder performs beamforming. In the 3GPP standards documents this
    % is often referred to as TXRU virtualization.
    % Wideband here means that the analog precoder is constant for all
    % resource blocks: there is one analog precoder per antenna per slot.
    % The analog precoder is an [nTXelements x nTX]complex matrix.
    % If no analog precoder is used nTXelemnts must be equal to nTX, since
    % the analog precoder maps the nTX RF transmit chains to the
    % nTXelements antenna elements.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also precoders.analog, precoders.analog.MIMO,
    % precoders.analog.NoAnalogPrecoding

    enumeration
        % FD-MIMO analog precoder according to 3GPP TR 38.901
        % Performs beamforming by mapping the transmit RF chains to antenna
        % elements so that a beam is formed.
        % In the 3GPP standard documents the RF chains are denoted as
        % transceiver units (TXRU).
        % Refer to the user manual for examples on how the TXRUs are mapped
        % to antenna elements in an antenna array.
        %
        % see also precoders.analog, precoders.analog.MIMO,
        % precoders.analog.AnalogPrecoderSuperclass
        MIMO   (1)

        % no analog precoder
        % If no analog precoding is performed, each transmit RF chain is
        % directly mapped to one antenna element.
        %
        % see also precoders.analog.NoAnalogPrecoding
        none  (2)
    end
end

