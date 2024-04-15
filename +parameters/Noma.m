classdef Noma < tools.HiddenHandle
    % parameters for NOMA transmission
    % This class defines the MUST mode and sets the interference
    % cancellation factor, that indicates how much interference remains
    % after a SIC.
    %
    % To use NOMA transmissions in a simulation a mustIdx mode different
    % from 00 must be chosen. Then, after the cell association each BS
    % pairs its users to NOMA pairs if  their cell association metric
    % differs less than deltaPairdB. The users in a NOMA pair then share
    % their scheduled resources and both users are served simultaneously.
    % To receive their signal the NOMA near users, that are closer to the
    % BS, perform SIC, i.e. they decode the signal of the NOMA far user,
    % remove from the received signal and then decode their own signal.
    % This process is handled by the successiveInterferenceCancellation in
    % the link quality model.
    %
    % MUST: MultiUser Superposition Transmission
    % NOMA: Non-Orthogonal Multiple Access
    % SIC:  Successive Interference Cancellation
    %
    % initial author: Agnes Fastenbauer
    %
    % see also
    % linkQualityModel.LinkQualityModel.successiveInterferenceCancellation,
    % scheduler.NomaScheduler, scheduler.signaling.BaseStationNoma,
    % scheduler.signaling.UserNoma, parameters.setting.MUSTIdx,
    % cellManagement.CellAssociation.nomaUserPairing

    properties
        % epsilon - indicates how much interference is left after SIC
        % [1x1]double interference cancellation factor 0...1
        % 0 is full cancellation and 1 is no cancellation
        %
        % If this is larger than 0, then the NOMA near user experiences
        % interference from the far user transmission.
        %
        % SIC: Successive Interference Cancellation
        %
        % see also linkQualityModel.LinkQualityModel.successiveInterferenceCancellation
        interferenceFactorSic = 0;

        % minimum difference in cell association metric for two users to be
        % paired for a NOMA transmission
        % [1x1]double minimum power difference between paired NOMA users
        %
        % see also cellManagement.CellAssociation.nomaUserPairing
        deltaPairdB = 15;

        % MUST index
        % [1x1]enum parameters.setting.MUSTIdx
        % The power share factor is chosen according to the MUST index and
        % 3GPP TS 36.211 Table 6.3.3-1. MUST index 0 indicates no NOMA
        % transmission, only OMA.
        %
        % MUST: MultiUser Superposition Transmission
        % NOMA: Non-Orthogonal Multiple Access
        % OMA:  Orthogonal Multiple Access
        %
        % see also scheduler.NomaScheduler, parameters.setting.MUSTIdx
        mustIdx = parameters.setting.MUSTIdx.Idx00;

        % indicator to abort NOMA transmission if CQI is too low
        % [1x1]logical indicator to abort low channel quality transmission
        %
        % If this parameter is set to true, the NOMA transmission is
        % cancelled if the far user CQI indicated by the feedback is lower
        % than 6. This serves to avoid making transmissions that are
        % expected to fail.
        abortLowCqi = false;
    end
end

