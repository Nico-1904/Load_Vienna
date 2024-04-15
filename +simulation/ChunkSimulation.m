classdef ChunkSimulation < tools.HiddenHandle
    %ChunkSimulation runs the simulation for one specific time chunk
    % The main part of the simulation handled by this class.
    %
    % initial author: Lukas Nagel
    %
    % ROI: Region Of Interest

    properties
        % container for chunk specific configuration
        % [1x1]handleObject simulation.ChunkConfig
        chunkConfig

        % SINR averager
        % [1x1]struct with SINR averager
        %   -DL:    [1x1]handleObject tools.MiesmAverager
        sinrAverager

        % wall loss in dB
        % [nAntennas x nUsers x nSegment]double wall loss for each UE-antenna link and segment in dB
        wallLossdB

        % antenna gain for all links in dB
        % [nAntennas x nUsers x nSegment]double antenna gain in dB
        antennaGaindB

        % shadow fading in dB
        % [nAntennas x nUsers x nSegment]double shadow fading for each UE-antenna link and slot in dB
        shadowFadingdB

        % postprocessor
        % [1x1]handleObject simulation.postprocessing.PostprocessorSuperclass
        % The postprocessor extracts the results of a chunk and combines
        % the results of all chunks to one simulation result.
        postprocessor

        % trace of results produced in one slot
        % [nSlots x 1]cell temporary results struct for ach slot
        %
        % see also simulation.results.TemporaryResult,
        % simulation.results.TemporaryResult.toStruct
        trace

        % path loss between each user and each antenna in dB
        % [nAntennas x nUsers x nSegment]double pathloss for all possible links in dB.
        % The path loss is used to calculate a preliminary SINR for cell
        % association and a post equalization SINR in the LQM.
        pathLossTableDL

        % macroscopic receive power in dB
        % [nAntennas x nUsers x nSegment]double macroscopic power received in dB
        % The macroscopic receive power considers all macroscopic fading
        % effects, which are transmit power, antenna gain, and macroscopic
        % fading.
        %
        % see also macroscopicFadingdB,
        % cellManagement.CellAssociation.setCellAssociationTable
        receivePowerdB

        % wideband SINR in dB
        % [nUsers x nSegment]double wideband SINR in dB
        % The wideband SINR considers all macroscopic fading parameters,
        % but no small scale fading, no precoding, no scheduling.
        %
        % see also cellManagement.CellAssociation.setCellAssociationTable
        widebandSinrdB
        
        %by Nico kabongo
        
        LoadCell
        
        debit
        
        debitOff
        
        trace1
        %----------------

        % lite downlink SINR in dB
        % [nUsers x nSlots]double lite downlink SINR for each user in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        liteSinrDLdB

        % lite uplink SINR in dB
        % [nUsers x nSlots]double lite uplink SINR for each user in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        % A random user in each cell is chosen as interfering user.
        liteSinrULdB

        % lite downlink SNR in dB
        % [nUsers x nSlots]double lite downlink SNR for each user in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        liteSnrDLdB

        % lite uplink SNR in dB
        % [nUsers x nSlots]double lite uplink SNR for each user in dB
        %
        % This SINR is calculated from large scale fading parameters
        % (antenna gain, transmit power, pathloss, wall loss, shadow
        % fading) and one randomly chosen scmall scale fading channel
        % realization.
        % A random user in each cell is chosen as interfering user.
        liteSnrULdB

        % Link Performance Model
        % [1x1]handleObject linkPerformanceModel.LinkPerformanceModel
        LPM

        % base stations in the simulation
        % [1 x n]handleObject networkElements.bs.BaseStation
        baseStations

        % users in the simulation
        % [1 x nUsers]handleObject networkElments.ue.User
        users

        % Inter-numerolgoy factor cache
        % [1x1]handleObject linkQualityModel.IniCache Caches precalculated
        % inter-numerology interference factors for the LQM
        iniCache

        % managess user to base station assignment
        % [1x1]handleObject cellManagement.CellAssociation
        cellManager

        % macroscopic fading gain for each link in dB
        % Combines path loss, antenna gain, wall loss and shadow fading,
        % then applies minimum coupling loss.
        % This value is in general negative, since the path loss exceeds
        % the antenna gain.
        % [nAntennas x nUsers x nSegment]double macroscopic fading in dB
        % see also parameters.PathlossModelContainer.minimumCouplingLossdB,
        % simulation.ChunkSimulation.antennaGaindB,
        % simulation.ChunkSimulation.pathLossTableDL,
        % simulation.ChunkSimulation.wallLossdB,
        % simulation.ChunkSimulation.shadowFadingdB
        macroscopicFadingdB

        % combines values of pathlsss minimum, coupling loss, antenna gain,
        % and shadow fading
        % [1x1]handleObject macroscopicPathlossModel.PathLossManagement
        pathLossManager

        % total number of users in the chunk
        % [1x1]integer total number of users
        nUsers

        % indicator for users in ROI (Region Of Interest) for each slot
        % [1 x nUsers]logical indicates if user is in ROI for each slot
        isUserRoi
    end

    properties (Access = private)
        % antennas used in this simulation
        % [1 x nAntennas]handleObject networkElements.bs.Antenna
        antennaList

        % total number of antennas
        % [1x1]integer total number of antennas
        % This the number of antennas that exist in this simulation, i.e.
        % the sum of all antennas used by all base stations.
        nAntennas

        % number of slots in a chunk
        %[1x1]integer number of slots in a chunk
        nSlots

        % total number of base stations in the simulation
        % [1x1]integer total number of base stations
        nBaseStations
    end

    properties (Dependent)
        % total number of segments
        % [1x1]integer total number of segments in this simulation
        nSegment
    end

    methods
        function obj = ChunkSimulation(chunkConfig)
            % Chunksimulation copies chunk config and initializes properties
            %
            % input:
            %   chunkConfig:    [1x1]handleObject simulation.ChunkConfig

            % copy chunk config to object
            obj.chunkConfig     = chunkConfig;

            % set private properties
            obj.baseStations	= obj.chunkConfig.baseStationList;
            obj.antennaList     = [obj.baseStations.antennaList];
            obj.users           = obj.chunkConfig.userList;
            obj.nAntennas       = length(obj.antennaList);
            obj.nBaseStations   = length(obj.baseStations);
            obj.nSlots          = obj.chunkConfig.params.time.slotsPerChunk;
            obj.nUsers          = length(obj.users);
            obj.postprocessor   = obj.chunkConfig.params.postprocessor;
            obj.iniCache        = obj.chunkConfig.iniFactors;

            % initialize averager
            obj.sinrAverager.DL = tools.MiesmAverager(...
                obj.chunkConfig.params.transmissionParameters.DL.cqiParameters,...
                'dataFiles/BICM_capacity_tables_20000_realizations.mat', obj.chunkConfig.params.fastAveraging);

            % initialize properties
            obj.chunkConfig.isNewSegment	= false(1, obj.nSlots);
            obj.trace                     	= cell(obj.nSlots,1);
            obj.trace1                     	= cell(obj.nSlots,1);
        end

        function chunkResult = runSimulation(obj)
            % runSimulation runs the main simulation loop of the chunk
            %
            % output:
            %   chunkResult:    [1x1]handleObject simulation.ChunkResult

            % sets geometry parameters and initializes SINR averager, precoder and LPM
            obj.setupPerChunk;

            % calculate macroscopic fading
            obj.calculateMacroscopicFading;

            % calculate user Noise (for whole bandwidth)
            userNoisePowersW = networkElements.NetworkElementWithPosition.getNoisePowerW(obj.users, ...
                obj.chunkConfig.params.transmissionParameters.DL.resourceGrid);

            % Initialize the small scale fading container
            smallScaleContainer = smallScaleFading.Container(obj.chunkConfig, obj.antennaList, obj.users);

            % initialize scheduler
            s = obj.initializeScheduler;

            % initialize Link Quality Model
            LQMDL = obj.initializeLQM;

            % cell association - user to cell assignment
            [obj.receivePowerdB, obj.widebandSinrdB, SinrLoad] = obj.cellManager.setCellAssociationTable(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW);
            
            %[obj.receivePowerdB, obj.widebandSinrdB] = obj.cellManager.setCellAssociationTable(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW+1);
            
            
            %by Nico Kabongo---- Load cell
            obj.LoadCell = obj.cellManager.getLoadCell(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW);
            aaa=obj.receivePowerdB;   
            obj.widebandSinrdB;
            iBaseStations = 1:obj.nBaseStations;
            for iBS = iBaseStations
                switch obj.baseStations(iBS).antennaList.baseStationType
                    case parameters.setting.BaseStationType.macro
                attachedUsers = obj.baseStations(iBS);
                ff=obj.baseStations;
                ff.attachedUsers;
                    case parameters.setting.BaseStationType.femto
                       for iUserAtt = 1:obj.nUsers
                attachedUsers = obj.users.id;
                obj.nUsers;
                       end
                end
            end
            kFem = 0;
            kMac =0;
            kFemBis = 0;
            kMacBis =0;
            kFemBis1 = 0;
            kMacBis1 =0;
            kFemBis2 = 0;
            kMacBis2 =0;
            kFemBis3 = 0;
            kMacBis3 =0;
            kFemBis4 = 0;
            kMacBis4 =0;
            kFemOff = 0;
            kMacOff =0;
