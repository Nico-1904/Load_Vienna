%% Simulator Launcher File
% launches Manhattan sceanrio with antenna arrays, quadriga channel model and HARQ
% Simulation scenario details are defined in +scenarios by handing the
% defined scenario and simulation type to simulate. After the simulation
% the simulation results can be displayed with the functions in
% simulation.results.
%
% initial author: Fjolla Ademaj
%
% see also scenarios.ManhattanQuadriga

% clear working space and close all figures
close all
clear
clc

% launch simulation
result = simulate(@scenarios.ManhattanQuadriga, parameters.setting.SimulationType.local);

%% display results
result.showAllPlots;

% plot LOS connection
figure(1);
antennas        = [result.networkResults.baseStationList.antennaList];
[iiAnt, iiUe]   = find(~result.additional.losMap);
indoorDecision  = result.additional.isIndoor(:,1);
for iUe = 1:length(result.networkResults.userList)
    if any(iUe==iiUe)
        for iAnt = unique(iiAnt(iUe==iiUe)')
            actAnt = antennas(iAnt).positionList(:,end);
            actUe = result.networkResults.userList(iUe).positionList(:,end);
            pLOS = plot3([actAnt(1),actUe(1)],[actAnt(2),actUe(2)],[actAnt(3),actUe(3)],'Color',tools.myColors.matlabOrange);
        end
    end
    % plot user with indoor color coding
    if indoorDecision(iUe)
        pIndoor = result.networkResults.userList(iUe).plot(1, tools.myColors.matlabGreen);
        hold on;
    else
        pOutdoor = result.networkResults.userList(iUe).plot(1, tools.myColors.matlabPurple);
        hold on;
    end
end
xlabel('x position in m');
ylabel('y position in m');
zlabel('height in m');
title('Simulation Scenario');
legend([pIndoor, pOutdoor, pLOS], {'indoor user', 'outdoor user', 'LOS connection'});

