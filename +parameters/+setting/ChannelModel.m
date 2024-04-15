classdef ChannelModel < uint32
    %CHANNELMODEL enum of implemented channel model types
    % Different types of small scale fading types (AWGN, VehA, ...).
    %
    % The enum class definition allows switching between numerical values
    % and strings.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also smallScaleFading.ChannelFactory,
    % smallScaleFading.PDPchannelFactory, smallScaleFading.PDPcontainer

    enumeration
        % Pedestrian A
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "High Speed Downlink Packet Access: UE Radio Transmission and Reception"
        % 3GPP TR 25.890 V1.0.0 (2002-05)
        PedA        (1)

        % Pedestrian B
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "High Speed Downlink Packet Access: UE Radio Transmission and Reception"
        % 3GPP TR 25.890 V1.0.0 (2002-05)
        PedB        (2)

        % Vehicular A
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "High Speed Downlink Packet Access: UE Radio Transmission and Reception"
        % 3GPP TR 25.890 V1.0.0 (2002-05)
        VehA        (3)

        % Vehicular B
        %
        % "Further Results on CPICH Interference Cancellation as A Means
        % for Increasing DL Capacity"
        % TSG - RAN Working Group 1 meeting No. 18
        % TSGR1-01-0030
        VehB        (4)

        % Typical Urban
        %
        % Technical Specification Group GSM/EDGE Radio Access Network,
        % Radio transmission and reception, annex c.3 propagation models,
        % 3rd GenerationPartnership Project (3GPP),
        % Tech. Rep. TS 05.05 V.8.20.0 (Release 1999), 2009
        %
        % Universal Mobile Telecommunications System (UMTS)
        % "Deployment aspects"
        % 3GPP TR 25.943 version 9.0.0 Release 9
        TU          (5)

        % extended Pedestrian B
        %
        % ITU-T extended PedestrianB channel model. From "Extension of the
        % ITU Channel Models for Wideband (OFDM) Systems", Troels B.
        % S?rensen, Preben E. Mogensen, Frank Frederiksen
        extPedB     (6)

        % Rural Area
        %
        % Technical Specification Group GSM/EDGE Radio Access Network,
        % ?Radio transmission and reception, annex c.3 propagation models,?
        % 3rd GenerationPartnership Project (3GPP), Tech. Rep. TS 05.05
        % V.8.20.0 (Release 1999), 2009
        %
        % Universal Mobile Telecommunications System (UMTS)
        % "Deployment aspects"
        % 3GPP TR 25.943 version 9.0.0 Release 9
        RA          (7)

        % Hilly Terrain
        %
        % Technical Specification Group GSM/EDGE Radio Access Network,
        % ?Radio transmission and reception, annex c.3 propagation models,?
        % 3rd GenerationPartnership Project (3GPP), Tech. Rep. TS 05.05
        % V.8.20.0 (Release 1999), 2009
        %
        % Universal Mobile Telecommunications System (UMTS)
        % "Deployment aspects"
        % 3GPP TR 25.943 version 9.0.0 Release 9
        HT          (8)

        % Rayleigh
        Rayleigh    (9)

        % Additive White Gaussian Noise
        %
        % AWGN channel model type works only for SISO, which means one
        % transmit antenna and one receive antenna.
        AWGN        (10)

        % Quadriga Channel Model
        %
        % developed by the Fraunhofer HHI, see
        % https://quadriga-channel-model.de for further details.
        Quadriga    (11)
    end
end

