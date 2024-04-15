classdef BaseStationNoma < tools.HiddenHandle
    % scheduler signaling for noma information
    % This class contains the additional information necessary for a NOMA
    % transmission. This includes the NOMA power share allocated to the
    % near user, the NOMA user allocation and the CQI and number of
    % codewords used by the NOMA far user whose signal needs to be decoded
    % through SIC by the NOMA near user.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also scheduler.signaling.UserNoma,
    % scheduler.signaling.UserScheduling, scheduler.rbGrid,parameters.Noma
    %
    % NOMA: Non-Orthogonal Multiple Access

    properties
        % share of power allocated to the NOMA near user 0 ... 0.5
        % [nRBFreq x nRBTime x maxLayer]double NOMA power share (1 - alpha) allocated to the near user
        % If this is not 1, then there is a NOMA transmission.
        powerShare

        % index of the scheduled NOMA near user
        % [nRBFreq x nRBTime]integer index of the additional NOMA user
        % This is the index of the near user with good channel conditions.
        % This user will perform SIC.
        userAllocation

        % CQI of the NOMA near user
        % [nRBFreq x nRBTime x maxNCodewords]integer CQI that is used by the near user
        CQI

        % number of codewords transmitted by the NOMA near user
        % [nRBFreq x nRBTime]integer number of codewords
        nCodewords
    end

    methods
        function obj = BaseStationNoma(nRBFreq, nRBTime, maxNCodewords, maxNLayer)
            % initialize NOMA scheduling to OMA transmission, i.e. no NOMA
            %
            % input:
            %   nRBFreq:        [1x1]integer number of resource blocks in frequency
            %   nRBTime:        [1x1]integer number of resource blocks in time
            %   maxNCodewords:  [1x1]integer maximum number of codewords
            %   maxNLayer:      [1x1]integer maximum number of layers

            % set default values for no NOMA transmission
            obj.powerShare      = ones(nRBFreq, nRBTime, maxNLayer);	% no NOMA transmission
            obj.userAllocation	= -1 * ones(nRBFreq, nRBTime);          % no NOMA users
            obj.CQI             = zeros(nRBFreq, nRBTime, maxNCodewords);
            obj.nCodewords      = zeros(nRBFreq, nRBTime);
        end

        function obj = reset(obj)
            % reset to default values for no NOMA transmission
            %
            % see also scheduler.rbGrid

            obj.powerShare(:)       = 1;    % no NOMA transmission
            obj.userAllocation(:)	= -1;	% no NOMA users
            obj.CQI(:)              = 0;
            obj.nCodewords(:)       = 0;
        end
    end
end

