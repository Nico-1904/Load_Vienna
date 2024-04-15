classdef TrafficModelType < uint32
    % TrafficModelType enum of implemented traffic models
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels

    enumeration
        % Full Buffer model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "Evolved Universal Terrestrial Radio Access (E-UTRA);
        % Further advancements for E-UTRA physical layer aspects"
        % 3GPP TR 36.814 V9.2.0 (2017-03)
        %
        % Full buffer users have infinte amount of data to be transmitted during the
        % whole simulation duration.
        %
        % see also trafficModels.FullBuffer
        FullBuffer     (1)

        % Constant Rate model
        %
        % see also trafficModels.ConstantRate
        ConstantRate   (2)

        % File Transfer Protocol model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "LTE physical layer framework for performance verification"
        % TSG - RAN Working Group 1 meeting No. 48
        % TSG-RAN1-070674
        %
        % see also trafficModels.FTP
        FTP     (3)

        % Hypertext Transfer Protocol model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "LTE physical layer framework for performance verification"
        % TSG - RAN Working Group 1 meeting No. 48
        % TSG-RAN1-070674
        %
        % see also trafficModels.HTTP
        HTTP     (4)

        % Video Streaming model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "LTE physical layer framework for performance verification"
        % TSG - RAN Working Group 1 meeting No. 48
        % TSG-RAN1-070674
        %
        % see also trafficModels.VideoStreaming
        Video     (5)

        % Gaming model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "LTE physical layer framework for performance verification"
        % TSG - RAN Working Group 1 meeting No. 48
        % TSG-RAN1-070674
        %
        % see also trafficModels.Gaming
        Gaming    (6)

        % VoIP model
        %
        % 3rd Generation Partnership Project
        % Technical Specification Group Radio Access Network
        % "LTE physical layer framework for performance verification"
        % TSG - RAN Working Group 1 meeting No. 48
        % TSG-RAN1-070674
        %
        % see also trafficModels.VoIP
        VoIP    (7)
    end
end

