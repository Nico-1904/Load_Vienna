classdef CellAssociation < tools.HiddenHandle
    %CellAssociation calculates wideband SINR and sets cell association
    % The cellAssociationStrategy decides which parameter is used to
    % decide the pairing between base station and user. Each user is served
    % by the base station to which the cell association metric is the
    % highest.
    % The cell association also considers the cellAssociationBias and the
    % technologies and only associates users to base stations with the same
    % technology.
    % The cell association also calculates the macroscopic receive power
    % and the wideband SINR.
    %
    % initial author: Christoph Buchner
    %
    % see also parameters.setting.CellAssociationStrategy,
    % simulation.ChunkSimulation, userToBSassignment,
    % parameters.Parameters.cellAssociationStrategy,
    % parameters.PathlossModelContainer.cellAssociationBiasdB,
    % setCellAssociationTable

    properties
        % cell association strategy
        % [1x1]enum parameters.setting.CellAssociationStrategy
        %
        % see also parameters.setting.CellAssociationStrategy,
        % parameters.Parameters.cellAssociationStrategy
        cellAssociationStrategy

        % cell association table
        % [nUsers x nSegment]integer index of base station this user is associated to
        %
        % Example: the first user is attached to the first base station in
        % the first segment and to the second base station from the second
        % segment onwards. Then, the first line of the userToBSassignment
        % will be [1 2 2 2 2 2], assuming there are 5 segments in a chunk.
        %
        % see also tools.AntennaBsMapper.getBSindex
        userToBSassignment

        % sub base station association table
        % [nUsers x nSegment]integer index of sub base station this user is associated to
        %
        % see also tools.AntennaBsMapper.getSubBSindex
        userToSubBSassignment

        % antenna association table
        % [nUsers x nSegment]integer index of sub base station this user is associated to
        %
        % see also tools.AntennaBsMapper.getSubBSindex
        userToAntassignment

        % NOMA user pairing
        % {nBaseStations x nSegment}cell[2 x nNOMA]integer NOMA user pairs
        % (1,:) far user with bad channel condition that will suffer additional interference
        % (2,:) near user with good channel condition that will perform SIC
        %
        % see also networkElements.bs.BaseStation.nomaPairs
        nomaUserPairing

        % list of all base stations in the simulation
        % [1 x nBaseStations]handleObject networkElements.bs.BaseStation
        %
        % see also networkElements.bs.BaseStation, networkElements.bs.CompositeBasestation
        baseStations

        % list of all users in the simulation
        % [1 x nUsers]handleObject networkElements.ue.User
        users

        % list of all antennas in the simulation
        % [1 x nAntennas]handleObject networkElements.bs.Antenna
        antennas

        % number of users in the simulation
        % [1x1]integer
        nUsers

        % number of antennas in the simulation
        % [1x1]integer
        nAntennas

        % number of base stations in the simulation
        % [1x1]integer
        nBaseStations

        % number of segments in the simulation
        % [1x1]integer
        nSegment

        % bias factor for small cells (linear)
        % [nAntennas x 1]double cell association bias factor (linear)
        %
        % see also parameters.PathlossModelContainer.cellAssociationBiasdB
        cellAssociationBias

        % NOMA minimum difference in cell association metric
        % [1x1]double minimum power difference between paired NOMA users in dB
        %
        % see also parameters.Noma.deltaPairdB
        nomaDeltadB

        % NOMA MUST index
        % [1x1]enum parameters.setting.MUSTIdx
        %
        % see also parameters.setting.MUSTIdx, parameters.Noma.mustIdx
        nomaMustIdx

        % base station to antenna mapper
        % [1x1]handleObject tools.AntennaBsMapper
        %
        % see also tools.AntennaBsMapper
        antennaBsMapper
        
        %by Nico Kabongo
        elementBis
        
        elementBis1
        
        elementBis2
        
        elementBis3
        
        elementBis4
        %--------------
    end

    methods
        function obj = CellAssociation(chunkConfig)
            % set common properties used in all the sub classes if the cellManagement
            %
            % input:
            %   chunkConfig:    [1x1]handleObject simulation.ChunkConfig

            % set cell association strategy
            obj.cellAssociationStrategy = chunkConfig.params.cellAssociationStrategy;

            % set properties
            obj.baseStations    = chunkConfig.baseStationList;
            obj.users           = chunkConfig.userList;
            obj.antennas        = [obj.baseStations.antennaList];
            obj.nUsers          = size(obj.users,2);
            obj.nAntennas       = size(obj.antennas,2);
            obj.nSegment        = sum(chunkConfig.isNewSegment);
            obj.nBaseStations   = size(obj.baseStations,2);
            obj.nomaDeltadB     = chunkConfig.params.noma.deltaPairdB;
            obj.nomaMustIdx     = chunkConfig.params.noma.mustIdx;

            % mapping from antennas index to bs index
            obj.antennaBsMapper = chunkConfig.antennaBsMapper;

            % set small cell association bias for each link
            obj.cellAssociationBias = tools.dBto(chunkConfig.params.pathlossModelContainer.cellAssociationBiasdB([obj.antennas.baseStationType]))';

            % NOMA pairing initialization
            obj.nomaUserPairing = cell(obj.nBaseStations, obj.nSegment);
        end

        function [receivePowerdB, widebandSinrdB, SinrLoad] = setCellAssociationTable(obj, macroscopicFadingW, userNoisePowersW)
            % set cell association table
            % Calculates the cell association metric for all links, sets
            % metric to nan for incompatible links and adds cell
            % association bias for small cells. Then, chooses the link with
            % the highest cell association metric as desired link and sets
            % the userToBSassignment table.
            % The assignment between user and base station is constant over
            % a segment.
            %
            % input:
            %	macroscopicFadingW: [nAntennas x nUsers x nSegment]double macroscopic fading in W
            %   userNoisePowersW:   [1 x nUsers]double noise powers of each user for whole bandwidth in W
            %
            % output:
            %   receivePowerdB: [nAntennas x nUsers x nSegment]double macroscopic power received in dB
            %   widebandSinrdB: [nUsers x nSegment]double wideband SINR in dB
            %
            % initial author: Christoph Buchner
            %
            % see also: parameters.settings.cellAssociationStrategy,
            % simulation.chunkSimulation.runSimulation

            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            % calculate receive power and wideband SINR
            receivePower = [obj.antennas.transmitPower]' .* macroscopicFadingW;
            receivePowerdB = tools.todB(receivePower);
            widebandSinr = obj.getWidebandSinr(receivePower, userNoisePowersW);
            
            Snrf = obj.getSinrToload(receivePower, userNoisePowersW, 1);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinr;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePower;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinr;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);

            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrdB(iUser,iSegment) = tools.todB(widebandSinr(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                    SinrLoad(iUser,iSegment) =  Snrf(obj.userToAntassignment(iUser,iSegment),iUser,iSegment);
                end
            end
        end
        
        %By Nico Kabongo
              function x = solveEquations(obj, R, sigma1, J)
            iBaseStations = 1:obj.nBaseStations;
            n=length(iBaseStations);
        function F = root2d6(x)
            r = 1500/(100*180);
            x0 =0;
            n0 =0;
            F0=0;
            t0=0;
%             J1= [2, 4];
%             J2= [1, 3, 5];
%             J3=[6]
%             J= {J1, J2, J3};

            for i = 1:n
                a=obj.functionTest(i,n);
                b=J{i};
                    for q = 1:length(b)
                        for p = 1:length(a)
                            t0 = t0 + R(a(p),b(q))*x(a(p));    
                        end
                            x0 = x0 + (r/log2(1 + (R(i,b(q))/(t0 + sigma1(i)))));
                            t0=0;
                    end
                F(i) = x(i) - x0;
                x0=0;
            end
        end
        fun = @root2d6;
            x0 = 2 * ones(n, 1)'
            %options = optimoptions('fsolve', 'StepTolerance', 1e-6, 'FunctionTolerance', 1e-6);
            x = fsolve(fun, x0);
      end

        function Element = functionTest(obj,ElementCourant, dim)
            for i = 1:dim
                A(i) = i;
            end
                A(ElementCourant) = [];
                Element = A;
        end
        
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);
            SnrdB = zeros(obj.nUsers, obj.nSegment);

            % calculate receive power and wideband SINR
            receivePower = [obj.antennas.transmitPower]' .* macroscopicFadingW;
            
            receivePowerMat = receivePower;
          for k = 1:30
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.999999999999999 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
            
            transMat = receivePowerMat;
            
            %ici maintenant c'est pour les cellules femto
%             for i = 1:numel(indLowFemto)
%                ligne_indLowFemto = transMat(indLowFemto(i), :);
%     
%                max_val = min(ligne_indLowFemto);
%                %if max_val > 0
%                max_val_new = max_val + 10 * (max_val);
%                networkOffset;
%                if max_val_new < 0
%                    max_val_new = max_val_new + 0.000005
%                end
%                ligne_indLowFemto(ligne_indLowFemto == max_val) = 0.00000201;
%     
%                  transMat(indLowFemto(i), :) = ligne_indLowFemto;
%                %end
%             end %fin for femto
          end
            %------------------------------
                        
                    %case parameters.setting.BaseStationType.macro
                %end
            %end
            
            receivePowerMatFinal = transMat;
            
            haveSameElements = isequal(receivePowerMat, receivePowerMatFinal);

if haveSameElements
   % disp('Les matrices femto et macro ont les m�mes �l�ments.');
else
   % disp('Les matrices femto et macro ont des �l�ments diff�rents.');

    % Identifier les �l�ments qui diff�rent
    difference = transMat - receivePowerMatFinal;
end

            receivePowerOff =receivePowerMatFinal;
            obj.elementBis = receivePowerMatFinal;
            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);
            
            Snr = obj.getSinrToload(receivePowerOff, userNoisePowersW, 1);
            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                    Snr(iUser,iSegment) = tools.todB(Snr(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + 1.5*(tools.dBto(widebandSinrOffdB))));
