classdef PostprocessorSuperclass < tools.HiddenHandle
    %POSTPROCESSOR is the baseclass for all postprocessors
    % it is used to 1) extract the desired results into the chunkresult
    %               2) combine chunkresults to the right result object
    %
    %NOTE: all postprocessor with superclass in the name cannot be
    %instantiated
    %NOTE: it is assumend that the number of users is constant over all
    %chunks
    %
    % initial author: Lukas Nagel

    methods(Static, Abstract)
        % those methods need to be implemented by all postprocessors

        % creates the result from all chunkresults
        result = combineResults(obj, chunkResultList)

        % collects basestations, users, for later processing/plotting
        networkSetup = collectNetworkSetup(obj, simulationObject)

        % Estimate size of simulation results in bytes
        % input:
        %   params: [1x1]parameters.Parameters
        % output:
        %   mem:    [1x1]double estimated result size in bytes
        mem = estimateResultSize(params);
    end

    methods (Static)
        % the postprocessor baseclass provides several static methods that
        % should be used by its subclasses to implement the abstract
        % methods.
        % most methods are used in multiple postprocessors so they are
        % concentrated here to simplify later changes

        function throughputUser = extractUserThroughput(chunkResultList)
            % extracts user throughput from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   throughputUser: [1x1]struct with results
            %       DL: [nUserROI x nSlotsValidTotal]integer user throughput in bit

            % get parameter object
            params = chunkResultList(1).params;

            % get feedback delay
            feedbackDelay = params.time.feedbackDelay;

            % get total number of time slots that are relevant for throughput calculation
            % The slots before feedback is initialized are discarded for
            % every chunk.
            validSlotsPerChunk = params.time.slotsPerChunk - feedbackDelay;
            nSlotsTotal	= validSlotsPerChunk * params.time.numberOfChunks;

            % get total number of users
            nUser = length([chunkResultList(1).trace{1}.throughputUser.DL]);

            isInROI = false(nSlotsTotal, nUser);

            % initialize result
            throughputUser.DL = NaN(nUser, nSlotsTotal);
            throughputUser.DLBestCQI = NaN(nUser, nSlotsTotal);

            % extract user throughput
            tt = 1;
            for iChunk = 1:params.time.numberOfChunks

                % check if users stay in ROI or interference region
                isInROItotal = reshape([chunkResultList(iChunk).networkSetup.userList.isInROI], [params.time.slotsPerChunk nUser]);
                isInROI(((iChunk-1)*validSlotsPerChunk+1):((iChunk-1)*validSlotsPerChunk+validSlotsPerChunk),:) = isInROItotal((feedbackDelay+1):end,:);

                % the first 'feedbackDelay' slots are discarded
                for ss = (feedbackDelay+1):params.time.slotsPerChunk
                    throughputUser.DL(:,tt) = [chunkResultList(iChunk).trace{ss}.throughputUser.DL].';
                    throughputUser.DLBestCQI(:,tt) = [chunkResultList(iChunk).trace{ss}.throughputUser.DLBestCQI].';
                    tt = tt + 1;
                end % for all slots
            end % for all chunks

            if ~(all(all(isInROI, 1) | ~any(isInROI, 1)))
                error('Result handling for users that move from the ROI to the interference region is not implemented yet.');
            end % if users move between ROI and interference region

            % remove interference region user results (results are empty)
            throughputUser.DL = throughputUser.DL(isInROI(1,:).',:);
            throughputUser.DLBestCQI = throughputUser.DLBestCQI(isInROI(1,:).',:);
        end

        function effectiveSinr = extractEffectiveSinr(chunkResultList)
            % extract effective SINR from chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   effectiveSinr:  [1x1]struct effective SINR
            %       -DL:    [nUser x nSlotsTotal]double effective SINR downlink

            params = chunkResultList(1).params;
            nSlotsTotal = params.time.slotsPerChunk * params.time.numberOfChunks;
            nUser = chunkResultList(1).nUser;
            effectiveSinr.DL = zeros(nUser, nSlotsTotal);

            iSlot = 1;
            for iChunk = 1:params.time.numberOfChunks
                for iSlotChunk = 1:params.time.slotsPerChunk
                    effectiveSinr.DL(:,iSlot) = [chunkResultList(iChunk).trace{iSlotChunk}.effectiveSinr.DL];
                    iSlot = iSlot + 1;
                end
            end
        end

        function effectiveBLER = extractBLER(chunkResultList)

            params = chunkResultList(1).params;
            nTime = params.time.slotsPerChunk * params.time.numberOfChunks;
            nUser = chunkResultList(1).nUser;
            effectiveBLER.DL = zeros(nUser, nTime);

            tt = 1;
            for nn = 1:params.time.numberOfChunks
                for ss = 1:params.time.slotsPerChunk
                    effectiveBLER.DL(:,tt) = [chunkResultList(nn).trace{ss}.BLER.DL];
                    tt = tt + 1;
                end
            end
        end

        function [liteSinrDLdB, liteSinrULdB, liteSnrDLdB, liteSnrULdB] = extractLiteSINRandSNR(chunkResultList)
            % extract the downlink/uplink SINR from all chunks
            %
            % input:
            %   chunkResultList:	[1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   liteSinrDLdB:   [nUserRoi x nSlotsTotal]double lite DL SINR for each user in each time slot
            %   liteSinrULdB:   [nUserRoi x nSlotsTotal]double lite UL SINR for each user in each time slot
            %   liteSnrDLdB:    [nUserRoi x nSlotsTotal]double lite DL SNR for each user in each time slot
            %   liteSnrULdB:    [nUserRoi x nSlotsTotal]double lite UL SNR for each user in each time slot

            liteSinrDLdB    = [chunkResultList.liteSinrDLdB];
            liteSinrULdB    = [chunkResultList.liteSinrULdB];
            liteSnrDLdB     = [chunkResultList.liteSnrDLdB];
            liteSnrULdB     = [chunkResultList.liteSnrULdB];
        end

        function widebandSinrdB = extractWidebandSinr(chunkResultList)
            % extract wideband SINR from all chunks
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   widebandSinrdB: [nUser x nSegmentsTotal]double wideband SINR for each user in each segment

            widebandSinrdB = [chunkResultList.widebandSinrdB];
        end
        %by Nico Kabongo
        function LoadCell = extractLoadCell(chunkResultList)
            LoadCell = [chunkResultList.LoadCell];
        end
        
        function debit = extractUserDebit(chunkResultList)

            debit = [chunkResultList.debit];
        end
        
        function throughputUser = extractUserThroughput1(chunkResultList)

            params = chunkResultList(1).params;

            % get feedback delay
            feedbackDelay = params.time.feedbackDelay;

            % get total number of time slots that are relevant for throughput calculation
            % The slots before feedback is initialized are discarded for
            % every chunk.
            validSlotsPerChunk = params.time.slotsPerChunk - feedbackDelay;
            nSlotsTotal	= validSlotsPerChunk * params.time.numberOfChunks;

            % get total number of users
            nUser = length([chunkResultList(1).trace1{1}.throughputUser.DL]);

            isInROI = false(nSlotsTotal, nUser);

            % initialize result
            throughputUser.DL = NaN(nUser, nSlotsTotal);
            throughputUser.DLBestCQI = NaN(nUser, nSlotsTotal);

            % extract user throughput
            tt = 1;
            for iChunk = 1:params.time.numberOfChunks

                % check if users stay in ROI or interference region
                isInROItotal = reshape([chunkResultList(iChunk).networkSetup.userList.isInROI], [params.time.slotsPerChunk nUser]);
                isInROI(((iChunk-1)*validSlotsPerChunk+1):((iChunk-1)*validSlotsPerChunk+validSlotsPerChunk),:) = isInROItotal((feedbackDelay+1):end,:);

                % the first 'feedbackDelay' slots are discarded
                for ss = (feedbackDelay+1):params.time.slotsPerChunk
                    throughputUser.DL(:,tt) = [chunkResultList(iChunk).trace1{ss}.throughputUser.DL].';
                    throughputUser.DLBestCQI(:,tt) = [chunkResultList(iChunk).trace1{ss}.throughputUser.DLBestCQI].';
                    tt = tt + 1;
                end % for all slots
            end % for all chunks

            if ~(all(all(isInROI, 1) | ~any(isInROI, 1)))
                error('Result handling for users that move from the ROI to the interference region is not implemented yet.');
            end % if users move between ROI and interference region

            % remove interference region user results (results are empty)
            throughputUser.DL = throughputUser.DL(isInROI(1,:).',:);
            throughputUser.DLBestCQI = throughputUser.DLBestCQI(isInROI(1,:).',:);
        end
        
        %-------------

        function isNewSegment = extractIsNewSegment(chunkResultList)
            % extract wideband SINR from all chunks
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   isNewSegment:   [1 x nSlotsTotal]logical indicates if slot is first in a segment

            isNewSegment = [chunkResultList.isNewSegment];
        end

        function transmissionLatency = extractTransmissionLatency(chunkResultList)
            % extract packets latency for users from all chunks results
            %
            % input:
            %   chunkResultList:     [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   transmissionLatency: [nUser x nChunk]cell
            %                        [1x nPackets]double transmission latency for each user
            %
            % initial author: Areen Shiyahin

            % get parameters
            params = chunkResultList(1).params;
            nChunkTotal = params.time.numberOfChunks;

            % get number of users
            nUser = chunkResultList(1).nUser;

            % initialize latency results
            transmissionLatency = cell(nUser, nChunkTotal);

            % get latency results for all chunks
            ii = 1;
            for cc = 1:params.time.numberOfChunks
                transmissionLatency(:,ii) = {chunkResultList(cc).transmissionLatency{:}};
                ii = ii + 1;
            end
        end

        function userToBSassignment = extractUserToBSassignment(chunkResultList)
            % extract assigned base station map
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   userToBSassignment: [nUsers x nSegmentsTotal]integer index of base station this user is associated to

            userToBSassignment = [chunkResultList.userToBSassignment];
        end

        function feedback = extractFeedback(chunkResultList)
            % extract feedback from chunk result list
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   feedback:   [1x1]struct user feedback
            %       -DL:    [nUser x nSlotsTotal]cell downlink user feedback

            params = chunkResultList(1).params;
            nUser = chunkResultList(1).nUser;
            tempfeedback.DL = cell(nUser, params.time.nSlotsTotal);

            tt = 1;
            for nn = 1:params.time.numberOfChunks
                for ss = 1:params.time.slotsPerChunk
                    tempfeedback.DL(:,tt) = chunkResultList(nn).trace{ss}.feedback.DL;
                    tt = tt + 1;
                end
            end
            feedback.DL = cell2mat(tempfeedback.DL);
        end

        function userScheduling = extractUserScheduling(chunkResultList)
            % extract user scheduling information from slot traces and combine chunk results
            %
            % input:
            %
            % output:
            %   userScheduling: [1x1]struct
            %       -DL:    [nUser x nSlotsTotal]struct with downlink user scheduling
            %
            % see also scheduler.signaling.UserScheduling.toStruct,
            % scheduler.signaling.UserScheduling

            % get parameters
            params      = chunkResultList(1).params;
            nSlotsTotal	= params.time.nSlotsTotal;
            nUser       = chunkResultList(1).nUser;

            % initialize output
            userScheduling.DL = cell(nUser, nSlotsTotal);

            % extract user scheduling results for each time slot
            iTime = 1;
            for iChunk = 1:params.time.numberOfChunks
                for iSlot = 1:params.time.slotsPerChunk
                    userScheduling.DL(:,iTime) = chunkResultList(iChunk).trace{iSlot}.userScheduling.DL;
                    iTime = iTime + 1;
                end
            end
        end

        function networkElements = extractNetworkElements(chunkResultList)
            % extracts all network elements from all chunks
            % The blockages should be same for all chunks, they are saved
            % from the first chunk and the other blockage objects are
            % discarded.
            % For the network elements, the positions are saved for all
            % slots and for the users isInROI is additionally saved for all
            % slots.
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   networkElements:    [1x1]struct with lists of network elements
            %       -buildingList:      [1 x nBuildings]handleObject blockages.Building
            %       -wallBlockageList:  [1 x nWallBlockages]handleObject blockages.WallBlockage
            %       -streetSystemList:  [1x1]handleObject blockages.StreetSystem
            %       -baseStationList:   [1 x nBS]handleObject networkElements.bs.BaseStation
            %       -userList:          [1 x nUser]handleObject networkElements.ue.User

            % initialize output:
            networkElements = struct;

            % get number of chunks in this simulation
            nChunks = length(chunkResultList);

            % obtain the elements which are the same for all chunks
            networkElements.buildingList = chunkResultList(1).networkSetup.buildingList;
            networkElements.wallBlockageList = chunkResultList(1).networkSetup.wallBlockageList;
            networkElements.streetSystemList = chunkResultList(1).networkSetup.streetSystemList;

            % get number of network elements - base station and users
            nBS = length(chunkResultList(1).networkSetup.baseStationList);
            nUE = length(chunkResultList(1).networkSetup.userList);

            % copy network elements
            for bb = 1:nBS
                combinedBaseStationList(bb) = chunkResultList(1).networkSetup.baseStationList(bb).copy();
            end

            for uu = 1:nUE
                combinedUserList(uu) = chunkResultList(1).networkSetup.userList(uu).copy();
            end

            % set properties that are different over the chunks and need to be saved
            for nn = 2:nChunks
                % copy network setup of this chunk
                networkSetup = chunkResultList(nn).networkSetup;

                for bb = 1:nBS
                    for aa = 1:length(networkSetup.baseStationList(bb).antennaList)
                        combinedBaseStationList(bb).antennaList(aa).positionList = [combinedBaseStationList(bb).antennaList(aa).positionList, ...
                            networkSetup.baseStationList(bb).antennaList(aa).positionList];
                    end
                end % for all base stations

                for uu = 1:nUE
                    combinedUserList(uu).positionList = [combinedUserList(uu).positionList, networkSetup.userList(uu).positionList];
                    combinedUserList(uu).isInROI = [combinedUserList(uu).isInROI, networkSetup.userList(uu).isInROI];
                end % for all users
            end % for all chunks

            networkElements.baseStationList = combinedBaseStationList;
            networkElements.userList = combinedUserList;
        end

        function additional = extractAdditionalResults(chunkResultList)
            % extracts the additional results and returns them in a struct
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   additional: [1x1]struct with additional results
            %       losMap:                 [nUser x nAntenna x nSegmentsTotal]logical table indicating links blocked by walls
            %       isIndoor:               [nUser x nSlotsTotal]logical indicator for indoor users
            %       antennaBsMapper:        [nAntenna x 2]integer antenna-BS-map
            %       macroscopicFadingdB:    [nAntennas x nUsers x nSegmentsTotal]double macroscopic fading for all possible links in dB
            %       wallLossdB:             [nAntennas x nUsers x nSegmentsTotal]double wall loss for all possible links in dB
            %       shadowFadingdB:         [nAntennas x nUsers x nSegmentsTotal]double sahdow fading for all possible links in dB
            %       antennaGaindB:          [nAntennas x nUsers x nSegmentsTotal]double antenna gain for all possible links in dB
            %       receivePowerdB:         [nAntennas x nUsers x nSegmentsTotal]double receive power for all possible links in dB
            %       pathlossTable:
            %           - DL:               [nAntenna x nUser x nSegmentsTotal]double downlink pathloss for all possible links in dB
            %       feedback:   [1x1]struct user feedback
            %           - DL:    [nUser x nSlotsTotal]cell downlink user feedback
            %       userScheduling: [1x1]struct
            %           - DL:    [nUser x nSlotsTotal]struct with downlink user scheduling
            %
            % see also parameters.Parameters.save

            % initialize output struct
            additional = struct();

            % extract LOS map
            if chunkResultList(1).params.save.losMap
                additional.losMap = simulation.postprocessing.PostprocessorSuperclass.extractLosMap(chunkResultList);
            end

            % extract isIndoor indicator
            if chunkResultList(1).params.save.isIndoor
                additional.isIndoor = simulation.postprocessing.PostprocessorSuperclass.extractIsIndoor(chunkResultList);
            end

            % extract antenna base station mapper
            if chunkResultList(1).params.save.antennaBsMapper
                additional.antennaBsMapper = simulation.postprocessing.PostprocessorSuperclass.extractAntennaBsMapper(chunkResultList);
            end

            % extract macroscopic fading table
            if chunkResultList(1).params.save.macroscopicFading
                additional.macroscopicFadingdB = simulation.postprocessing.PostprocessorSuperclass.extractMacroFading(chunkResultList);
            end

            % extract pathloss table
            if chunkResultList(1).params.save.pathlossTable
                additional.pathlossTable = simulation.postprocessing.PostprocessorSuperclass.extractPathlossTable(chunkResultList);
            end

            % extract wall loss table
            if chunkResultList(1).params.save.wallLoss
                additional.wallLossdB = simulation.postprocessing.PostprocessorSuperclass.extractWallLoss(chunkResultList);
            end

            % extract shadow fading table
            if chunkResultList(1).params.save.shadowFading
                additional.shadowFadingdB = simulation.postprocessing.PostprocessorSuperclass.extractShadowFading(chunkResultList);
            end

            % extract antenna gain table
            if chunkResultList(1).params.save.antennaGain
                additional.antennaGaindB = simulation.postprocessing.PostprocessorSuperclass.extractAntennaGain(chunkResultList);
            end

            % extract receive power table
            if chunkResultList(1).params.save.receivePower
                additional.receivePowerdB = simulation.postprocessing.PostprocessorSuperclass.extractreceivePower(chunkResultList);
            end

            % extract feedback
            if chunkResultList(1).params.save.feedback
                additional.feedback = simulation.postprocessing.PostprocessorSuperclass.extractFeedback(chunkResultList);
            end

            % extract scheduler signaling
            if chunkResultList(1).params.save.userScheduling
                additional.userScheduling = simulation.postprocessing.PostprocessorSuperclass.extractUserScheduling(chunkResultList);
            end
        end

        function losMap = extractLosMap(chunkResultList)
            % extracts the additional results and returns them in a struct
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %  [nAntennas x nUsers x nSegmentsTotal]logical table indicating links blocked by walls

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.losMap, 1);

            % initialize output
            losMap = false(nAntenna, nUser, nSegmentTotal);

            % save LOS/NLOS-map
            iSegment = 1;
            for iChunk = chunkResultList(1).params.time.numberOfChunks
                losMap(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = logical(sum(chunkResultList(iChunk).addition.losMap, 3));
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function isIndoor = extractIsIndoor(chunkResultList)
            % extracts isIndoor from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   isIndoor:   [nUser x nSlotsTotal]logical indicator for indoor users

            % get parameters
            timeParams	= chunkResultList(1).params.time;
            nUser       = chunkResultList(1).nUser;

            % initalize output
            isIndoor = false(nUser, timeParams.nSlotsTotal);

            % save isIndoor table
            iSlot = 1;
            for iChunk = 1:timeParams.numberOfChunks
                isIndoor(:, iSlot:(iSlot+timeParams.slotsPerChunk-1)) = chunkResultList(iChunk).addition.isIndoor - 1;
                iSlot = iSlot + timeParams.slotsPerChunk;
            end % for all chunks
        end

        function antennaBsMapper = extractAntennaBsMapper(chunkResultList)
            % extracts the antenna-base station-map from the first chunk
            % The antenna-BS mapping is constant over all chunks and can be
            % saved from the first chunk.
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   antennaBsMapper:    [nAntenna x 2]integer with antenna index in 1st column and base station index in 2nd column
            %
            % see also tools.AntennaBsMapper

            % save antenna-BS-map - the antenna-BS connection does not change over chunks
            antennaBsMapper = chunkResultList(1).addition.antennaBsMapper.antennaBsMap;
        end

        function macroFadingTable = extractMacroFading(chunkResultList)
            % extracts segment result tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   macroFadingTable:   [nAntenna x nUser x nSegmentTotal]double macroscopic fading for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.macroscopicFadingdB, 1);

            % initialize output
            macroFadingTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                macroFadingTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.macroscopicFadingdB;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function pathlossTable = extractPathlossTable(chunkResultList)
            % extracts pathloss tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   pathlossTable:  [nAntenna x nUser x nSegmentTotal]double pathloss for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.pathlossTableDL, 1);

            % initialize output
            pathlossTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                pathlossTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.pathlossTableDL;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function antennaGainTable = extractAntennaGain(chunkResultList)
            % extracts segment result tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   antennaGainTable:   [nAntenna x nUser x nSegmentTotal]double antenna gain for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.antennaGaindB, 1);

            % initialize output
            antennaGainTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                antennaGainTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.antennaGaindB;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function receivePowerTable = extractReceivePower(chunkResultList)
            % extracts segment result tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   receivePowerTable:   [nAntenna x nUser x nSegmentTotal]double receive power for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.antennaGaindB, 1);

            % initialize output
            receivePowerTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                receivePowerTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.receivePowerdB;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function wallLossTable = extractWallLoss(chunkResultList)
            % extracts segment result tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   wallLossTable:  [nAntenna x nUser x nSegmentTotal]double wall loss for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.wallLossdB, 1);

            % initialize output
            wallLossTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                wallLossTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.wallLossdB;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end

        function shadowFadingTable = extractShadowFading(chunkResultList)
            % extracts segment result tables from all chunk results
            %
            % input:
            %   chunkResultList:    [1 x nChunks]handleObject simulation.ChunkResult
            %
            % output:
            %   shadowFadingTable:  [nAntenna x nUser x nSegmentTotal]double shadow fading for all possible links in dB

            % get parameters
            nSegmentTotal	= sum([chunkResultList.nSegment]);
            nUser           = chunkResultList(1).nUser;
            nAntenna        = size(chunkResultList(1).addition.shadowFadingdB, 1);

            % initialize output
            shadowFadingTable = zeros(nAntenna, nUser, nSegmentTotal);

            % save pathloss tables
            iSegment = 1;
            for iChunk = 1:chunkResultList(1).params.time.numberOfChunks
                shadowFadingTable(:,:,iSegment:(iSegment+chunkResultList(iChunk).nSegment-1)) = chunkResultList(iChunk).addition.shadowFadingdB;
                iSegment = iSegment + chunkResultList(iChunk).nSegment;
            end % for all chunks
        end
    end

    methods (Static, Access =  protected)
        function networkSetup = collectFullNetworkSetup(simulationObject)
            % collect the network setup for results
            %
            % input:
            %   simulationObject:   [1x1]handleObject simulation.ChunkSimulation
            %
            % output:
            %   networkSetup:   [1x1]struct with network geometry information
            %       -buildingList:      [1 x nBuildings]handleObject blockages.Building
            %       -wallBlockageList:  [1 x nWalls]handleObject blockages.WallBlockage
            %       -userList:          [1 x nUser]handleObject networkElements.ue.User
            %       -baseStationList:   [1 x nBS]handleObject networkElements.bs.BaseStation
            %       -streetSystemList:	[1 x nStreets]handleObject blockages.StreetSystem
            %       -isNewSegment:      [1 x nSlots]logical indicator if slot is first in new segment
            %
            % see also simulation.ChunkConfig

            % get chunkConfig
            chunkConfig = simulationObject.chunkConfig;

            % initialize output struct
            networkSetup = struct;

            % save network elements and blockages
            networkSetup.buildingList       = chunkConfig.buildingList;
            networkSetup.wallBlockageList	= chunkConfig.wallBlockageList;
            networkSetup.userList           = chunkConfig.userList;
            networkSetup.baseStationList	= chunkConfig.baseStationList;
            networkSetup.streetSystemList	= chunkConfig.streetSystemList;
            networkSetup.isNewSegment       = chunkConfig.isNewSegment;
        end
    end
end

