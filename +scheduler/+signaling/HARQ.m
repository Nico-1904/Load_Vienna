classdef HARQ < tools.HiddenHandle
    %HARQ Class initiates retransmissions from the base station to
    % the user in case of transmission failure.
    % Transmission errors are declared by non-acknowlegdment in the user
    % feedback. Retransmissions can be done on codeword basis. In this class,
    % the redundancy version, which is the set of coded bits used in
    % retransmission, is set. There can be 3 different redundancy versions
    % corresponding to the maxmimum number of retransmissions that could be
    % done for a codeword
    %
    % initial author: Areen Shiyahin
    %
    % see also +scheduler.signaling.UserScheduling
    % scheduler.Scheduler
    % parameters.transmissionParameters.TransmissionParameters

    properties
        % redundancy version of codewords
        % [1xnCodewords] double redundancy version used in the retransmission
        % of each codeword. Redundancy version 0 means no retransmission.
        % If a transmission fails, there could be 1st, 2nd or 3rd
        % retransmissions
        codewordRV
    end

    methods
        function obj = HARQ()
            % class constructor with default values

            % set parameter
            obj.codewordRV = zeros(1,2);
        end

        function RV = initiateRetransmission(obj,cwAcknowledgment)
            % increase the redundancy version if a retransmission
            % is required and reset it if the maximum number of
            % retransmissions is reached
            %
            % input:
            %   cwAcknowledgment: [1x nCodewords]double acknowledgment about
            %                     codeword transmission
            % output:
            %   RV: [1x nCodewords]double redundancy versions of both codewords

            % get number of codewords
            nCodewords = length(obj.codewordRV);

            for iCW = 1:nCodewords
                if ~cwAcknowledgment(iCW)
                    obj.codewordRV(iCW) = obj.codewordRV(iCW) + 1;

                    % when the maximum number of retransmissions is reached, reset
                    % the redundancy version of this codeword
                    if obj.codewordRV(iCW) > 3
                        obj.resetRV(iCW)
                    end
                else
                    obj.resetRV(iCW)
                end
            end

            RV = obj.codewordRV;
        end

        function resetRV(obj,cwIndex)
            % reset this codeword's redundancy version

            obj.codewordRV(cwIndex) = 0;
        end

        function resetRVs(obj)
            % reinitialize the redundancy versions

            obj.codewordRV = zeros(1,2);
        end

        function struct = toStruct(obj)
            % write HARQ signaling into a struct.
            %
            % output:
            %   struct: [1x1]struct with HARQ infromation
            %       - codewordRV: [1xnCodewords] double redundancy version used in the retransmission of this user
            %
            %
            % see also scheduler.signaling.UserScheduling.toStruct

            struct.codewordRV  = obj.codewordRV;
        end

        function checkParametersHARQ(obj)
            % check parameters compability

            if any(obj.codewordRV)
                warning("HARQ:RVCompatibility", ...
                    "Default redundaucy version for any codeword must be zero.");
            end
        end
    end
end

