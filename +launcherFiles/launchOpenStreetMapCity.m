%% Simulator Launcher File
% launches the open street map city scenario

%%
clc; close all; clear;

%% Flag to set up parallel simulation
% If set to 'true', the simulation will be run in parallel mode, which can improve 
% the efficiency of the computation when multiple processors are available.
enableParallelSim = false;
% flag = 1;

% Invoke the simulator
results = simulate(@scenarios.openStreetMapCity, enableParallelSim);

% restore data
%restoredata(results, flag)