%             iBaseStations = 1:obj.nBaseStations;
%             for iBS = iBaseStations
%                 attachedUsers = obj.baseStations(iBS).attachedUsers
%             end
            %-----------------------------------------------------

            %% main simulation loop
            for iSlot = 1:obj.nSlots
                % update ROI indicator for this slot
                obj.setIsUsersRoi(iSlot);
                indexUserRoi = find(obj.isUserRoi);

                if obj.chunkConfig.isNewSegment(iSlot)
                    % cell association changes and handovers are performed

                    % update cell association if this is new segment
                    obj.cellManager.updateUsersAttachedToBaseStations(obj.getiSegment(iSlot));
                    %obj.cellManager.updateUsersAttachedToBaseStationsInterfer(obj.getiSegment(iSlot), tools.dBto(obj.macroscopicFadingdB));

                    % find cells that belong in the interference region
                    obj.filterPureInterferenceCells(iSlot);

                    % perform handovers - clear feedback buffers and update
                    % precoders of users in new cell
                    obj.performHandover(iSlot);
                end % if this slot is the first one in a segment

                if ~obj.chunkConfig.params.liteSimulation
                    % calculate analog precoder for this slot
                    obj.calculateAnalogPrecoder;

                    % check if new packet generation is necessary
                    obj.getNewTraffic(iSlot);

                    % perform scheduling
                    obj.scheduling(s, iSlot);

                    % create temporary result to save results from this slot
                    temporaryResult = simulation.results.TemporaryResult(obj);
                end % if this is a full simulation

                for iUE = indexUserRoi
                    % map iSlot to iSegment
                    iSeg = obj.getiSegment(iSlot);

                    % set desired antennas according to cell association
                    desired = obj.setDesiredAntenna(iUE, iSeg);

                    % get new macroscopic parameters
                    macroscopicW = tools.dBto(obj.macroscopicFadingdB(:,iUE,iSeg).');

                    if obj.chunkConfig.isNewSegment(iSlot)
                        % update macroscopic parameters
                        LQMDL(iUE).updateMacroscopic(desired, macroscopicW);
                    end % if this is a new segment

                    % get current user
                    userRoi = obj.users(iUE);

                    % calculate lite SINR
                    obj.setLiteSINR(userRoi, iUE, iSlot, userNoisePowersW(iUE), macroscopicW, ...
                        desired, LQMDL(iUE).interferer, smallScaleContainer);

                    if ~obj.chunkConfig.params.liteSimulation % skip in lite simulation mode

                        % update small scale parameters
                        H_array = smallScaleContainer.getChannelDL(userRoi, obj.antennaList, iSlot);
                        LQMDL(iUE).updateSmallScale(H_array);

                        % calculate SINR
                        postEqSinrdB = LQMDL(iUE).getPostEqSinr;

                        % save additional results
                        if obj.chunkConfig.params.useFeedback
                            % calculate feedback
                            userRoi.userFeedback.DL.calculateFeedbackSafe(iSlot, LQMDL(iUE), postEqSinrdB, false);
                        end

                        % call link performance model
                        [temporaryResult.throughputUser.DL(iUE), temporaryResult.throughputUser.DLBestCQI(iUE), ...
                            temporaryResult.effectiveSinr.DL(iUE), temporaryResult.BLER.DL(iUE)] = obj.LPM.DL.calculateThroughput(...
                            userRoi.scheduling.CQI(1:userRoi.scheduling.nCodeword),...
                            postEqSinrdB(:,userRoi.scheduling.assignedRBs),...
                            userRoi.scheduling.nCodeword,...
                            iSlot,...
                            userRoi.scheduling.assignedRBs,...
                            sum([obj.baseStations(obj.cellManager.userToBSassignment(iUE, obj.getiSegment(iSlot))).antennaList.nTX]),...
                            userRoi.scheduling.nLayer, ...
                            userRoi.scheduling.nomaPowerShare, ...
                            userRoi.scheduling.HARQ.codewordRV);

                        if obj.chunkConfig.params.useFeedback
                            % get acknowlegment about transmission success
                            userRoi.userFeedback.DL.getAck(obj.LPM.DL)
                        end

                        % check if there is data in packets buffer
                        % and update buffer according to user throughput
                        if obj.chunkConfig.params.useFeedback
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DL(iUE), iSlot);
                        else
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DLBestCQI(iUE), iSlot);
                        end
                    end % if this is a full simulation
                end % for all users in the region of interest

                if ~obj.chunkConfig.params.liteSimulation   % Skip in lite simulation mode
                    % set random feedback for users in interference region
                    lqmDummy.resourceGrid = obj.chunkConfig.params.transmissionParameters.DL.resourceGrid;
                    sinrDummy = zeros(1, lqmDummy.resourceGrid.nRBFreq, lqmDummy.resourceGrid.nRBTime);
                    for userInterference = obj.users(~obj.isUserRoi)
                        lqmDummy.receiver.nRX = userInterference.nRX;
                        lqmDummy.antenna.nTX = 1;
                        %NOTE: here the users in the interference region
                        %get a random feedback. Users in the interference
                        %region are not fully simulated, they only generate
                        %interference to reduce border effects at the user
                        %in the ROI (Region Of Interest).
                        userInterference.userFeedback.DL.calculateFeedbackSafe(iSlot, lqmDummy, sinrDummy, true);

                        % get a random acknowledgment about transmission success
                        userInterference.userFeedback.DL.getAck(obj.LPM.DL)
                    end

                    % set result trace element for this slot
                    temporaryResult = temporaryResult.setTemporarySlotResult(obj);
                    obj.trace{iSlot} = temporaryResult.toStruct;
                end % if this is not a lite simulation
            end % for all slots

            % set chunk result for all slots
            chunkResult = simulation.ChunkResult.getChunkResult(obj);

            % clear packets buffer for all users
            % it is necessary at the end of each chunk since considerably
            % long distance and time is assumed between chunks. Therefore,
            % it does not make sense to carry on transmiting users'
            % packets over multiple chunks. Basically, different chunks
            % can be considered as independent simulations from the traffic
            % model point of view. Untransmitted packets are not shown in the
            % packets buffer in the saved results, however they can be seen as
            % a tail probability in the transmission latency plot
            for iUser = obj.users
                iUser.trafficModel.clearBuffer;
            end

            % reset redundancy versions of codewords since no
            % retransmissions are carried on over multiple chunks
            for iUser = obj.users
                iUser.scheduling.HARQ.resetRVs;
            end
            
            lite1 = obj.liteSinrULdB;
            lite2 = obj.liteSinrDLdB;
            lite3 = obj.liteSnrULdB;
            lite4 = obj.liteSnrDLdB;
            temporaryResult.throughputUser.DL;
            obj.debit = temporaryResult.throughputUser.DLBestCQI;
            z3=temporaryResult.effectiveSinr.DL;
            %By Nico Kabongo
            iBaseStations = 1:obj.nBaseStations;
            idUser = 1:obj.nUsers;
            ik={};
            ipp=[];
            for iBS = iBaseStations
                        %load_BS = 1500 ./ (100 * 180 * log2(1 + tools.dBto(obj.widebandSinrdB)));
                        %snr = tools.dBto(obj.receivePowerdB) ./ userNoisePowersW; 
                        load_BS = 1500 ./ (100 * 180 * log2(1 + 1.5 *(SinrLoad)));
                vect =[obj.baseStations(iBS).attachedUsers.id]
                nobrUser1(iBS) = numel(vect);
                fg = load_BS(vect);
                sulm= sum(fg);
                ipp(iBS)=sulm;
                ik{iBS}=vect;
                
                switch obj.baseStations(iBS).antennaList.baseStationType
                 case parameters.setting.BaseStationType.femto
                     BsFemto = obj.baseStations(iBS).antennaList.id;
                        kFem(iBS)=obj.baseStations(iBS).antennaList.id;
                 case parameters.setting.BaseStationType.macro
                     BsMacro = obj.baseStations(iBS).antennaList.id;
                        kMac(iBS)=obj.baseStations(iBS).antennaList.id;
                end
            end
            ik;
            
            to =(10^3) * (tools.dBto(obj.receivePowerdB));
            tr=(10^3) * (userNoisePowersW);
            solverLoad = obj.cellManager.solveEquations(to, tr,ik)
            ipp;
            idBase = iBaseStations;
            highLoad= solverLoad(solverLoad > 0.4); %0.5396
            lowLoad= solverLoad(solverLoad < 0.17); %0.1798
            indHigh = find(solverLoad > 0.4);
            kMac=nonzeros(kMac).'
            indHighMacro = intersect(kMac, indHigh);
            indLow = find(solverLoad < 0.17);
            kFem = nonzeros(kFem);
            kFem=nonzeros(kFem).'
            indLowFemto = intersect(kFem, indLow);
            
            
                        sum_rho_abs = abs(sum(solverLoad))^2;
            sum_rho_squared = length(solverLoad) * sum(solverLoad.^2);
            IndiceEquite = sum_rho_abs / sum_rho_squared;
            
            figure()
                bar(idBase,solverLoad );
                xlim([0, length(idBase)+1]);
                xticks(0:2:length(idBase)+1);
                ylim([0, 2.5]);
                xlabel('Station de base');
                ylabel('Charge sans decalage');
                title('Graphique de la charge sans decalage par BS');
                
                figure()
                bar(idBase,nobrUser1);
                xlim([0, length(idBase)+1]);
                xticks(0:2:length(idBase)+1);
                xlabel('Station de base');
                ylabel('Nombre Utilisateur');
                title('Graphique Nombre Utilisateur par BS sans decalage');
                
            
            %Algorithme load_balancing
                     IndiceEquite_Opt = 0;
                     networkOffset = 0.00001;
