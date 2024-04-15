classdef ChunkResult < tools.HiddenHandle
    %ChunkResult is the result of a ChunkSimulation
    % All of the results generated by ChunkSimulation have to saved into
    % this result class.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.ChunkSimulation

    properties
        % simulation parameters
        % [1x1]handleObject parameters.Parameters
        params

        % new segment indicator for all slots
        % [1 x nSlots]logical indicates if slot is first in a segment
        % true: this slot is the first in a new segment, the macroscopic parameters have been updated
        % false: this slot is in the same segment as the previous slot
        isNewSegment

        % total number of segments
        % [1x1]integer toatl number of segments in this chunk
        nSegment

        % [nUserRoi x nSlots]double downlink lite SNR for each user
        %
        % see also simulation.ChunkSimulation.liteSnrDLdB
        liteSnrDLdB

        % [nUserRoi x nSlots]double uplink lite SNR for each user
        %
        % see also simulation.ChunkSimulation.liteSnrULdB
        liteSnrULdB

        % [nUserRoi x nSlots]double downlink lite SINR for each user
        %
        % see also simulation.ChunkSimulation.liteSinrDLdB
        liteSinrDLdB

        % [nUserRoi x nSlots]double uplink lite SINR for each user
        %
        % see also simulation.ChunkSimulation.liteSinrULdB
        liteSinrULdB

        % wideband SINR in dB
        % [nUsers x nSegment]double wideband SINR in dB
        % The wideband SINR considers all macroscopic fading parameters,
        % but no small scale fading, no precoding, no scheduling.
        %
        % see also cellManagement.CellAssociation.setCellAssociationTable
        widebandSinrdB
        
        %by Nico Kabongo
        
        LoadCell
        
        debit
        
        debitOff
        
        trace1
        
        %---------------

        % trace with simulation results for this chunk
        % [nSlotsPerChunk x 1]cell with structs of traces of each chunk
        %   -throughputUser:    [nUser x 1]struct with throughput
        %       *DL:    [nUser x 1]double downlink throughput of each user
        %               %NOTE: this is empty, but still there if the user
        %               is an interference region user
        %	-effectiveSinr:     [1x1]struct
        %      	*DL:    [nUser x 1]double
        %	-feedback:          [1x1]struct
        %      	*DL:    [nUser x 1]cell
        %	-userScheduling:    [1x1]struct
        %     	*DL:    [nUser x 1]cell
        %
        % see also simulation.results.TemporaryResult
        trace

        % packets transmission Latency
        % [nUser x 1]cell
        % [1 x nPackets]double transmission latency result for each chunk
        % contains the difference between generation slot and
        % successful transmission slot of individual packets
        transmissionLatency = {};

        % network elements and network geometry simulation setup
        % [1x1]struct collects the chunk network configuration in a struct
        % This is 0 for no network post processors or a struct with the
        % different network element arrays for other postprocessors.
        %
        % see also simulation.postprocessing.PostprocessorSuperclass.collectFullNetworkSetup
        networkSetup

        % cell association table
        % [nUsers x nSegment]integer index of base station this user is associated to
        %
        % Example: the first user is attached to the first base station in
        % the first segment and to the second base station from the second
        % segment onwards. Then, the first line of the userToBSassignment
        % will be [1 2 2 2 2 2], assuming there are 5 segments in a chunk.
        %
        % see also cellManagement.CellAssociation.userToBSassignment,
        % tools.AntennaBsMapper.getBSindex
        userToBSassignment

        % additional parameters that are saved
        % [1x1]struct with additional parameters to be saved
        %   losMap:             [nAntennas x nUsers x nWalls x nSegment]logical table indicating links blocked by walls
        %   isIndoor:           [nUsers x nSlots]logical indicator for indoor users
        %   antennaBsMapper:    [1x1]handleObject tools.AntennaBsMapper
        %   pathlossTableDL:    [nAntennas x nUsers x nSegment]double pathloss for all possible links in dB
        %   macroscopicFadingdB:[nAntennas x nUsers x nSegment]double macroscopic fading for all possible links in dB
        %   wallLossdB:         [nAntennas x nUsers x nSegment]double wall loss for all possible links in dB
        %   shadowFadingdB:     [nAntennas x nUsers x nSegment]double sahdow fading for all possible links in dB
        %   antennaGaindB:      [nAntennas x nUsers x nSegment]double antenna gain for all possible links in dB
        %   receivePowerdB:     [nAntennas x nUsers x nSegment]double receive power for all possible links in dB
        %
        % see also parameters.SaveObject
        addition = struct();
    end

    properties (Dependent)
        % number of users
        % [1x1]integer total number of users
        nUser
    end

    methods
        function nUser = get.nUser(obj)
            % get number of users in simulation
            %
            % output:
            %   nUser:  [1x1]integer total number of users

            nUser = size(obj.widebandSinrdB, 1);
        end
    end

    methods (Static)
        function chunkResult = getChunkResult(ChunkSimulation)
            % puts together the chunk result class as return object for the ChunkSimulation
            % This function collects the settings and results from
            % ChunkSimulation in a single object that is returned by
            % runSimulation.
            %
            % input:
            %   ChunkSimulation:    [1x1]handleObject simulation.ChunkSimulation
            %
            % output:
            %   chunkResult:    [1x1]handleObject simulation.ChunkResult
            %
            % see also simulation.ChunkResult,
            % simulation.ChunkSimulation.runSimulation

            % create chunk result
            chunkResult = simulation.ChunkResult;

            % save basic configuration
            chunkResult.liteSnrDLdB         = ChunkSimulation.liteSnrDLdB(ChunkSimulation.isUserRoi, :);
            chunkResult.liteSnrULdB         = ChunkSimulation.liteSnrULdB(ChunkSimulation.isUserRoi, :);
            chunkResult.liteSinrDLdB        = ChunkSimulation.liteSinrDLdB(ChunkSimulation.isUserRoi, :);
            chunkResult.liteSinrULdB        = ChunkSimulation.liteSinrULdB(ChunkSimulation.isUserRoi, :);
            chunkResult.trace               = ChunkSimulation.trace;
            chunkResult.networkSetup        = ChunkSimulation.postprocessor.collectNetworkSetup(ChunkSimulation);
            chunkResult.params              = ChunkSimulation.chunkConfig.params;
            chunkResult.isNewSegment        = ChunkSimulation.chunkConfig.isNewSegment;
            chunkResult.nSegment            = ChunkSimulation.nSegment;
            chunkResult.userToBSassignment  = ChunkSimulation.cellManager.userToBSassignment;
            chunkResult.widebandSinrdB      = ChunkSimulation.widebandSinrdB;
            %by Nico Kabongo
            chunkResult.LoadCell            = ChunkSimulation.LoadCell;
            chunkResult.debit            = ChunkSimulation.debit;
            chunkResult.debitOff            = ChunkSimulation.debitOff;
            chunkResult.trace1               = ChunkSimulation.trace1;
            %---------------

            % set latency results for all users
            chunkResult.transmissionLatency = cell(ChunkSimulation.nUsers, 1);
            for iUE = 1:ChunkSimulation.nUsers
                chunkResult.transmissionLatency{iUE} = ChunkSimulation.users(iUE).trafficModel.getTransmissionLatency;
            end

            % save optional results
            if ChunkSimulation.chunkConfig.params.save.losMap
                chunkResult.addition.losMap = ChunkSimulation.pathLossManager.blockageMapUserAntennas;
            end

            if ChunkSimulation.chunkConfig.params.save.isIndoor
                chunkResult.addition.isIndoor = ChunkSimulation.pathLossManager.isIndoor;
            end

            if ChunkSimulation.chunkConfig.params.save.antennaBsMapper
                chunkResult.addition.antennaBsMapper = ChunkSimulation.chunkConfig.antennaBsMapper;
            end

            if ChunkSimulation.chunkConfig.params.save.macroscopicFading
                chunkResult.addition.macroscopicFadingdB = ChunkSimulation.macroscopicFadingdB;
            end

            if ChunkSimulation.chunkConfig.params.save.pathlossTable
                chunkResult.addition.pathlossTableDL = ChunkSimulation.pathLossTableDL;
            end

            if ChunkSimulation.chunkConfig.params.save.wallLoss
                chunkResult.addition.wallLossdB = ChunkSimulation.wallLossdB;
            end

            if ChunkSimulation.chunkConfig.params.save.shadowFading
                chunkResult.addition.shadowFadingdB = ChunkSimulation.shadowFadingdB;
            end

            if ChunkSimulation.chunkConfig.params.save.antennaGain
                chunkResult.addition.antennaGaindB = ChunkSimulation.antennaGaindB;
            end

            if ChunkSimulation.chunkConfig.params.save.receivePower
                chunkResult.addition.receivePowerdB = ChunkSimulation.receivePowerdB;
            end
        end
    end
end
