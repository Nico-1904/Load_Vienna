%% Simulator Launcher File
% launches a simulation and displays results
% This is the example function for how to use the 5G systemlevel simulator.
% Launches the simulation defined in +scenarios by handing the defined
% scenario and simulation type to simulate. After the simulation the
% simulation results can be displayed with the functions in
% simulation.results or by creating customized plots for the scenario.
%
% see also scenarios.basicScenario, simulate, scenarios.example
% parameters.setting.SimulationType, scenarios, simulation.results

% clear working space and close all figures
close all
clear
clc

% launch a local simulation with the scenario defined in scenarios.basicScenario
% To launch a parallel simulation, change the second input to
% parameters.setting.SimulationType.parallel.
result = simulate(@scenarios.basicScenario, parameters.setting.SimulationType.local);

%% display results

% plot SINR and throughput
result.plotUserLiteSinrEcdf;
result.plotUserThroughputEcdf;

% plot ROI and building
figure();
result.networkResults.buildingList.plotFloorPlan2D(tools.myColors.darkGray);
result.params.regionOfInterest.plotRoiBorder(tools.myColors.darkGray);
baseStations = result.networkResults.baseStationList;
% plot base stations and show attached users
for iBS = 1:size(baseStations,2)
    % plot base station
    antHandle = baseStations(iBS).antennaList.plot2D(1, tools.myColors.matlabRed);
    hold on;
    % plot line to attached user
    posAnt   =  baseStations(iBS).antennaList.positionList(:,1);
    for iUser = baseStations(iBS).attachedUsers
        posUe = iUser.positionList(:,1);
        % plot first user position in green
        handleFirst = iUser.plot2D(1, tools.myColors.matlabGreen);
        hold on;
        plot([posUe(1),posAnt(1)],[posUe(2),posAnt(2)],'Color', tools.myColors.lightGray);
        hold on;
    end
end

% display movement of one user of each movement type
userKeys = result.params.userParameters.keys;
nUsersToPlot = length(userKeys);
for uu = 1:nUsersToPlot
    userIndex = result.params.userParameters(userKeys{uu}).indices(1);
    posList = result.networkResults.userList(userIndex).positionList;
    posHandle = plot(posList(1,:), posList(2,:), 'b+');
    % draw arrow from start to finish
    dirHandle = quiver(posList(1,1), posList(2,1), posList(1,end)-posList(1,1), posList(2, end)-posList(2, 1), 0, 'r');
    % plot path for the first user
    pathHandle = plot(posList(1,:), posList(2,:), 'k-');
    hold on;
end
title('Simulation Scenario');
legend([antHandle, posHandle, dirHandle, pathHandle], {'base station', 'user position', 'movement direction', 'path'});