%                 
%             
             [receivePowerBis4dB, widebandSinrBis4dB, load_BSBis4] = obj.cellManager.getUpdateAssociationWithLoad(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW, indHigh, indLow, networkOffset);
            %receivePowerOffdB;
            %widebandSinrOffdB;
            
            %-----mise à jour attachement
                        for iSlot = 1:obj.nSlots
                % update ROI indicator for this slot
                obj.setIsUsersRoi(iSlot);
                indexUserRoi = find(obj.isUserRoi);

                if obj.chunkConfig.isNewSegment(iSlot)
                    % cell association changes and handovers are performed

                    % update cell association if this is new segment
                    obj.cellManager.updateUsersAttachedToBaseStations(obj.getiSegment(iSlot));
                    %obj.cellManager.updateUsersAttachedToBaseStationsInterfer(obj.getiSegment(iSlot), tools.dBto(obj.macroscopicFadingdB));

                    % find cells that belong in the interference region
                    obj.filterPureInterferenceCells(iSlot);

                    % perform handovers - clear feedback buffers and update
                    % precoders of users in new cell
                    obj.performHandover(iSlot);
                end % if this slot is the first one in a segment

                %fichier simul temp
                if ~obj.chunkConfig.params.liteSimulation
                    % calculate analog precoder for this slot
                    obj.calculateAnalogPrecoder;

                    % check if new packet generation is necessary
                    obj.getNewTraffic(iSlot);

                    % perform scheduling
                    obj.scheduling(s, iSlot);

                    % create temporary result to save results from this slot
                    temporaryResult = simulation.results.TemporaryResult(obj);
                end % if this is a full simulation

                for iUE = indexUserRoi
                    % map iSlot to iSegment
                    iSeg = obj.getiSegment(iSlot);

                    % set desired antennas according to cell association
                    desired = obj.setDesiredAntenna(iUE, iSeg);

                    % get new macroscopic parameters
                    macroscopicW = tools.dBto(obj.macroscopicFadingdB(:,iUE,iSeg).');

                    if obj.chunkConfig.isNewSegment(iSlot)
                        % update macroscopic parameters
                        LQMDL(iUE).updateMacroscopic(desired, macroscopicW);
                    end % if this is a new segment

                    % get current user
                    userRoi = obj.users(iUE);

                    % calculate lite SINR
                    obj.setLiteSINR(userRoi, iUE, iSlot, userNoisePowersW(iUE), macroscopicW, ...
                        desired, LQMDL(iUE).interferer, smallScaleContainer);

                    if ~obj.chunkConfig.params.liteSimulation % skip in lite simulation mode

                        % update small scale parameters
                        H_array = smallScaleContainer.getChannelDL(userRoi, obj.antennaList, iSlot);
                        LQMDL(iUE).updateSmallScale(H_array);

                        % calculate SINR
                        postEqSinrdB = LQMDL(iUE).getPostEqSinr;

                        % save additional results
                        if obj.chunkConfig.params.useFeedback
                            % calculate feedback
                            userRoi.userFeedback.DL.calculateFeedbackSafe(iSlot, LQMDL(iUE), postEqSinrdB, false);
                        end

                        % call link performance model
                        [temporaryResult.throughputUser.DL(iUE), temporaryResult.throughputUser.DLBestCQI(iUE), ...
                            temporaryResult.effectiveSinr.DL(iUE), temporaryResult.BLER.DL(iUE)] = obj.LPM.DL.calculateThroughput(...
                            userRoi.scheduling.CQI(1:userRoi.scheduling.nCodeword),...
                            postEqSinrdB(:,userRoi.scheduling.assignedRBs),...
                            userRoi.scheduling.nCodeword,...
                            iSlot,...
                            userRoi.scheduling.assignedRBs,...
                            sum([obj.baseStations(obj.cellManager.userToBSassignment(iUE, obj.getiSegment(iSlot))).antennaList.nTX]),...
                            userRoi.scheduling.nLayer, ...
                            userRoi.scheduling.nomaPowerShare, ...
                            userRoi.scheduling.HARQ.codewordRV);

                        if obj.chunkConfig.params.useFeedback
                            % get acknowlegment about transmission success
                            userRoi.userFeedback.DL.getAck(obj.LPM.DL)
                        end

                        % check if there is data in packets buffer
                        % and update buffer according to user throughput
                        if obj.chunkConfig.params.useFeedback
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DL(iUE), iSlot);
                        else
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DLBestCQI(iUE), iSlot);
                        end
                    end % if this is a full simulation
                end % for all users in the region of interest

                if ~obj.chunkConfig.params.liteSimulation   % Skip in lite simulation mode
                    % set random feedback for users in interference region
                    lqmDummy.resourceGrid = obj.chunkConfig.params.transmissionParameters.DL.resourceGrid;
                    sinrDummy = zeros(1, lqmDummy.resourceGrid.nRBFreq, lqmDummy.resourceGrid.nRBTime);
                    for userInterference = obj.users(~obj.isUserRoi)
                        lqmDummy.receiver.nRX = userInterference.nRX;
                        lqmDummy.antenna.nTX = 1;
                        %NOTE: here the users in the interference region
                        %get a random feedback. Users in the interference
                        %region are not fully simulated, they only generate
                        %interference to reduce border effects at the user
                        %in the ROI (Region Of Interest).
                        userInterference.userFeedback.DL.calculateFeedbackSafe(iSlot, lqmDummy, sinrDummy, true);

                        % get a random acknowledgment about transmission success
                        userInterference.userFeedback.DL.getAck(obj.LPM.DL)
                    end

                    % set result trace element for this slot
                    temporaryResult = temporaryResult.setTemporarySlotResult(obj);
                    obj.trace1{iSlot} = temporaryResult.toStruct;
                end % if this is not a lite simulation
