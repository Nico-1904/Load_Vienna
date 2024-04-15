%% Simulator Launcher File
% simulates a heterogeneous scenario with different base station and user types
% Simulation scenario details are defined in +scenarios by handing the
% defined scenario and simulation type to simulate. After the simulation
% the simulation results can be displayed with the functions in
% simulation.results.
%
% initial author: Fjolla Ademaj
%
% see also scenarios.HetNet

% clear working space and close all figures
close all
clear
clc

% launch simulation
result = simulate(@scenarios.HetNet, parameters.setting.SimulationType.local);

%% display results
result.plotUserThroughputEcdf;
result.plotUserBler;
result.plotUserLiteSinrEcdf;
result.plotUserCellIdLoad;
% plot scenario
figure();
pNoma = [];
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
        case parameters.setting.BaseStationType.pico
            color = tools.myColors.matlabRed;
            pPicoBS = iBaseStation.antennaList.plot2D(1, color);
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
    % plot NOMA pairs
    if ~isempty(iBaseStation.nomaPairs)
        for iNomaPair = 1:size(iBaseStation.nomaPairs, 2)
            farUserPos1 = iBaseStation.attachedUsers(iBaseStation.nomaPairs(1, iNomaPair)).positionList(1,1);
            farUserPos2 = iBaseStation.attachedUsers(iBaseStation.nomaPairs(1, iNomaPair)).positionList(2,1);
            nearUserPos1 = iBaseStation.attachedUsers(iBaseStation.nomaPairs(2, iNomaPair)).positionList(1,1);
            nearUserPos2 = iBaseStation.attachedUsers(iBaseStation.nomaPairs(2, iNomaPair)).positionList(2,1);
            pNoma = plot([farUserPos1, nearUserPos1], [farUserPos2, nearUserPos2],  'Color', tools.myColors.gray);
        end
    end
end
% plot users by user type
pedestrianUser = [result.params.userParameters('clusterUser').indices, result.params.userParameters('poissonUserPedestrian').indices];
vehicularUser = [result.params.userParameters('poissonUserCar').indices, result.params.userParameters('vehicle').indices];
for iUser = pedestrianUser
    pPed = result.networkResults.userList(iUser).plot2D(1, tools.myColors.matlabLightBlue);
end
for iUser = vehicularUser
    pVeh = result.networkResults.userList(iUser).plot2D(1, tools.myColors.matlabBlue);
end
legend([pMacroBS, pPicoBS, pFemtoBS, pVeh, pPed, pNoma], ...
    {'macro BS', 'pico BS', 'femto BS', 'vehicular user', 'pedestrian user', 'NOMA pair'});
title('Simulation Scenario');
set(gca,'fontsize', 12);
xlim([result.params.regionOfInterest.xMin, result.params.regionOfInterest.xMax]);
ylim([result.params.regionOfInterest.yMin, result.params.regionOfInterest.yMax]);
xlabel('x position in m');
ylabel('y position in m');

