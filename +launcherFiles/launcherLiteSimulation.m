%% Simulator Launcher File
% run a lite simulation where no scheduling is performed
% Simulation scenario details are defined in +scenarios by
% handing the defined scenario and simulation type to simulate. After the
% simulation the simulation results can be displayed with the functions in
% simulation.results.
%
% initial author: Blanca Ramos Elbal
%
% see also scenarios.basicLiteScenario

% clear working space and close all figures
close all
clear
clc

% launch local simulation defined scenarios.basicLiteScenario
result = simulate(@scenarios.basicLiteScenario, parameters.setting.SimulationType.local);

% display results
result.plotUserLiteSinrEcdf;
result.plotUserWidebandSinr;
result.plotScene(1);
result.params.regionOfInterest.plotRoiBorder(tools.myColors.lightGray);

