%% Simulator Launcher File
% launches open street map scenario with dynamic spectrumm sharing and 1024-QAM
% Simulation scenario details are defined in +scenarios by handing the
% defined scenario and simulation type to simulate. After the simulation
% the simulation results can be displayed with the functions in
% simulation.results.
%
% initial author: Christoph Buchner
%
% see also scenarios.openStreetMapScenario

% clear working space and close all figures
close all
clear
clc

% launch simulation
result = simulate(@scenarios.openStreetMap, parameters.setting.SimulationType.local);

%% display results
result.showAllPlots;

% show user technologies and cell association  
figure(1);
hold on;
for iBaseStation = result.networkResults.baseStationList
    for iAntenna = iBaseStation.antennaList
        posAnt =  iAntenna.positionList(:,1);
        for iUser = iBaseStation.attachedUsers
            posUe = iUser.positionList(:,1);
            if iUser.technology == parameters.setting.NetworkElementTechnology.LTE
                pLTE = iUser.plot(1, tools.myColors.matlabBlue);
                hold on;
            else
                p5G = iUser.plot(1, tools.myColors.matlabGreen);
                hold on;
            end
            plot3([posUe(1),posAnt(1)],[posUe(2),posAnt(2)],[posUe(3),posAnt(3)], 'Color', tools.myColors.lightGray);
        end
    end
end

legend([pLTE, p5G], {'LTE user', '5G user'});
xlim([result.params.regionOfInterest.xMin, result.params.regionOfInterest.xMax]);
ylim([result.params.regionOfInterest.yMin, result.params.regionOfInterest.yMax]);
xlabel('x position in m');
ylabel('y position in m');
zlabel('height in m');

% plot throughput by numerology/technology
numerologies = unique([result.networkResults.userList.numerology]);
f = figure("Name", "Throughput");
set(f,'Position', [50 50 1000 500]);
p1 = subplot(1,2,1);
hold on;
title('user throughput');
xlabel('throughput (Mbit/s)');
ylabel('ECDF');
grid on;
p2 = subplot(1,2,2);
hold on;
title('best CQI user throughput');
xlabel('throughput (Mbit/s)');
ylabel('ECDF');
grid on;
for num = numerologies
    userMask = [result.networkResults.userList.numerology] == num;
    dl = result.userThroughputMBitPerSec.DL(userMask, :);
    dlBestCqi = result.userThroughputMBitPerSec.DLBestCQI(userMask, :);
    axes(p1);
    tools.myEcdf(mean(dl,2,'omitnan'));
    axes(p2);
    tools.myEcdf(mean(dlBestCqi,2,'omitnan'));
end
plotLegend = "Numerology " + numerologies;
legend(plotLegend);
axes(p1);
legend(plotLegend);

