classdef UserNoma < tools.HiddenHandle
    % scheduler signaling for noma information at the user
    % This class contains the additional scheduler information necessary
    % for performing SIC at the NOMA near user. It contains the MCS
    % information of the NOMA far user that is necessary for the near user
    % to receive the signal of the far user for SIC.
    %
    % NOMA: Non-Orthogonal Multiple Access
    % SIC:  Successive Interference Cancellation
    %
    % initial author: Agnes Fastenbauer
    %
    % see also scheduler.rbGrid, scheduler.Scheduler, scheduler.rbGrid,
    % scheduler.signaling.UserScheduling

    properties
        % Channel Quality Indicator of the NOMA far user
        % [1 x nCodewords]integer CQI of the NOMA far user for SIC
        CQI

        % number of codewords used by NOMA far user
        % [1x1]integer number of codewords used by NOMA far user
        nCodeword
    end

    methods
        function obj = UserNoma()
            % initialize NOMA signalling to default values for no NOMA transmission

            % set default values
            obj.CQI         = [];
            obj.nCodeword	= 0;
        end

        function struct = toStruct(obj)
            % Write additonal NOMA scheduler signaling into a struct.
            %
            % output:
            %   struct: [1x1]struct with elementary user scheduling
            %       -CQI:           [nNomaRBs x nCodewords]integer Channel Quality Indicator of the other NOMA user
            %       -nCodewords:    [1x1]integer number of codewords used by other NOMA user
            %
            % see also scheduler.signaling.UserScheduling.toStruct

            struct.CQI          = obj.CQI;
            struct.nCodeword	= obj.nCodeword;
        end
    end
end

