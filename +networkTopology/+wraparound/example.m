%% Example for creating a simple 5G NR 3D network topology
clc; close all; clear;
rng('shuffle')

%% Example of topology parameters
ROI        = [2000, 2000];  % Width of ROI (m)
numCells   = 7;             % Number of cells
cellRadius = 500;           % Cell radius (m)
gNBHeight  = 30;            % Height of gNB antenna
ueDensity  = 5e-3;          % UE density per km^2
maxUEs     = 20;            % Maxium UE number per cell
[distances,azimuths] = topology.generateTopology(ROI,numCells,cellRadius,gNBHeight,ueDensity,maxUEs);