%             sum_rho_abs = abs(sum(load_BSoff))^2;
%             sum_rho_squared = length(load_BSoff) * sum(load_BSoff.^2);
%             IndiceEquite = sum_rho_abs / sum_rho_squared
%indColIntFinal = obj.getInterfence(receivePower);
        end
        
        %ici Bis
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad2(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            receivePower = obj.elementBis;
            
            receivePowerMat = receivePower;
          for k = 1:20
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.99 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
          end
            
            transMat = receivePowerMat;
            
            %ici maintenant c'est pour les cellules femto
%             f=[1,4,6,8,9];
%             for k = 1:5
%             for i = 1:numel(f)
%                ligne_indLowFemto = transMat(f(i), :);
%     
%                max_val = max(ligne_indLowFemto);
%                %if max_val > 0
%                max_val_new = max_val - 0.999 * (max_val);
%                networkOffset;
%                if max_val_new < 0
%                    max_val_new = max_val_new + 0.000005
%                end
%                ligne_indLowFemto(ligne_indLowFemto == max_val) = max_val_new;
%     
%                  transMat(f(i), :) = ligne_indLowFemto;
%                %end
%             end %fin for femto
%             end
            receivePowerMatFinal = transMat;

            receivePowerOff =receivePowerMatFinal;
            obj.elementBis1 = receivePowerMatFinal;
            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);
            
            Snr = obj.getSinrToload(receivePowerOff, userNoisePowersW, 1);
            
            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
            Snr = receivePower ./ userNoisePowersW;
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + 1.5 * tools.dBto(widebandSinrOffdB)));
        end

        %---------------Fin bis
        
        %ici Bis1
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad3(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            receivePower = obj.elementBis1;
            
            receivePowerMat = receivePower;
          for k = 1:50
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.99 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
          end
            
            transMat = receivePowerMat;
            
            receivePowerMatFinal = transMat;

            receivePowerOff =receivePowerMatFinal;
            obj.elementBis2 = receivePowerMatFinal;
            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);
            
            Snr = obj.getSinrToload(receivePowerOff, userNoisePowersW, 1);
            
            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + 1.5 * tools.dBto(widebandSinrOffdB)));
        end

        %---------------Fin bis1
        
        %ici Bis2
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad4(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            receivePower = obj.elementBis2;
            
            receivePowerMat = receivePower;
          for k = 1:9
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.99 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
          end
            
            transMat = receivePowerMat;
            
            receivePowerMatFinal = transMat;

            receivePowerOff =receivePowerMatFinal;
            obj.elementBis3 = receivePowerMatFinal;
            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);
            
            Snr = obj.getSinrToload(receivePowerOff, userNoisePowersW, 0.2);
            
            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
            Snr = receivePower ./ userNoisePowersW;
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + 1.5 * tools.dBto(widebandSinrOffdB)));
        end

        %---------------Fin bis2
        
        %ici Bis3
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad5(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            receivePower = obj.elementBis3;
            
            receivePowerMat = receivePower;
          for k = 1:6
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.99 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
          end
            
            transMat = receivePowerMat;
                        %ici maintenant c'est pour les cellules femto
%             for i = 1:numel(indLowFemto)
%                ligne_indLowFemto = transMat(indLowFemto(i), :);
%                
%                test1=transMat(indLowFemto(2), :);
%     
%                max_val = max(ligne_indLowFemto);
%                %if max_val > 0
%                max_val_new = max_val + 2 * (max_val);
%                networkOffset;
%                if max_val_new < 0
%                    max_val_new = max_val_new + 0.000005
%                end
%                ligne_indLowFemto(ligne_indLowFemto == max_val) = 0.0000046;
%     
%                  transMat(indLowFemto(i), :) = ligne_indLowFemto;
%                %end
%             end %fin for femto
            
            receivePowerMatFinal = transMat;

            receivePowerOff =receivePowerMatFinal;
            obj.elementBis4 = receivePowerMatFinal;
            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);
            
            Snr = obj.getSinrToload(receivePowerOff, userNoisePowersW, 1);
            
            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + tools.dBto(widebandSinrOffdB)));
        end

        %---------------Fin bis3
        
        %ici Bis3
        function [receivePowerOffdB, widebandSinrOffdB, load_BSoff] = getUpdateAssociationWithLoad6(obj, macroscopicFadingW, userNoisePowersW, indHighMacro, indLowFemto,  networkOffset)
            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            receivePower = obj.elementBis4;
            
            receivePowerMat = receivePower;
           for k = 1:30
            for i = 1:numel(indHighMacro)
               ligne_indHighMacro = receivePowerMat(indHighMacro(i), :);
    
               max_val = max(ligne_indHighMacro);
               max_val_new = max_val - 0.999999999 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
               ligne_indHighMacro(ligne_indHighMacro == max_val) = max_val_new;
    
                 receivePowerMat(indHighMacro(i), :) = ligne_indHighMacro;
            end
           end
           for k=1:25
            transMat = receivePowerMat;
                                    %ici maintenant c'est pour les cellules femto
            for i = 1:numel(indLowFemto)
               ligne_indLowFemto = transMat(indLowFemto(i), :);
               ligne_indLowFemto = ligne_indLowFemto + 0.00000000236;
               max_val = min(ligne_indLowFemto);
               %if max_val > 0
               max_val_new = max_val + 2 * (max_val);
               networkOffset;
               if max_val_new < 0
                   max_val_new = max_val_new + 0.000005
               end
              % ligne_indLowFemto(ligne_indLowFemto == max_val) = 1.9111246;
                 transMat(indLowFemto(i), :) = ligne_indLowFemto;
               %end
            end %fin for femto
           end
            
            
            receivePowerMatFinal = transMat;

            receivePowerOff =receivePowerMatFinal;

            receivePowerOffdB = tools.todB(receivePowerOff);
            widebandSinrOff = obj.getWidebandSinr(receivePowerOff, userNoisePowersW);

            % choose cell association metric
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinrOff;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePowerOff;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinrOff;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);

            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrOffdB(iUser,iSegment) = tools.todB(widebandSinrOff(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
                end
            end
            Snr = receivePower ./ userNoisePowersW;
             %load_BSoff = 1500 ./ (100 * 180 * log2(1 + Snr));
             load_BSoff = 1500 ./ (100 * 180 * log2(1 + 1.5 * tools.dBto(widebandSinrOffdB)));
        end

        %---------------Fin bis4
        
        function LoadCell = getLoadCell(obj, macroscopicFadingW, userNoisePowersW)
            
            % input:
            %	macroscopicFadingW: [nAntennas x nUsers x nSegment]double macroscopic fading in W
            %   userNoisePowersW:   [1 x nUsers]double noise powers of each user for whole bandwidth in W
            %
            % output:
            %   receivePowerdB: [nAntennas x nUsers x nSegment]double macroscopic power received in dB
            %   widebandSinrdB: [nUsers x nSegment]double wideband SINR in dB
            %

            widebandSinrdB = zeros(obj.nUsers, obj.nSegment);

            % calculate receive power and wideband SINR
            receivePower = [obj.antennas.transmitPower]' .* macroscopicFadingW;
            receivePowerdB = tools.todB(receivePower);
            widebandSinr = obj.getWidebandSinr(receivePower, userNoisePowersW);
            
            switch obj.cellAssociationStrategy
                case parameters.setting.CellAssociationStrategy.maxSINR
                    cellAssociationMetric = widebandSinr;
                case parameters.setting.CellAssociationStrategy.maxReceivePower
                    cellAssociationMetric = receivePower;
                otherwise
                    warning('The chosen cell association metric is invalid. Maximum SINR will be used.');
                    cellAssociationMetric = widebandSinr;
            end
            % set metric of incompatible links to nan
            cellAssociationMetric(~obj.getCompatibliltyMatrix) = nan;

            % set cell association table based on cell association metric
            obj.setUserToAntAssignment(cellAssociationMetric .* obj.cellAssociationBias);

            for iSegment = 1:obj.nSegment
                for iUser = 1:obj.nUsers
                    widebandSinrdB(iUser,iSegment) = tools.todB(widebandSinr(obj.userToAntassignment(iUser,iSegment),iUser,iSegment));
               
                end
            end
            %LoadCell = zeros(obj.nUsers, obj.nSegment);
            %widebandSinrdB = tools.todB(widebandSinr); 
            LoadCell = 1500 ./ (100 * 180 * log2(1 + tools.dBto(widebandSinrdB)));
            %LoadCell = log2(1 + widebandSinr);
            iBaseStations = 1:obj.nBaseStations;
            %a=obj.baseStations.antennaList.id
            for iBS = iBaseStations
                %switch obj.baseStations.antennaList.baseStationType
                    %case parameters.setting.BaseStationType.macro
                attachedUsers = obj.baseStations(iBS).attachedUsers;
                %end
            end
        end
        
        %--------------------------------------

        function setUserToAntAssignment(obj, cellAssociationMetric)
            % select the link with the maximal received Power. Between
            % antennas user pairs under the same condition a randome selection is done.
            %
            % input:
            %   cellAssociationMetric:  [nAntennas x nUsers x nSegment]double link condition of each antenna to user connection
            %                           Including cellAssociationBiasdB.
            %
            % see also cellManagement.CellAssociation.setCellAssociationTable

            % set sinrArray to unreachable elements to make sure
            % incompatible pairs are not selected

            % find all the maximum entries in the antenna dimension because
            % they resemble antenna user links with the best available
            % condition
            [maxAssValues] = max(cellAssociationMetric,[],1);
            [iAnt,iCol] = find(maxAssValues == cellAssociationMetric);
            antOptions = (iCol== unique(iCol)');

            % count the Antennas with best conditions
            nMaxPerAnt = sum(antOptions,1);
            % pick a random Antenna from these
            antChoice =  ceil(rand(size(nMaxPerAnt)).*nMaxPerAnt);
            % convert antChoice to Global index
            offset = cumsum(nMaxPerAnt);
            offset = [0,offset(1:(end-1))];
            antChoice = antChoice + offset;
            % reshape secondary dimesion to [ nUsers x nSegment]
            userToAntAssignmentArray = reshape(iAnt(antChoice),size(cellAssociationMetric,2),[]);

            % set association to zero if no antenna satisfies the user
            % technology constraints
            %NOTE: this throws an error in the LQM however there should
            %always be at least one antenna satisfying the user technology
            %and numerology constraints
            userToAntAssignmentArray(isnan(maxAssValues)) = 0;

            % remap from antenna index to base station index
            obj.userToAntassignment = userToAntAssignmentArray;
            obj.userToBSassignment = obj.antennaBsMapper.getBSindex(userToAntAssignmentArray);
            obj.userToSubBSassignment = obj.antennaBsMapper.getSubBSindex(userToAntAssignmentArray);

            % find NOMA user pairs
            for iSeg = 1:obj.nSegment
                obj.setNomaUserPairing(maxAssValues(:,:,iSeg), iSeg);
            end
        end

        function SINRArrayDL = getWidebandSinr(obj, receivedPowerArray, userNoisePowersW)
            % get preliminary SINR used for cell association. Does not
            % account for scheduling but does use estimates about spectrum
            % scheduling. Similar to calculateLiteSinr in the chunkSimulation
            % but calculation is carried out without the use of the link quality model.
            %
            % input:
            %   receivedPowerArrayDL:   [nAntennas x nUsers x nSegment]double
            %       receive power on each antenna user pairing over all
            %       segments
            %   userNoisePowersW:       [1 x nUser]double users noise power for whole bandwidth
            %
            % output:
            %   SINRArrayDL:    [nAntennas x nUsers x nSegment]double linear
            %       estimate of the expected SINR only considering
            %       macroscopic fading effects ad interfence of the non
            %       desired base stations

            % get default desired interferer indicators
            desiredMat = eye(obj.nAntennas);

            % get noise power
            userNoisePowerArray = repmat(userNoisePowersW, [obj.nAntennas, 1, obj.nSegment]);

            % get interference
            interfererMat   = ~desiredMat;
            % weight the interference from composite BSs to avoid doubling
            % the interference from BSs with several technologies
            interfererMat   = obj.getSpectrumSharingPowerWeight .* interfererMat;

            % calculate interference based on received power, the weighting
            % and the interferer
            interferencePowersArray = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);
            for iSeg = 1:obj.nSegment
                interferencePowersArray(:, :, iSeg) = interfererMat * receivedPowerArray(:,:,iSeg);
            end
            %----BY Nico Kabongo
            MeanMAT = mean(interferencePowersArray(:));
            %interferencePowersArray = 0.6 * interferencePowersArray;
            %---------------

            % calculate SINR
            SINRArrayDL = receivedPowerArray ./ (userNoisePowerArray + interferencePowersArray);
        end

        %By Nico kabongo
        function SINRToLoad = getSinrToload(obj, receivedPowerArray, userNoisePowersW, r)
          
            % get default desired interferer indicators
            desiredMat = eye(obj.nAntennas);

            % get noise power
            userNoisePowerArray = repmat(userNoisePowersW, [obj.nAntennas, 1, obj.nSegment]);
            
            % get interference
            interfererMat   = ~desiredMat;
            % weight the interference from composite BSs to avoid doubling
            % the interference from BSs with several technologies
            interfererMat   = obj.getSpectrumSharingPowerWeight .* interfererMat;

            % calculate interference based on received power, the weighting
            % and the interferer
            interferencePowersArray = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);
            for iSeg = 1:obj.nSegment
                interferencePowersArray(:, :, iSeg) = interfererMat * receivedPowerArray(:,:,iSeg);
            end

            % calculate SINR
            SINRToLoad = receivedPowerArray ./ (userNoisePowerArray + r * interferencePowersArray);
        end
        
        function indColIntFinal = getInterfence(obj, receivedPowerArray)
            % get default desired interferer indicators
            desiredMat = eye(obj.nAntennas);

            % get interference
            interfererMat   = ~desiredMat;
            % weight the interference from composite BSs to avoid doubling
            % the interference from BSs with several technologies
            interfererMat   = obj.getSpectrumSharingPowerWeight .* interfererMat;

            % calculate interference based on received power, the weighting
            % and the interferer
            interferencePowersArray = zeros(obj.nAntennas, obj.nUsers, obj.nSegment);
            for iSeg = 1:obj.nSegment
                interferencePowersArray(:, :, iSeg) = interfererMat * receivedPowerArray(:,:,iSeg);
            end
            %----BY Nico Kabongo
            % Valeur seuil
            %meanMat = mean(interferencePowersArray(:));
            %interfervalue = all(interferencePowersArray < meanMat);
            %interfervalue;
           % indColInt = find(interferencePowersArray < meanMat);
           % indColInt = interferencePowersArray(:, interfervalue);
            %indColInt = find(all(interferencePowersArray < meanMat));
            %length(indColInt);
            rankingInterfer = sort(interferencePowersArray(:), 'descend');
            firstFifty = rankingInterfer(1:200);
            meanMat = mean(firstFifty(:));
            %meanMat = mean(rankingInterfer(:));
            [interfervalue] = interferencePowersArray(interferencePowersArray > meanMat);
            length(interfervalue);
            [indAntInt,indColInt] = find(interferencePowersArray > meanMat);
            length(indColInt);
            indColIntFinal = unique(indColInt)';

            interferencePowersArray;
            %---------------

        end
        %-------------
        
        
        function powerWeightMat = getSpectrumSharingPowerWeight(obj)
            % calculates a weight matrix estimating the change in the
            % interference power due to spectrum sharing
            % for all antennas.
            %
            % output:
            %   powerWeightMat [nAntennas x nAntennas]double estimates the influence of the spectrum sharing in the

            % get antenna information
            % check which Base station is a CompositeBSTech used for spectrum scheduling
            CompBstype   = 'networkElements.bs.compositeBsTyps.CompositeBsTech';
            isCompBStech = arrayfun(@(x)isa(x,CompBstype), obj.baseStations);
            % replicate result for each antenna on the base station
            isCompBStechAnt = repelem(isCompBStech,[obj.baseStations.nAnt]);

            % get the number of antennas per basestation
            nAntPerBS = repelem([obj.baseStations.nAnt],[obj.baseStations.nAnt]);

            % distribute the power evenly between the technologies
            antweight                   = ones(1, obj.nAntennas);
            antweight(isCompBStechAnt)  = antweight(isCompBStechAnt)./nAntPerBS(isCompBStechAnt);

            % repeat weighting factors for each antenna
            powerWeightMat = repmat(antweight ,obj.nAntennas,1);
            powerWeightMat = min(powerWeightMat, powerWeightMat');

            % find elements with same BS id
            sameBSMat = repmat(obj.antennaBsMapper.antennaBsMap(:,1)', obj.nAntennas, 1);
            sameBSMat = sparse(sameBSMat == sameBSMat');

            % Antennas with a CompositeBSTech
            isCompBSMat     = repmat(isCompBStechAnt,obj.nAntennas,1);

            % reset powerWeightMat matrix where interferer is both a compositeBSTech
            % and is placed on the same BS
            powerWeightMat(and(sameBSMat,isCompBSMat)) = 0;

        end

        function compatibilityMatrix = getCompatibliltyMatrix(obj)
            % get matrix indicating which users anre compatible with which antennas
            % Check for each user and antenna pair if a direct link is
            % possible based on their technology and their numerology.
            %
            % output:
            %   compatibilityMatrix:    [nAntennas x nUsers x nSegment]logical defines which antenna and user can link up

            % create technology compatibility matrix [nAntennas x nUsers]
            technologyCompatibility = ...
                repmat([obj.antennas.technology]', 1, obj.nUsers) ==...
                repmat([obj.users.technology], obj.nAntennas, 1);

            % create numerlogoy compatibility matrix [nAntennas x nUsers]
            numerologyCompatibility = ...
                repmat([obj.antennas.numerology]', 1, obj.nUsers) ==...
                repmat([obj.users.numerology], obj.nAntennas, 1);

            % combine numerology and technology information
            compatibilityMatrix = technologyCompatibility .* numerologyCompatibility;

            % replicate for all segments
            compatibilityMatrix = repmat(compatibilityMatrix, [1,1,obj.nSegment]);
        end

        function updateUsersAttachedToBaseStations(obj, iSegment)
            % updates users attached to each base station for this segment
            % This function takes the cell association saved in
            % userToBSassignment for the current slot and updates
            % the baseStations' attached users accordingly.
            %
            % This function should be called at the beginning of each
            % segment, or when the cell association has changed for any
            % other reason.
            %
            % input:
            %   iSegment:  [1x1]integer index of current segment

            for iBS = 1:obj.nBaseStations
                % attach new users to base station
                actUserassignmentDL = obj.userToBSassignment(:,iSegment) == iBS;
                obj.baseStations(iBS).attachedUsers = obj.users(actUserassignmentDL);
                
                switch obj.baseStations(iBS).antennaList.baseStationType
                    case parameters.setting.BaseStationType.macro
                        a3=obj.baseStations(iBS).attachedUsers;
                    case parameters.setting.BaseStationType.femto
                        b3=obj.baseStations(iBS).attachedUsers;
                end
                % update NOMA user pairs for this segment
                obj.baseStations(iBS).nomaPairs = obj.nomaUserPairing{iBS, iSegment};
            end
        end
        
        %by Nico Kabongo
        function updateUsersAttachedToBaseStationsInterfer(obj, iSegment, macroscopicFadingW)
            for iBS = 1:obj.nBaseStations
                % attach new users to base station
                %actUserassignmentDL = obj.userToBSassignment(:,iSegment) == iBS;
                %obj.baseStations(iBS).attachedUsers = obj.users(actUserassignmentDL);
                %obj.users;
                receivePower = [obj.antennas.transmitPower]' .* macroscopicFadingW;
                indColIntFinal = obj.getInterfence(receivePower);
                allUsersInterfer = obj.users;
                allUsersInterfer(indColIntFinal)=[];
                actUserassignmentInterferDL = obj.userToBSassignment(:,iSegment) == iBS;
                actUserassignmentInterferDL(indColIntFinal)=[];
                switch obj.baseStations(iBS).antennaList.baseStationType
                    case parameters.setting.BaseStationType.macro
                        actUserassignmentDL = obj.userToBSassignment(:,iSegment) == iBS;
                        obj.baseStations(iBS).attachedUsers = obj.users(actUserassignmentDL);
                        %a3=obj.baseStations(iBS).attachedUsers;
                    case parameters.setting.BaseStationType.femto
                        obj.baseStations(iBS).attachedUsers = allUsersInterfer(actUserassignmentInterferDL);
                        %b3=obj.baseStations(iBS).attachedUsers;
                end

                % update NOMA user pairs for this segment
                obj.baseStations(iBS).nomaPairs = obj.nomaUserPairing{iBS, iSegment};
            end
        end        
        %-----------

        function setNomaUserPairing(obj, cellAssociationMetric, iSegment)
            % pair users for NOMA transmission
            % This function looks for NOMA user pairs in each cell. Two
            % users are paired if the difference in their received powers
            % is larger than the minimum NOMA deltadB.
            %
            % input:
            %   cellAssociationMetric:	[1 x nUser]double value used for cell association for each user
            %                           can be SINR or received power
            %   iSegment:               [1x1]integer index of current segment
            %
            % set properties: nomaUserPairing
            %
            % see also parameters.Noma.deltaPairdB,
            % parameters.Noma.mustIdx, parameters.setting.MUSTIdx

            if obj.nomaMustIdx ~= parameters.setting.MUSTIdx.Idx00
                for iBS = 1:obj.nBaseStations
                    % get array indicating which users are attached to this base station
                    attachedUser = obj.userToBSassignment(:,iSegment) == iBS;
                    % get the cell association metric used for the users attached to this BS
                    metricAttachedUser = tools.todB(cellAssociationMetric(attachedUser));
                    % get number of users attached to this BS in this segment
                    nUser = length(metricAttachedUser);
                    % sort metrics
                    [powerSorted, indexSorted] = sort(metricAttachedUser);
                    % get difference in metric for possible user pairs
                    deltaPower = powerSorted(end:-1:(end-floor(nUser/2)+1)) - powerSorted(1:floor(nUser/2));
                    % find users with large enough delta
                    nomaUser = deltaPower > obj.nomaDeltadB;
                    % get full index array
                    nomaUserArray = [nomaUser false(1, ceil(nUser/2))];
                    % save the user pairs in obj.nomaUserPairing
                    obj.nomaUserPairing{iBS, iSegment} = [indexSorted(nomaUserArray); indexSorted(nomaUserArray(end:-1:1))];
                    % now we change the high power users to be in the correct order
                    if ~isempty(obj.nomaUserPairing{iBS, iSegment})
                        obj.nomaUserPairing{iBS, iSegment}(2,:) = obj.nomaUserPairing{iBS, iSegment}(2,end:-1:1);
                    end % if this BS has paired NOMA users
                end % for each base station
            end % if NOMA is used in this simulation
        end
    end
end

