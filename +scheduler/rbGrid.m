classdef rbGrid < tools.HiddenHandle
    %RBGRID antenna scheduler signaling information
    % This class contains the information the scheduler provides for each
    % resource blocks at a base station.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also scheduler.Scheduler, parameters.resourceGrid.ResourceGrid,
    % scheduler.signaling.UserScheduling,
    % networkElements.bs.BaseStation.setDLsignaling

    properties
        % index of the scheduled user
        % [nRBFreq x nRBTime]integer id of the scheduled user
        %
        % see also networkElements.ue.User.id
        userAllocation

        % NOMA scheduler signaling
        % [1x1]handleObject scheduler.signaling.BaseStationNoma
        noma

        % allocated power for data
        % [nAnt x nRBFreq x nRBTime]double allocated power for data
        % networkElements.bs.BaseStation.setDLsignaling
        powerAllocation

        % CQI that is used for every resource block and Codeword
        % [nRBFreq x nRBTime x maxNCodewords]integer CQI that is used for every RB and Codeword
        CQI

        % precoder matrices
        % [nAnt x nRBFreq x nRBTime]struct with field W of precoder matrices
        % or [nRBFreq x nRBTime]double if accessed from the antenna, where
        % the information for the other antennas is discarded see
        % networkElements.bs.BaseStation.setDLsignaling
        %   -W: [nTX x nLayers]complex precoder for this resource block
        precoder = struct('W', 0);

        % number of transmission layers
        % [nRBFreq x nRBTime]integer number of transmission layers
        nLayers

        % number of codewords
        % [nRBFreq x nRBTime]integer number of codewords
        nCodewords

        % mask which defines which DL rb are accessable by a scheduler
        % [nRBFreq x nRBTime]integer
        rbGridMask

        % number of resource blocks in frequency
        % [1x1]integer
        nRBFreq

        % number of resource blocks in time
        % [1x1]integer
        nRBTime
    end

    methods
        function obj = rbGrid(BS, nRBFreq, nRBTime, maxNCodewords, maxNLayer)
            %RBGRID initialize instance of this class
            % Sets defaults values for no allocated resources.
            % This is used to initialize the resource grid
            %
            % input:
            %   BS:             [1x1]handleObject networkElements.bs.BaseStation
            %   nRBFreq:        [1x1]integer number of resource blocks in frequency
            %   nRBTime:        [1x1]integer number of resource blocks in time
            %   maxNCodewords:  [1x1]integer maximum number of codewords
            %   maxNLayer:      [1x1]integer maximum number of layers

            % get parameters
            nAnt            = BS.nAnt;
            transmitPower	= [BS.antennaList.transmitPower];
            alwaysOn        = [BS.antennaList.alwaysOn];
            obj.nRBFreq     = nRBFreq;
            obj.nRBTime     = nRBTime;
            % set default values
            obj.userAllocation	= -1 * ones(nRBFreq, nRBTime);
            obj.noma            = scheduler.signaling.BaseStationNoma(nRBFreq, nRBTime, maxNCodewords, maxNLayer);
            obj.CQI             = zeros(nRBFreq, nRBTime, maxNCodewords);
            obj.nLayers         =  ones(nRBFreq, nRBTime);
            obj.nCodewords      =  ones(nRBFreq, nRBTime);
            obj.rbGridMask      =  true(nRBFreq, nRBTime);

            % initialize precoder
            % Preallocation
            initPrecoder(1:nAnt,1:nRBFreq,1:nRBTime) = struct('W',1);
            %create default precoders for current BS
            for iAnt = 1:nAnt
                if BS.antennaList(iAnt).nTX ~= 1
                    actNTX = BS.antennaList(iAnt).nTX;
                    initPrecoder(iAnt,1:nRBFreq,1:nRBTime) = struct('W',1/sqrt(actNTX)*ones(actNTX,1));
                end
            end
            obj.precoder = initPrecoder;
            % set default power allocaton
            obj.powerAllocation	= (transmitPower .* double(alwaysOn)).' / nRBFreq .* ones(nAnt, nRBFreq, nRBTime);
        end

        function obj = reset(obj, BS)
            % resets the data of the resource grid
            %
            % input:
            %   BS:	[1x1]handleObject networkElements.bs.BaseStation

            % get parameters
            nAnt            = BS.nAnt;
            transmitPower	= [BS.antennaList.transmitPower];
            alwaysOn        = [BS.antennaList.alwaysOn];

            % reset to no allocated users
            obj.userAllocation	= -1 * ones(obj.nRBFreq, obj.nRBTime);
            obj.noma            = obj.noma.reset();
            obj.CQI             = zeros(size(obj.CQI));
            obj.nLayers         = ones(size(obj.nLayers));
            obj.nCodewords      = ones(size(obj.nCodewords));

            % set default power allocaton
            obj.powerAllocation	= (transmitPower .* double(alwaysOn)).' / obj.nRBFreq .* ones(nAnt, obj.nRBFreq, obj.nRBTime);

            % reset precoder - create default precoders for current BS
            for iAnt = 1:nAnt
                nTX = BS.antennaList(iAnt).nTX;
                obj.precoder(iAnt,:,:) = struct('W',ones(nTX,1)/sqrt(nTX));
            end
        end

        function obj = copy(obj)
            % copy method
        end

        function precoder = getAntennaPrecoder(obj, iAntenna, iRB)
            % returns precoders for given antenna and resource blocks
            %
            % input:
            %   iAntenna:   [1x1]integer index of antenna
            %   iRB:        [nRB x 1]integer linear indices of resource blocks
            %
            % output:
            %   precoder:   [nRB x 1]struct precoders
            %       -W: [nTX x nLayer]complex precoding matrix

            precoderFull	= squeeze(obj.precoder(iAntenna,:,:));
            precoder        = precoderFull(iRB);
        end
    end
end

