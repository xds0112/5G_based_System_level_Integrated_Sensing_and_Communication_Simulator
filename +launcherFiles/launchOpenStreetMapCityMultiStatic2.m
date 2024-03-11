%% Simulator Launcher File
% launches the open street map city scenario

%%
clc; close all; clear;

%% Flag to set up parallel simulation
% If set to 'true', the simulation will be run in parallel mode, which can
% speed up the simulation when multiple processors are available.
enableParallelSim = false;

% Invoke the simulator
results = simulate(@scenarios.openStreetMapCityMultiStatic2, enableParallelSim);