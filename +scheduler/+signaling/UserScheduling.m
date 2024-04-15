classdef UserScheduling < tools.HiddenHandle
    %USERSCHEDULING contains the scheduling information for a user
    % This class contains the scheduling information for a user, the
    % information is read out from the base station signaling and includes
    % the RB allocation, the number of codewords and layers used, the CQI
    % and the NOMA scheduling information.
    %
    % RB: Resource Block
    %
    % initial author: Agnes Fastenbauer
    % extended by   : Areen Shiyahin, added HARQ parameter
    %
    % see also scheduler.Scheduler, scheduler.signaling,
    % scheduler.signaling.UserNoma, networkElements.ue.User

    properties
        % linear indices of resource blocks assigned to this user
        % [nRBscheduled x 1]integer indices of assigned resource blocks
        assignedRBs

        % linear indices of resource blocks assigned to this user
        % in every slot
        % [1 x nSlotsTotal]cell
        % [nRBscheduled x 1]integer indices of assigned resource blocks
        assignedRBsBuffer

        % frequency indices of assigned resource blocks
        % [nRBscheduled x 1]integer indices in frequency of assigned resource blocks
        iRBFreq

        % time in of assigned resource blocks
        % [nRBscheduled x 1]integer indices in time of assigned resource blocks
        iRBTime

        % number of resource blocks assigned to this user
        % [1x1]integer number of scheduled resource blocks
        nRBscheduled

        % number of codewords used by this user
        % [1x1]integer number of codewords
        nCodeword

        % number of layers used by the precoder for this user
        % [1x1]integer number of layers
        nLayer

        % Channel Quality Indicator for all RBs assigned to this user
        % [1 x nCodewords]integer Channel Quality Indicator
        CQI

        % Channel Quality Indicator for all RBs assigned to this user in
        % every slot
        % [nCodewords x nTotalSlot]integer Channel Quality Indicator
        CQIBuffer

        % contains the difference between generation slot and
        % power share for NOMA transmission 0 ... 1
        % [nLayer x 1]double power share allocated to this user 0 ... 1
        % This is the percentage of power that is allocated to this user.
        % This is 1 for OMA transmission.
        % If this is smaller than 0.5, then SIC is performed and this user
        % is a NOMA near user.
        nomaPowerShare

        % scheduling information from other NOMA user
        % [1x1]handleObject scheduler.signaling.UserNoma
        noma

        % HARQ infromation of this user
        % [1x1]handleObject scheduler.signaling.HARQ
        HARQ
    end

    methods
        function obj = UserScheduling()
            %USERSCHEDULING constructs a class with default values
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters

            % no resource blocks are assigned by default
            obj.assignedRBs     = [];
            obj.iRBFreq         = [];
            obj.iRBTime         = [];
            obj.nRBscheduled	= 0;
            obj.assignedRBsBuffer = {};

            % set defaults to no transmission
            obj.nCodeword	= 0;
            obj.CQI         = [];
            obj.nLayer      = 1;
            obj.CQIBuffer   = [];

            % set NOMA transmssion defaults - no NOMA
            obj.nomaPowerShare	= 1;
            obj.noma            = scheduler.signaling.UserNoma;

            % set HARQ
            obj.HARQ            = scheduler.signaling.HARQ;
        end

        function setUserScheduling(obj, rbGrid, maxNCodewords, useHARQ)
            % set user signaling according to the scheduler information in rbGrid
            % This function should set all UserSchedulingProperties
            % according to the given rbGrid.
            %
            % input:
            %   rbGrid:         [1x1]object scheduler.rbGrid
            %   maxNCodewords:	[1x1]integer maximum number of codewords
            %   useHARQ:        [1x1] logical indicates if the scheduler uses HARQ or not

            if obj.nRBscheduled
                % set number of codewords and layers
                %NOTE: all RBs of a user, use the same number of codewords
                %and layers
                obj.nCodeword = rbGrid.nCodewords(obj.assignedRBs(1));
                obj.nLayer    = rbGrid.nLayers(obj.assignedRBs(1));

                % set CQI
                obj.CQI = zeros(1, maxNCodewords);
                obj.CQI(:) = rbGrid.CQI(obj.iRBFreq(1), obj.iRBTime(1), 1:maxNCodewords);
            else
                % reset the user signaling - no transmission
                obj.nCodeword	= 0;
                obj.nLayer      = 1;
                obj.CQI         = zeros(1, maxNCodewords);
            end

            % reset NOMA transmssion defaults - no NOMA
            obj.nomaPowerShare	= ones(obj.nLayer, 1);
            obj.noma            = scheduler.signaling.UserNoma;

            % store the indices of RBs and CQIs if a retransmission is
            % required
            if useHARQ
                obj.harqBuffer();
            end
        end

        function setUserAllocation(obj, userAllocation, userID)
            % read out user allocation
            %
            % input:
            %   userAllocation:	[nRBFreq x nRBTime]integer user ID assigned to each RB
            %   userID:         [1x1]integer ID of this user
            %
            % see also: scheduler.rbGrid.userAllocation,
            % networkElements.ue.User.id

            % find and set indices of resource blocks assigned to this user
            obj.assignedRBs             = find(userAllocation == userID);
            [obj.iRBFreq, obj.iRBTime]	= find(userAllocation == userID);
            obj.nRBscheduled            = size(obj.assignedRBs, 1);
        end

        function setNomaNearUserScheduling(obj, rbGrid, userID, nomaRBs)
            % set user scheduling for NOMA near users
            % This sets the user scheduling of the NOMA near user including
            % user allocation. This function reads in the NOMA scheduling
            % information from the rbGrid and sets the assigned resource
            % blocks from the input parameter to avoid recalculation of
            % this parameter.
            %
            % input:
            %   rbGrid:         [1x1]object scheduler.rbGrid
            %   userID:         [1x1]integer ID of this user
            %   nomaRBs:        [nNomaRB x 1]integer linear indices of NOMA RBs

            % set nCodeword and nLayer
            obj.nCodeword	= rbGrid.noma.nCodewords(nomaRBs(1));
            obj.nLayer      = rbGrid.nLayers(nomaRBs(1));

            % set assigned resource blocks
            % find and set indices of resource blocks assigned to this user
            [obj.iRBFreq, obj.iRBTime]	= find(rbGrid.noma.userAllocation == userID);
            % write user allocation information in user scheduling
            obj.assignedRBs     = nomaRBs;
            obj.nRBscheduled	= size(nomaRBs, 1);

            % get number of codewords used by the NOMA far user
            obj.noma.nCodeword = rbGrid.nCodewords(nomaRBs(1));

            % set CQI and noma CQI of far user
            obj.CQI         = zeros(1, obj.nCodeword);
            obj.CQI(:)      = rbGrid.noma.CQI(obj.iRBFreq(1), obj.iRBTime(1), 1:obj.nCodeword);
            obj.noma.CQI    = zeros(1, obj.nCodeword);
            obj.noma.CQI(:)	= rbGrid.CQI(obj.iRBFreq(1), obj.iRBTime(1), 1:obj.noma.nCodeword);

            % set NOMA power share
            obj.nomaPowerShare = zeros(obj.nLayer, 1);
            obj.nomaPowerShare(:) = rbGrid.noma.powerShare(obj.iRBFreq(1), obj.iRBTime(1), 1:obj.nLayer);
        end

        function struct = toStruct(obj)
            % return struct with user scheduling information
            % This function returns a struct with the important user
            % scheduling information. Derived properties like iRBFreq,
            % iRBTime and nRBscheduled are not included in the struct, they
            % can be recalculated if necessary. The NOMA parameters can be
            % derived from the nomaPowerShare.
            % This function is used to save the user scheduling as
            % additional result.
            %
            % output:
            %   struct: [1x1]struct with elementary user scheduling
            %       -assignedRBs:       [1 x nAssignedRBs]integer indices of assigned resource blocks
            %       -nCodeword:         [1x1]integer number of codewords
            %       -CQI:               [1 x nCodeword]integer Channel Quality Indicator
            %       -nLayer:            [1x1]integer number of layers
            %       -nomaPowerShare:    [nLayer x 1]double power share assigned to this user in this resource block
            %       -noma:              [1x1]struct scheduler.signaling.UserNoma.toStruct
            %
            % see also parameters.SaveObject.userScheduling

            struct.assignedRBs      = obj.assignedRBs;
            struct.nCodeword        = obj.nCodeword;
            struct.CQI              = obj.CQI;
            struct.nLayer           = obj.nLayer;
            struct.nomaPowerShare	= obj.nomaPowerShare;
            struct.noma             = obj.noma.toStruct;
            struct.HARQ             = obj.HARQ.toStruct;
        end

        function retransmissionCQI = getUserCQI(obj, feedbackDelay,iCW)
            % return the CQI used in the origianl transmission slot of
            % this codeword for this user
            %
            % input:
            %   feedbackDelay: [1x1]integer feedback delay in slots
            %   iCW:           [1x1]integer index of codeword
            %
            % output:
            %   retransmissionCQI: [1x1]integer Channel Quality Indicator
            %
            % initial author: Areen Shiyahin

            CQIBufferLength   = size(obj.CQIBuffer,2);
            columnIndex       = CQIBufferLength-(feedbackDelay-1);
            allCodewordsCQI   = obj.CQIBuffer(:,columnIndex);
            retransmissionCQI = allCodewordsCQI(iCW);
        end

        function retransmissionRBs = getUserAllocation(obj, feedbackDelay)
            % return linear indices of resource blocks assigned to this user
            % at the origianl transmission slot
            %
            % input:
            %   feedbackDelay: [1x1]integer feedback delay in slots
            %
            % output:
            %   assignedRBs:   [nRBscheduled x 1]integer indices of assigned resource blocks
            %
            % initial author: Areen Shiyahin

            RBsBufferLength   = size(obj.assignedRBsBuffer,2);
            RBsIndex          = RBsBufferLength-(feedbackDelay-1);
            retransmissionRBs = obj.assignedRBsBuffer{RBsIndex};
        end

        function harqBuffer(obj)
            % store the indices of RBs and CQIs
            % assigned to this user over all slots
            %
            % initial author: Areen Shiyahin

            obj.assignedRBsBuffer = [obj.assignedRBsBuffer(:)', {obj.assignedRBs}];
            obj.CQIBuffer         = [obj.CQIBuffer, obj.CQI'];
        end
    end
end

