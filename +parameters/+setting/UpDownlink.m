classdef UpDownlink < uint32
    %UPDOWNLINK uplink/downlink state of transmission
    % Indicates if uplink or downlink transmission is performed.
    %
    % initial author: Agnes Fastenbauer

    enumeration
        % uplink
        % This means that the transmitter is a networkElements.ue.User and
        % the receiver is a networkElements.bs.Antenna or in a broader
        % sense a networkElements.bs.BaseStation.
        uplink      (1)

        % downlink
        % This means that the receiver is a networkElements.ue.User and
        % the transmitter is a networkElements.bs.Antenna or in a broader
        % sense a networkElements.bs.BaseStation.
        downlink    (2)
    end
end

