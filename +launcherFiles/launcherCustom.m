%% Simulator Launcher File
close all
clear
clc

% launch simulation
result = simulate(@scenarios.Custom, parameters.setting.SimulationType.local);

%% display results
%result.plotUserThroughputEcdf; 
result.plotUserThroughput1Ecdf;
%result.plotUserBler;
%result.plotUserLiteSinrEcdf;
%result.plotUserWidebandSinr;
%result.plotUserEffectiveSinrEcdf;
%result.plotUserLoadCell;
%result.plotUserDebit;
% plot scenario
figure();
%pNoma = [];
for iBaseStation = result.networkResults.baseStationList
    antPos1 = iBaseStation.antennaList.positionList(1);
    antPos2 = iBaseStation.antennaList.positionList(2);
    hold on;
    % plot base stations and attached users by base station type
    switch iBaseStation.antennaList.baseStationType
        case parameters.setting.BaseStationType.macro
            color = tools.myColors.matlabPurple;
            pMacroBS = iBaseStation.antennaList.plot2D(1, color);
            for iUser = iBaseStation.attachedUsers
                plot([iUser.positionList(1, 1), antPos1], [iUser.positionList(2, 1), antPos2],  'Color', color);
            end
        case parameters.setting.BaseStationType.femto
            color = tools.myColors.matlabOrange;
            pFemtoBS = iBaseStation.antennaList.plot2D(1, color);
            for iUser = iBaseStation.attachedUsers
                plot([iUser.positionList(1, 1), antPos1], [iUser.positionList(2, 1), antPos2],  'Color', color);
            end
        otherwise
            disp('This should not happen.');
    end
    
end
%Compute the load for each BS

%load_BS = result.LoadCell;
% load_BS = 1500 ./ (100 * 180 * log2(1 + tools.dBto(result.widebandSinrdB)));
%FinalLoad = sum(load_BS, 2);   
            
% plot users by user type
%result.params.userParameters('clusterUser').indices, 

% pedestrianUser = [result.params.userParameters('poissonUserPedestrian').indices];
% noServedUser = [result.params.userParameters('poissonUserNoServed').indices];

userFixed = [result.params.userParameters('poissonUserFixed').indices];
%vehicularUser = [result.params.userParameters('poissonUserCar').indices, result.params.userParameters('vehicle').indices];
%--------------
%  for iUser = pedestrianUser
%      pPed = result.networkResults.userList(iUser).plot2D(1, tools.myColors.matlabLightBlue);
%  end
%  for iUser = noServedUser
%      pNoSer = result.networkResults.userList(iUser).plot2D(1, tools.myColors.black);
%  end
  for iUser = userFixed
     pFix = result.networkResults.userList(iUser).plot2D(1, tools.myColors.black);
 end
%-------------------------
%for iUser = vehicularUser
 %   pVeh = result.networkResults.userList(iUser).plot2D(1, tools.myColors.matlabBlue);
%end
% legend([pMacroBS, pFemtoBS, pPed, pNoSer], ...
%     {'macro BS', 'femto BS', 'pedestrian user', 'other user'}, 'Location', 'northEastOutside');


legend([pMacroBS, pFemtoBS, pFix], ...
    {'macro BS', 'femto BS', 'userFixed'}, 'Location', 'northEastOutside');
title('Simulation Scenario');
set(gca,'fontsize', 12);
xlim([result.params.regionOfInterest.xMin, result.params.regionOfInterest.xMax]);
ylim([result.params.regionOfInterest.yMin, result.params.regionOfInterest.yMax]);
xlabel('x position in m');
ylabel('y position in m');

% %New plot
% figure()
% dl= result.LoadCell;
% tools.myEcdf(mean(dl,2,'omitnan'));

%plot new load
%   Id = zeros(1, length(FinalLoad));
%   for ip = 1:length(FinalLoad)
%   Id(ip) = result.networkResults.baseStationList(1,ip).antennaList.id;
%   end
%   xId = Id';
%   figure()
%   bar(xId, FinalLoad);
%   xlabel('ID Cell');
%   ylabel('Load');
%   title('Load cell (by Nico KABONGO)');


% figure()
% for iBaseStationPlot = result.networkResults.baseStationList
%     hold on
%     switch iBaseStationPlot.antennaList.baseStationType
%         case parameters.setting.BaseStationType.macro
%             load_BS = 1500 ./ (100 * 180 * log2(1 + tools.dBto(result.widebandSinrdB)));
%                 sumLoad =[];
%                 l=[];
%                 e=[];
%                 f=[];
%                 for i=[iBaseStationPlot.attachedUsers.id]
%                     l=[l,i];
%                     if length(l) == length([iBaseStationPlot.attachedUsers.id])    
%                       e=[e,l];
%                       k=iBaseStationPlot.antennaList.id;
%                       VectorAttach=load_BS(e);
%                       sumLoad=sum(VectorAttach);
%                       bar(k,sumLoad);
%                       hold on
%                     else
%                     end
%                 end   
%         case parameters.setting.BaseStationType.femto  
%             load_BS = 1500 ./ (100 * 180 * log2(1 + tools.dBto(result.widebandSinrdB)));
%             
%             VectorAttachFe = [];
%             sumLoadFe =[];
%                 lFe=[];
%                 eFe=[];
%                 fFe=[];
%                 for i=[iBaseStationPlot.attachedUsers.id]
%                     lFe=[lFe,i];
%                     if length(lFe) == length([iBaseStationPlot.attachedUsers.id])    
%                       eFe=[eFe,lFe];
%                       kFe=iBaseStationPlot.antennaList.id;
%                       VectorAttachFe=load_BS(eFe);
%                       sumLoadFe=sum(VectorAttachFe);
%                       bar(kFe,sumLoadFe);
%                       hold on
%                     else
%                     end
%                 end 
%             
%         otherwise
%             disp('This should not happen.');
%     end
% end