%fichier simul temp
                        end
                        
                        chunkResult = simulation.ChunkResult.getChunkResult(obj);

            for iUser = obj.users
                iUser.trafficModel.clearBuffer;
            end

            for iUser = obj.users
                iUser.scheduling.HARQ.resetRVs;
            end
%             %--------------------
            for iBS = iBaseStations
                vectBis4 =[obj.baseStations(iBS).attachedUsers.id];
                nobrUserBis4(iBS) = numel(vectBis4);
                %intU(iBS)= nobrUser
                fgBis4 = load_BSBis4(vectBis4);
                sulmBis4= sum(fgBis4);
                ippBis4(iBS)=sulmBis4;
                ikBis4{iBS}=vectBis4;
	           switch obj.baseStations(iBS).antennaList.baseStationType
                 case parameters.setting.BaseStationType.femto
                        kFemBis4(iBS)=obj.baseStations(iBS).antennaList.id;
                 case parameters.setting.BaseStationType.macro
                        kMacBis4(iBS)=obj.baseStations(iBS).antennaList.id;
                end
                        end
                        
                        %-------------off load
                        
            to =(10^3) * (tools.dBto(receivePowerBis4dB));
            tr=(10^3) * (userNoisePowersW);
            solverLoadBis4 = obj.cellManager.solveEquations(to, tr,ikBis4);
            idBaseBis4 = iBaseStations;
            highLoadBis4= solverLoadBis4(solverLoadBis4 > 0.8);
            lowLoadBis4 = solverLoadBis4(solverLoadBis4 < 0.2);
            indHighBis4 = find(solverLoadBis4 > 0.8);
            kMacBis4=nonzeros(kMacBis4).';
            indHighMacroBis4 = intersect(kMacBis4, indHighBis4);
            indLowBis4 = find(solverLoadBis4 < 0.2)
            kFemBis4 = nonzeros(kFemBis4);
            kFemBis4=nonzeros(kFemBis4).';
            indLowFemtoBis4 = intersect(kFemBis4, indLowBis4);
                        %--------------
                        
                        sum_rho_abs = abs(sum(solverLoadBis4))^2;
            sum_rho_squared = length(solverLoadBis4) * sum(solverLoadBis4.^2);
            IndiceEquiteBis4 = sum_rho_abs / sum_rho_squared;
            
            
            
                        figure()
                bar(idBaseBis4,solverLoadBis4 );
                xlim([0, length(idBaseBis4)+1]);
                xticks(0:2:length(idBaseBis4)+1);
                ylim([0, 2.5]);
                xlabel('Station de base');
                ylabel('Charge sans decalage');
                title('Graphique de la charge Bis4');
                
                figure()
                bar(idBaseBis4,nobrUserBis4);
                xlim([0, length(idBaseBis4)+1]);
                xticks(0:2:length(idBaseBis4)+1);
                xlabel('Station de base');
                ylabel('Nombre Utilisateur');
                title('Graphique Nombre Utilisateur par BS Bis4');
                
                
                %--------------------------Fin Bis4
            %------------------
            
            
                        networkOffset=0.0000246;
                               % [receivePowerBis4dB, widebandSinrBis4dB, load_BSBis4] = obj.cellManager.getUpdateAssociationWithLoad6(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW, indHighOff, indLowFemtoOff, networkOffset);
                               
            [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = obj.cellManager.getUpdateAssociationWithLoad2(tools.dBto(obj.macroscopicFadingdB), userNoisePowersW, indHighBis4, indLowFemtoBis4, networkOffset);
                

                 %-----mise à jour attachement
                        for iSlot = 1:obj.nSlots
                % update ROI indicator for this slot
                obj.setIsUsersRoi(iSlot);
                indexUserRoi = find(obj.isUserRoi);

                if obj.chunkConfig.isNewSegment(iSlot)
                    % cell association changes and handovers are performed

                    % update cell association if this is new segment
                    obj.cellManager.updateUsersAttachedToBaseStations(obj.getiSegment(iSlot));
                    %obj.cellManager.updateUsersAttachedToBaseStationsInterfer(obj.getiSegment(iSlot), tools.dBto(obj.macroscopicFadingdB));

                    % find cells that belong in the interference region
                    obj.filterPureInterferenceCells(iSlot);

                    % perform handovers - clear feedback buffers and update
                    % precoders of users in new cell
                    obj.performHandover(iSlot);
                end % if this slot is the first one in a segment

                %fichier simul temp
                if ~obj.chunkConfig.params.liteSimulation
                    % calculate analog precoder for this slot
                    obj.calculateAnalogPrecoder;

                    % check if new packet generation is necessary
                    obj.getNewTraffic(iSlot);

                    % perform scheduling
                    obj.scheduling(s, iSlot);

                    % create temporary result to save results from this slot
                    temporaryResult = simulation.results.TemporaryResult(obj);
                end % if this is a full simulation

                for iUE = indexUserRoi
                    % map iSlot to iSegment
                    iSeg = obj.getiSegment(iSlot);

                    % set desired antennas according to cell association
                    desired = obj.setDesiredAntenna(iUE, iSeg);

                    % get new macroscopic parameters
                    macroscopicW = tools.dBto(obj.macroscopicFadingdB(:,iUE,iSeg).');

                    if obj.chunkConfig.isNewSegment(iSlot)
                        % update macroscopic parameters
                        LQMDL(iUE).updateMacroscopic(desired, macroscopicW);
                    end % if this is a new segment

                    % get current user
                    userRoi = obj.users(iUE);

                    % calculate lite SINR
                    obj.setLiteSINR(userRoi, iUE, iSlot, userNoisePowersW(iUE), macroscopicW, ...
                        desired, LQMDL(iUE).interferer, smallScaleContainer);

                    if ~obj.chunkConfig.params.liteSimulation % skip in lite simulation mode

                        % update small scale parameters
                        H_array = smallScaleContainer.getChannelDL(userRoi, obj.antennaList, iSlot);
                        LQMDL(iUE).updateSmallScale(H_array);

                        % calculate SINR
                        postEqSinrdB = LQMDL(iUE).getPostEqSinr;

                        % save additional results
                        if obj.chunkConfig.params.useFeedback
                            % calculate feedback
                            userRoi.userFeedback.DL.calculateFeedbackSafe(iSlot, LQMDL(iUE), postEqSinrdB, false);
                        end

                        % call link performance model
                        [temporaryResult.throughputUser.DL(iUE), temporaryResult.throughputUser.DLBestCQI(iUE), ...
                            temporaryResult.effectiveSinr.DL(iUE), temporaryResult.BLER.DL(iUE)] = obj.LPM.DL.calculateThroughput(...
                            userRoi.scheduling.CQI(1:userRoi.scheduling.nCodeword),...
                            postEqSinrdB(:,userRoi.scheduling.assignedRBs),...
                            userRoi.scheduling.nCodeword,...
                            iSlot,...
                            userRoi.scheduling.assignedRBs,...
                            sum([obj.baseStations(obj.cellManager.userToBSassignment(iUE, obj.getiSegment(iSlot))).antennaList.nTX]),...
                            userRoi.scheduling.nLayer, ...
                            userRoi.scheduling.nomaPowerShare, ...
                            userRoi.scheduling.HARQ.codewordRV);

                        if obj.chunkConfig.params.useFeedback
                            % get acknowlegment about transmission success
                            userRoi.userFeedback.DL.getAck(obj.LPM.DL)
                        end

                        % check if there is data in packets buffer
                        % and update buffer according to user throughput
                        if obj.chunkConfig.params.useFeedback
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DL(iUE), iSlot);
                        else
                            userRoi.trafficModel.updateAfterTransmit(temporaryResult.throughputUser.DLBestCQI(iUE), iSlot);
                        end
                    end % if this is a full simulation
                end % for all users in the region of interest

                if ~obj.chunkConfig.params.liteSimulation   % Skip in lite simulation mode
                    % set random feedback for users in interference region
                    lqmDummy.resourceGrid = obj.chunkConfig.params.transmissionParameters.DL.resourceGrid;
                    sinrDummy = zeros(1, lqmDummy.resourceGrid.nRBFreq, lqmDummy.resourceGrid.nRBTime);
                    for userInterference = obj.users(~obj.isUserRoi)
                        lqmDummy.receiver.nRX = userInterference.nRX;
                        lqmDummy.antenna.nTX = 1;
                        %NOTE: here the users in the interference region
                        %get a random feedback. Users in the interference
                        %region are not fully simulated, they only generate
                        %interference to reduce border effects at the user
                        %in the ROI (Region Of Interest).
                        userInterference.userFeedback.DL.calculateFeedbackSafe(iSlot, lqmDummy, sinrDummy, true);

                        % get a random acknowledgment about transmission success
                        userInterference.userFeedback.DL.getAck(obj.LPM.DL)
                    end

                    % set result trace element for this slot
                    temporaryResult = temporaryResult.setTemporarySlotResult(obj);
                    obj.trace1{iSlot} = temporaryResult.toStruct;
                end % if this is not a lite simulation
%fichier simul temp
                        end
                        
                        chunkResult = simulation.ChunkResult.getChunkResult(obj);

            for iUser = obj.users
                iUser.trafficModel.clearBuffer;
            end

            for iUser = obj.users
                iUser.scheduling.HARQ.resetRVs;
            end
            %--------------------
                
            lite11=obj.liteSinrULdB;
            lite12=obj.liteSinrDLdB;
            lite13=obj.liteSnrULdB;
            lite14=obj.liteSnrDLdB;

%             %---------------
            

        for iBS = iBaseStations
                vectOff =[obj.baseStations(iBS).attachedUsers.id];
                nobrUserOff(iBS) = numel(vectOff);
                %intU(iBS)= nobrUser
                fgOff = load_BSoff(vectOff);
                sulmOff= sum(fgOff);
                ippOff(iBS)=sulmOff;
                ikOff{iBS}=vectOff;
	           switch obj.baseStations(iBS).antennaList.baseStationType
                 case parameters.setting.BaseStationType.femto
                        kFemOff(iBS)=obj.baseStations(iBS).antennaList.id;
                 case parameters.setting.BaseStationType.macro
                        kMacOff(iBS)=obj.baseStations(iBS).antennaList.id;
                end
                        end
                        
                        %-------------off load
                        
            to =(10^3) * (tools.dBto(receivePowerOffdB));
            tr=(10^3) * (userNoisePowersW);
            solverLoadOff = obj.cellManager.solveEquations(to, tr,ikOff);
                                    idBaseOff = iBaseStations;
            highLoadOff= solverLoadOff(solverLoadOff > 0.8);
            lowLoadOff = solverLoadOff(solverLoadOff < 0.2);
            indHighOff = find(solverLoadOff > 0.8);
            kMacOff=nonzeros(kMacOff).';
            indHighMacroOff = intersect(kMacOff, indHighOff);
            indLowOff = find(solverLoadOff < 0.2)
            kFemOff = nonzeros(kFemOff);
            kFemOff=nonzeros(kFemOff).';
            indLowFemtoOff = intersect(kFemOff, indLowOff);
                        %--------------
                        
                        sum_rho_abs = abs(sum(solverLoadOff))^2;
            sum_rho_squared = length(solverLoadOff) * sum(solverLoadOff.^2);
            IndiceEquiteOff = sum_rho_abs / sum_rho_squared;
            
            %---------------------------------------------
            temporaryResult.throughputUser.DL;
            obj.debitOff = temporaryResult.throughputUser.DLBestCQI;
            y3=temporaryResult.effectiveSinr.DL;
            gainDebit = obj.debitOff - obj.debit;
            MaxGainDebit = max(gainDebit);
            gainSINR = widebandSinrOffdB - obj.widebandSinrdB;
            MaxGainSINR = max(gainSINR);
            IndiceEquite
            IndiceEquiteBis4
            IndiceEquite_Opt = IndiceEquiteOff
            bbb=receivePowerOffdB;
            %-Fin attachement interference
            
            
            yy3=temporaryResult.effectiveSinr.DL;
      %just verification      
            haveSameElements = isequal(aaa, bbb);

if haveSameElements
    disp('Les matrices ont les mêmes éléments.');
else
    disp('Les matrices ont des éléments différents.');

    % Identifier les éléments qui diffèrent
    difference = aaa - bbb;
end
%---
                figure()
                bar(idBase,solverLoadOff);
                xlim([0, length(idBase)+1]);
                xticks(0:2:length(idBase)+1);
                ylim([0, 2.5]);
                xlabel('Station de base');
                ylabel('Charge avec decalage');
                title('Graphique de la charge avec decalage par BS');
                %figure()
                %plot(idUser, load_BS);
                figure()
                bar(idBase,nobrUserOff);
                xlim([0, length(idBase)+1]);
                xticks(0:2:length(idBase)+1);
                xlabel('Station de base');
                ylabel('Nombre Utilisateur');
                title('Graphique Nombre Utilisateur par BS avec decalage');
              
                
                figure()
                dl= widebandSinrOffdB;
                %tools.myEcdf(mean(dl,2,'omitnan'));
                tools.myEcdf(dl(:));
                hold on
                grid on
                xlabel('widebandSinr');
                ylabel('ECDF');
                
                ddl= obj.widebandSinrdB;
                %tools.myEcdf(mean(ddl,2,'omitnan'));
                tools.myEcdf(ddl(:));
                legend('widebandSinr apres decalage','widebandSinrdB avant decalage', 'Location', 'northEastOutside');
                
                
                            figure();
            leg = [];
                tools.myEcdf(lite2(:));
                hold on;
                grid on;
                tools.myEcdf(lite4(:));
                hold on;
                leg = [leg;"DL SINR";"DL SNR"];
                
                tools.myEcdf(lite12(:));
                hold on;
        		grid on;
                tools.myEcdf(lite14(:));
                hold on;
                leg = [leg;"DL SINR(déc)";"DL SNR(déc)"];
                

            xlabel('lite SINR Downlink in dB');
            ylabel('ECDF');
            title('user lite SINR Downlink avant et après decalage');
            legend(leg, 'Location', 'northwest');
            
            figure();
            leg = [];
                
                tools.myEcdf(lite1(:));
                hold on;
                grid on
                tools.myEcdf(lite3(:));
                leg = [leg;"UL SINR";"UL SNR"];
                
                tools.myEcdf(lite11(:));
                hold on;
                tools.myEcdf(lite13(:));
                leg = [leg;"UL SINR(déc)";"UL SNR(déc)"];

            xlabel('lite SINR Uplink in dB');
            ylabel('ECDF');
            title('user lite Uplink SINR avant et après decalage');
            legend(leg, 'Location', 'northwest');
                
            %------------------------
        end

        % getter functions for dependent properties
        function nSegment = get.nSegment(obj)
            % getter function for number of segments
            %
            % output:
            %   nSegment:   [1x1]integer number of segments in this chunk

            % get number of segments
            if obj.chunkConfig.isNewSegment(1) ==  true
                nSegment = sum(obj.chunkConfig.isNewSegment);
            else
                nSegment = 0;
                warning('The segments are not set yet, but the number of segments is used.');
            end
        end

        function iSegment = getiSegment(obj, iSlot)
            % gets the index of the current segment in this slot.
            %
            % input:
            %   iSlot:  [1x1]integer index of current slot
            %
            % output:
            %   iSegment:   [1x1]integer index of current segment

            % the index of the current segment is the sum of segment completed
            iSegment = sum(obj.chunkConfig.isNewSegment(1:iSlot));
        end

        function iSlot = getiSlot(obj, iSeg)
            % get the index of the first slot in a given segment
            %
            % input:
            %   iSeg:   [1x1]integer index of segment
            %
            % output:
            %   iSlot:  [1x1]integer index of first slot in the segment

            % find the indices of the first slots in segments
            firstSlots = find(obj.chunkConfig.isNewSegment, iSeg);
            % get the index of the first slot in this segment
            iSlot = firstSlots(iSeg);
        end

        % other functions
        function setIsUsersRoi(obj, iSlot)
            % sets isUserRoi indicator for the given slot
            % This function should be called at the beginning of each slot
            % to update the positions of the users.
            %
            % input:
            %   iSlot:  [1x1]integer index of current slot
            %
            % set properties: isUserRoi

            % get matrix with all isInROI indicators
            isInRoi = reshape([obj.users.isInROI], obj.nSlots, obj.nUsers);
            % pick isInROI indicator for this slot
            obj.isUserRoi = isInRoi(iSlot, :);
        end

        %NOTE: these functions are not private so that they can be accessed
        %from outside for testing
        function calculateMacroscopicFading(obj)
            % this function combines the parameters:
            %   - obj.pathLossTable:    [nAntennas x nUsers]double db
            %   - obj.wallLossdB:       [nAntennas x nUsers]double db
            %   - obj.antennaGaindB:    [nAntennas x nUsers]double db
            %   - obj.shadowFadingdB: 	[nAntennas x nUsers x nSegment]double db
            %   - obj.chunkConfig.params.pathlossModelContainer.minimumCouplingLossdB: [1 x nBsTypes] double dB
            % into one parameter to avoid multiple recalculation in the code

            % calculate pathn loss
            obj.pathLossTableDL = obj.pathLossManager.getPathloss(obj.antennaList, obj.users, obj.chunkConfig.isNewSegment);
            %NOTE: wall loss calculation needs blockagemap therefore it is
            %after path loss calcultaion
            obj.calculateWallLoss;
            obj.calculateShadowFading;
            obj.calculateAntennaGain;

            % combine pathlosses
            macrodB = obj.antennaGaindB - obj.pathLossTableDL - obj.wallLossdB - obj.shadowFadingdB;

            % get minimum coupling loss
            bsTypes = [obj.antennaList.baseStationType];
            minCouplingdB = -obj.chunkConfig.params.pathlossModelContainer.minimumCouplingLossdB(bsTypes);
            minCouplingdB = reshape(minCouplingdB, obj.nAntennas, 1, 1);

            % apply minimum coupling loss
            obj.macroscopicFadingdB = min(minCouplingdB, macrodB);
        end
    end

    methods (Access = private)
        function setupPerChunk(obj)
            % sets up the simulation of a chunk
            % This function sets the indicator of new segments, creates the
            % LOS map, sets the indoor/outdoor parameter, and initializes
            % the link performance model.

            % find where new segments start
            obj.setNewSegmentIndicator();

            % initialize lite SNR and SINR
            obj.liteSinrDLdB    = zeros(obj.nUsers, obj.nSlots);
            obj.liteSnrDLdB     = zeros(obj.nUsers, obj.nSlots);
            obj.liteSinrULdB    = zeros(obj.nUsers, obj.nSlots);
            obj.liteSnrULdB     = zeros(obj.nUsers, obj.nSlots);

            % set distance tables and wrap indicator
            obj.pathLossManager = macroscopicPathlossModel.PathLossManagement(...
                obj.chunkConfig.params.pathlossModelContainer, obj.chunkConfig.params, ...
                obj.chunkConfig.buildingList, obj.chunkConfig.wallBlockageList);
            obj.cellManager     = cellManagement.CellAssociation(obj.chunkConfig);

            if ~obj.chunkConfig.params.liteSimulation
                % initialize feedback for all users
                for thisUser = obj.users
                    thisUser.userFeedback.DL.sinrAverager = obj.sinrAverager.DL;
                end

                % initialize the link performance model for up- and downlink
                obj.LPM.DL = linkPerformanceModel.LinkPerformanceModel(...
                    obj.sinrAverager.DL, obj.chunkConfig.params.transmissionParameters.DL, ...
                    obj.chunkConfig.params.bernoulliExperiment, obj.chunkConfig.params.useFeedback);
            end % if this is a full simulation
        end

        function allUsersStatic = checkIfAllUsersAreStatic(obj)
            % checks if any user is moving in this chunk
            %
            % output:
            %   allUsersStatic: [1x1]logical flag indicating if all users are static
            %                   This is set to false if any user changes
            %                   its position during this chunk.

            % initialize return value
            allUsersStatic = true;

            for iUEall = 1:obj.nUsers
                POS = obj.users(iUEall).positionList;
                if nnz(POS(:,2:end)-POS(:,1:end-1)) ~= 0
                    allUsersStatic = false;
                    break;
                end % if the user's position changes at some point in the chunk
            end % for all users
        end

        function setNewSegmentIndicator(obj)
            % creates a logical array that is true for all slots that are the first in a segment
            % Marks all slots, for which a user has moved further than the
            % maximum correlation distance.
            % Large scale parameters are constant for a segment.

            % first see if all users are static
            allUsersStatic = obj.checkIfAllUsersAreStatic;

            % the first slot is always in a new segment
            obj.chunkConfig.isNewSegment(1) = true;
            firstSlotOfSegment = 1;
            if ~allUsersStatic
                for ss = 2:obj.nSlots
                    for iUEall = 1:obj.nUsers
                        currentPosition = obj.users(iUEall).positionList(:,ss);
                        lastUpdatePosition = obj.users(iUEall).positionList(:,firstSlotOfSegment);
                        dist = norm(currentPosition-lastUpdatePosition,2);
                        if dist > obj.chunkConfig.params.maximumCorrelationDistance
                            firstSlotOfSegment = ss;
                            obj.chunkConfig.isNewSegment(ss) = true;
                            break;
                        end % user moved more than the maximum correlation distance for large scale parameters
                    end % for all users
                end % for all slots in the chunk
            end % if any user is moving
        end

        function setLiteSINR(obj, userRoi, iUser, iSlot, userNoisePowersW, macroscopicW, desired, interferer, smallScaleContainer)
            % wrapper function for lite S(I)NR calculation
            %
            % input:
            %   userRoi:                [1x1]handleObjct current user
            %   iUser:                  [1x1]integer index of current user in array of all users
            %   iSLot:                  [1x1]integer index of current slot
            %   userNoisePowersW:       [1x1]double wideband noise power of user in W
            %   macroscopicW:           [nAnt x 1]double macroscopic fading of this user in this segment
            %   desired:                [1 x nAnt]logical indicates desired antennas
            %   interferer:             [1 x nAnt]logical indicates interfering antennas
            %   smallScaleContainer:    [1x1]object smallScaleFading.Container
            %
            % see also liteSnrDLdB, liteSinrDLdB, liteSnrULdB, liteSinrULdB

            % randomly choose resource block in frequency for lite S(I)NR calculation
            iRBFreq = randi(obj.chunkConfig.params.transmissionParameters.DL.resourceGrid.nRBFreq);

            % compute downlink lite SINR and SNR
            obj.calculateLiteSinrDL(desired, interferer, macroscopicW, userNoisePowersW, ...
                smallScaleContainer, userRoi, iUser, iSlot, iRBFreq);

            % compute uplink lite SINR and SNR
            obj.calculateLiteSinrUL(macroscopicW(desired), desired, ...
                smallScaleContainer, userRoi, iUser, iSlot, iRBFreq);
        end

        function calculateLiteSinrDL(obj, desired, interferer, macroscopicFadingW, userNoisePowerW, smallScaleContainer, user, iUser, iSlot, iRBFreq)
            % calculate donwlink lite SNR and SINR for current user
            %
            % input:
            %   desired:                [1 x nAnt]logical desired link antennas
            %   interferer:             [1 x nAnt]integer interfering link antennas
            %   macroscopicFadingW:     [1x1]double macroscopic fading of desired link
            %   userNoisePowerW:        [1x1]double noise power of current user
            %   smallScaleContainer:    [1x1]smallScaleFading.Container small scale fading
            %   user:                   [1x1]networkElements.ue.User current user
            %   iSlot:                  [1x1]integer current time slot
            %   iRBFreq:                [1x1]integer index of randomly chosen resource block in frequency

            % get antenna information
            % check which Basestation is a CompositeBSTech used for spectrum scheduling
            CompBstype   = 'networkElements.bs.compositeBsTyps.CompositeBsTech';
            isCompBStech = arrayfun(@(x)isa(x,CompBstype),obj.baseStations);
            isCompBStechAnt = repelem(isCompBStech,[obj.baseStations.nAnt]);

            % get the number of antennas per basestation
            nAntPerBS = repelem([obj.baseStations.nAnt],[obj.baseStations.nAnt]);
            % get the antenna 2 basestation mapping
            ant2BS = repelem(1:obj.nBaseStations,[obj.baseStations.nAnt]);

            % something like y= arrayfun(@(x) weightMap(char(x)), antTechs)
            % distribute the power evenly between the technologies
            antweight = ones(1, obj.nAntennas);
            antweight(isCompBStechAnt) = antweight(isCompBStechAnt)./nAntPerBS(isCompBStechAnt);

            % filter interferer if he is located on the same Bs with
            % the desired and is a composite basestation for technology
            if isCompBStechAnt(desired)
                sameBSmask = ant2BS == ant2BS(desired);
                interferer(sameBSmask) = false;
            end

            % get channel power of desired channel(s)
            desChannelPower = smallScaleContainer.getLiteChannelPower(user, obj.antennaList(desired), iSlot, iRBFreq);

            % get rxPower
            rxPowerW = [obj.antennaList.transmitPower] .* macroscopicFadingW;

            % get signalPowers with random subcarrier
            signalPowerW = sum(rxPowerW(desired) .* desChannelPower);

            % calculate lite SNR
            obj.liteSnrDLdB(iUser, iSlot) = tools.todB(signalPowerW ./ userNoisePowerW);

            % calculate lite SINR
            if any(interferer)
                intChannelPower = smallScaleContainer.getLiteChannelPower(user, obj.antennaList(interferer), iSlot, iRBFreq);
                % get interferencePowers with random subcarrier
                interferencePowersW = rxPowerW(interferer) .* intChannelPower;
                % multiply by power weighting due to spectrum scheduling - this sums over interferers
                interferencePowersW = interferencePowersW * antweight(interferer)';
                % calculate sinr
                obj.liteSinrDLdB(iUser, iSlot) = tools.todB(signalPowerW ./(interferencePowersW + userNoisePowerW));
            else
                % SINR is SNR if there is no interference
                obj.liteSinrDLdB(iUser, iSlot) = obj.liteSnrDLdB(iUser, iSlot);
            end % if there are interferers
        end

        function calculateLiteSinrUL(obj, macroscopicFadingW, desired, smallScaleContainer, user, iUser, iSlot, iRBFreq)
            % calculate uplink lite SNR and SINR for current user
            %
            % input:
            %   macroscopicFadingW:     [1 x nDes]double macroscopic fading of current user
            %   desired:                [1 x nAnt]integer desired link antennas
            %   smallScaleContainer:    [1x1]smallScaleFading.Container small scale fading
            %   user:                   [1x1]networkElements.ue.User current user
            %   iSlot:                  [1x1]integer current time slot
            %   iSeg:                   [1x1]integer current segment
            %   iRBFreq:                [1x1]integer index of randomly chosen resource block in frequency
            %
            % initial author: Jan Nausner

            % get received signal power of deired signal - sum over all desired antennas
            desChannelPower = smallScaleContainer.getLiteChannelPower(user, obj.antennaList(desired), iSlot, iRBFreq);
            signalPowerW    = sum(user.transmitPower .* macroscopicFadingW .* desChannelPower);

            % get wideband noise power - sum over all desired antennas
            antennaNoisePowerW = sum(networkElements.NetworkElementWithPosition.getNoisePowerW(...
                obj.antennaList(desired), obj.chunkConfig.params.transmissionParameters.DL.resourceGrid));

            % initialize interference power array
            interferenceW = zeros(1, obj.nBaseStations);

            % remove desired base station from loop over interferers
            desiredBSindex = obj.chunkConfig.antennaBsMapper.antennaBsMap(desired, 1);
            iBaseStations = 1:obj.nBaseStations;
            iBaseStations(desiredBSindex(1)) = [];

            % compute the interferer receive powers
            % for each BS select one random user as interferer
            for iBS = iBaseStations
                if ~isempty(obj.baseStations(iBS).attachedUsers)
                    % randomly choose one attached user as interferer
                    nUserCell   = length(obj.baseStations(iBS).attachedUsers);
                    intUser     = obj.baseStations(iBS).attachedUsers(randi(nUserCell));
                    iIntUser    = find([obj.users.id] == intUser.id);

                    % read out uplink macroscopic fading
                    intMacroFadingW = tools.dBto(obj.macroscopicFadingdB(desired, iIntUser, obj.getiSegment(iSlot)).');

                    % read out interferer small scale coefficient
                    intChannelPower = smallScaleContainer.getLiteChannelPower(intUser, obj.antennaList(desired), iSlot, iRBFreq);

                    % calculate interference power
                    interferenceW(iBS) = sum(intUser.transmitPower .* intChannelPower .* intMacroFadingW);
                end % if cell is not empty
            end

            % calculate lite SNR and SINR
            obj.liteSnrULdB(iUser, iSlot)   = tools.todB(signalPowerW / antennaNoisePowerW);
            obj.liteSinrULdB(iUser, iSlot)  = tools.todB(signalPowerW / (sum(interferenceW) + antennaNoisePowerW));
        end

        function filterPureInterferenceCells(obj, iSlot)
            % marks interference region base stations for this slot - sets isRoi for all BSs
            % filterPureInterferenceCells sets the isRoi property for all
            % base stations according to cell association, user positions
            % and base station type for the given slot.
            %
            % Base stations that have only users in the interference region
            % (this means that no antenna of the BS has any user in the
            % ROI) are considered as interference region base stations, which
            % means they only generate interference and no desired signal.
            % Cells that are purely interference region cells - i.e have
            % only interference region users - get a simplified scheduler.
            %
            % input:
            %   iSlot:    [1x1]integer index of current slot

            bsIndices = 1:obj.nBaseStations;

            % find base station that have users but no users in the ROI
            interferenceBS = setdiff(obj.cellManager.userToBSassignment(:,obj.getiSegment(iSlot)), obj.cellManager.userToBSassignment(obj.isUserRoi, obj.getiSegment(iSlot))).';

            for iBS = bsIndices
                if ismember(iBS, interferenceBS) || ~obj.baseStations(iBS).antennaList(1).isInROI(obj.getiSegment(iSlot))
                    % set isInRoi indicator for interference region BSs
                    obj.baseStations(iBS).setIsRoi(false, iSlot);
                else % the BS is in the ROI
                    % set isInRoi indicator for BSs in ROI
                    obj.baseStations(iBS).setIsRoi(true, iSlot);
                end % if this BS is in the interference region
            end % for all base stations that are not of HexRing type
        end

        function performHandover(obj, iSlot)
            % performs handovers - clear feedback buffer and updated
            %  precoders of users that connect to a new base station.
            %
            % input:
            %   iSlot:  [1x1]integer index of current slot
            %
            % extended by: Alexander Bokor, added precoder update

            isFirstSlot = obj.getiSegment(iSlot) == 1;

            % perform handovers
            for iUEall = 1:obj.nUsers
                % index of bs connected in this slot
                iNewBs = obj.cellManager.userToBSassignment(iUEall, obj.getiSegment(iSlot));
                if ~isFirstSlot
                    % if its not the first slot clear the feedback and set the
                    % precoder for users that switched base station.

                    % index of bs connected in last slot
                    iOldBs = isFirstSlot || obj.cellManager.userToBSassignment(iUEall, obj.getiSegment(iSlot)-1);
                    if iOldBs ~= iNewBs
                        % clear feedback buffer
                        obj.users(iUEall).userFeedback.DL.clearFeedbackBuffer();

                        % set new precoders
                        if ~isa(obj.baseStations(iNewBs),'networkElements.bs.CompositeBasestation')
                            obj.users(iUEall).userFeedback.DL.precoder = obj.baseStations(iNewBs).precoder.DL;
                        else
                            iSubBS = obj.cellManager.userToSubBSassignment(iUEall, obj.getiSegment(iSlot));
                            obj.users(iUEall).userFeedback.DL.precoder = obj.baseStations(iNewBs).subBaseStationList(iSubBS).precoder.DL;
                        end
                    end
                else
                    % if it is the first slot, set the precoders for the
                    % users.
                    if ~isa(obj.baseStations(iNewBs),'networkElements.bs.CompositeBasestation')
                        obj.users(iUEall).userFeedback.DL.precoder = obj.baseStations(iNewBs).precoder.DL;
                    else
                        iSubBS = obj.cellManager.userToSubBSassignment(iUEall, obj.getiSegment(iSlot));
                        obj.users(iUEall).userFeedback.DL.precoder = obj.baseStations(iNewBs).subBaseStationList(iSubBS).precoder.DL;
                    end
                end
            end % for all users in the simulation
        end

        function desired = setDesiredAntenna(obj, iUE, iSegment)
            % set desired array
            % Desired array indicates which antennas are the desired
            % antennas for the current user in this segment.
            %
            % input:
            %   iUE:        [1x1]integer index of current user
            %   iSegment:   [1x1]integer index of current segment
            %
            % ouput:
            %   desired:    [1 x nAntnennas]logical indicates desired antennas
            %               Desired antennas are set to true, interfering
            %               antennas are set to false.

            % initialize output
            desired             = false(1, obj.nAntennas);

            % get index of desired base station
            bb                  = obj.cellManager.userToBSassignment(iUE, iSegment);
            % get indices of antennas of desired base station
            antIndices          = obj.chunkConfig.antennaBsMapper.getGlobalAntennaIndices(bb);

            % clear indices where technology differs
            clearIndices = [obj.antennaList(antIndices).technology] ~= obj.users(iUE).technology;
            % clear indices where nummerology differs
            clearIndices = (clearIndices | [obj.antennaList(antIndices).numerology] ~= obj.users(iUE).numerology);
            antIndices(clearIndices) = [];

            % set desired array
            desired(antIndices)	= true;
        end

        function calculateAntennaGain(obj)
            % gets all antenna gains for preliminary SINR calculations
            %
            % see also networkElements.bs.Antenna,
            % networkElements.bs.antennas.Omnidirectional,
            % networkElements.bs.antennas.Sector,
            % simulation.ChunkSimulation.antennaGaindB

            % initializes antenna gain
            obj.antennaGaindB = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);

            for iAnt = 1:obj.nAntennas
                for iSeg = 1:obj.nSegment
                    % calulate antenna gains between this antenna and all users
                    obj.antennaGaindB(iAnt,:,iSeg) = obj.antennaList(iAnt).gain(obj.users, obj.getiSlot(iSeg), iSeg);
                end % for all segments
            end % for all antennas
        end

        function calculateWallLoss(obj)
            % calculates and sets wallLossdB property

            if ~isempty(obj.chunkConfig.buildingList) || ~isempty(obj.chunkConfig.wallBlockageList)
                % get list with all walls in the simulation
                orderedWallList = blockages.Blockage.getOrderedWallList(obj.chunkConfig.buildingList, obj.chunkConfig.wallBlockageList);
                % replicate the loss for each wall for all antennas, all users and all slots
                wallLossTmp = repmat([orderedWallList.loss].',[1, obj.nAntennas, obj.nUsers, obj.nSegment]);
                % make wallLosstmp a [nAntennas x nUsers x nWalls x nSlots] matrix
                wallLossTmp = permute(wallLossTmp,[2, 3, 1, 4]);
                % sum the loss of all walls blocking one link, and shape wallLossdB in a [nAntennas x nUsers x nSlots] matrix
                obj.wallLossdB = reshape(sum(obj.pathLossManager.blockageMapUserAntennas .* wallLossTmp, 3), obj.nAntennas, obj.nUsers, obj.nSegment);
            else
                obj.wallLossdB = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);
            end
        end

        function calculateShadowFading(obj)
            % calculates shadow fading and sets shadowFadingdB

            if obj.chunkConfig.params.shadowFading.on
                resolution = obj.chunkConfig.params.shadowFading.resolution;
                sizeX      = ceil(obj.chunkConfig.params.regionOfInterest.interferenceRegion.ySpan/resolution);
                sizeY      = ceil(obj.chunkConfig.params.regionOfInterest.interferenceRegion.xSpan/resolution);
                mapCorr    = obj.chunkConfig.params.shadowFading.mapCorr;
                meanSFV    = obj.chunkConfig.params.shadowFading.meanSFV;
                stdDevSFV  = obj.chunkConfig.params.shadowFading.stdDevSFV;
                decorrDist = obj.chunkConfig.params.shadowFading.decorrDist;

                % initialize shadow fading map
                sfm = shadowing.ShadowFadingMapLinearFiltering(sizeX, sizeY, obj.nAntennas, resolution, mapCorr, meanSFV, stdDevSFV, decorrDist);

                % set shadow fading for each link in each slot
                userPosition = [obj.users.positionList];
                for iAntenna = 1:obj.nAntennas
                    x = userPosition(1,:)-obj.chunkConfig.params.regionOfInterest.interferenceRegion.xMin;
                    y = userPosition(2,:)-obj.chunkConfig.params.regionOfInterest.interferenceRegion.yMin;
                    % shadow fading values in dB
                    sfvdB = sfm.getPathlossPoint(x,y,iAntenna);
                    % reshape to matrix form
                    sfvdB = reshape(sfvdB, obj.chunkConfig.params.time.slotsPerChunk, obj.nUsers)';
                    % remap from Slot to Segment
                    obj.shadowFadingdB(iAntenna,:,:) = sfvdB(:,obj.chunkConfig.isNewSegment);
                end
            else % no shadow fading
                % set shadow fading for each link in each slot
                obj.shadowFadingdB = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);
            end % if shadow fading is used
        end

        function s = initializeScheduler(obj)
            % initialize scheduler for all base stations
            %
            % output:
            %   s:  [1 x nBaseStations]handleObject scheduler.Scheduler
            %       empty for lite simulation

            if ~obj.chunkConfig.params.liteSimulation

                % preallocate schedulers
                s(1:obj.nBaseStations) = scheduler.Scheduler.generateScheduler(...
                    obj.chunkConfig.params, obj.baseStations(obj.nBaseStations), obj.sinrAverager);

                % set scheduler for each base station
                for iBS = 1:obj.nBaseStations
                    s(iBS) = scheduler.Scheduler.generateScheduler(...
                        obj.chunkConfig.params, obj.baseStations(iBS), obj.sinrAverager);
                end

            else % lite simulation
                % no scheduling in lite simulations
                s = [];
            end
        end

        function getNewTraffic(obj, iSlot)
            % call a traffic model function to check whether
            % new data packet has to be generated and appended to packets
            % buffer in the current slot
            %
            % input
            %   iSlot:    	 [1x1]double index of current slot
            %
            % initial author: Areen Shiyahin

            % check if generation of new packet is needed
            for iUser = obj.users
                iUser.trafficModel.checkNewPacket(iSlot);
            end
        end

        function scheduling(obj, schedulers, iSlot)
            % calls scheduling function for each base station
            % (if this is a full simulation otherwise it does nothing)
            %
            % input:
            %   schedulers: [1 x nBaseStations]handleObject scheduler.Scheduler
            %   iSlot:    	[1x1]integer index of current slot

            for iBS = 1:obj.nBaseStations
                attachedUsers = obj.baseStations(iBS).attachedUsers;

                % update cell association at scheduler
                schedulers(iBS).updateAttachedUsers(attachedUsers);

                % schedule users
                if obj.baseStations(iBS).isRoi
                    schedulers(iBS).scheduleDL(iSlot);
                else % simplified interference region scheduling
                    schedulers(iBS).scheduleDLDummy();
                end % if this BS has users in the ROI
            end % for all base stations
        end

        function LQMDL = initializeLQM(obj)
            % initializes link quality model for each receiver
            %
            % output:
            %   LQMDL:  [1 x xnUsers]handleObject linkQualityModel.LinkQualityModel

            % preallocate one LQM per user for DL
            LQMDL(1, 1:obj.nUsers) = linkQualityModel.ZeroForcing(...
                obj.chunkConfig.params, obj.chunkConfig.params.transmissionParameters.DL.resourceGrid, ...
                obj.chunkConfig.antennaBsMapper, obj.iniCache);
            for iUE = 1:obj.nUsers
                % initialize one LQM per user for DL
                LQMDL(iUE) = linkQualityModel.ZeroForcing(...
                    obj.chunkConfig.params, obj.chunkConfig.params.transmissionParameters.DL.resourceGrid, ...
                    obj.chunkConfig.antennaBsMapper, obj.iniCache);
                LQMDL(iUE).setLinkParameters(obj.antennaList, obj.users(iUE));
            end
        end

        function calculateAnalogPrecoder(obj)
            % calculate and set analog precoder for each antenna
            %
            % see also precoder.analog

            for iAnt = 1:obj.nAntennas
                obj.antennaList(iAnt).W_a = obj.antennaList(iAnt).precoderAnalog.calculatePrecoder(obj.antennaList(iAnt));
            end
        end
    end
end

