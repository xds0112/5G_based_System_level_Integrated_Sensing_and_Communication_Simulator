function cellSimuParams = assignCellSimulationParameters(time, bsParams, ...
    schedulingParams, trafficParams, pathlossParams, comChannelParams, log)
%ASSIGNCELLPARAMETERS assign simulation parameters for a single cell
% Input:
% time: simulation time pararmeters
%
% bsParams: base station pararmeters
%
% ueParams：UEs pararmeters
%
% targetParams: target pararmeters
%
% schedulingParams：scheduling pararmeters
%
% trafficParams: application traffic pararmeters
%
% pathlossParams: Pathloss model pararmeters
%
% comChannelParams: CDL channel models pararmeters
%
% log: Logging and visualization pararmeters 
%
% Output:
% cellSimuParams: cell simulation pararmeters 

    % Initialize cell simulation parameters
    cellSimuParams = struct;

    % Base station pararmeters re-assignment
    cellSimuParams.cellID          = bsParams.cellID; 
    cellSimuParams.duplexMode      = bsParams.duplexMode; 
    cellSimuParams.schedulingType  = bsParams.schedulingType;
    cellSimuParams.dlCarrierFreq   = bsParams.dlCarrierFreq;
    cellSimuParams.ulCarrierFreq   = bsParams.ulCarrierFreq;  
    cellSimuParams.dlBandwidth     = bsParams.dlBandwidth; 
    cellSimuParams.ulBandwidth     = bsParams.ulBandwidth;  
    cellSimuParams.scs             = bsParams.scs;     
    cellSimuParams.numRBs          = bsParams.numRBs;
    cellSimuParams.tddPattern      = bsParams.tddPattern;
    cellSimuParams.specialSlot     = bsParams.tddSpecialSlot;
    cellSimuParams.numDLSlots      = bsParams.tddConfig.numDLSlots;
    cellSimuParams.numULSlots      = bsParams.tddConfig.numULSlots;
    cellSimuParams.numDLSyms       = bsParams.tddConfig.numDLSyms;
    cellSimuParams.numULSyms       = bsParams.tddConfig.numULSyms;
    cellSimuParams.dlulPeriodicity = bsParams.tddConfig.dlulPeriodicity;
    cellSimuParams.gNBPosition     = bsParams.position;
    cellSimuParams.gNBTxAnts       = bsParams.txAntenna.numElements;
    cellSimuParams.gNBRxAnts       = bsParams.rxAntenna.numElements;
    cellSimuParams.gNBTxPanel      = bsParams.txAntenna.arrayGeometry;
    cellSimuParams.gNBRxPanel      = bsParams.rxAntenna.arrayGeometry;
    cellSimuParams.gNBTxPower      = bsParams.txPower;
    cellSimuParams.gNBRxGain       = bsParams.rxGain;
    cellSimuParams.gNBNoiseFigure  = bsParams.noiseFigure;
    cellSimuParams.gNBTemperature  = bsParams.antTemperature;
    cellSimuParams.gNBSenAntenna   = bsParams.txAntenna;
    cellSimuParams.detectionArea   = bsParams.sensing.detectionArea;
    cellSimuParams.Pfa             = bsParams.sensing.Pfa;
    cellSimuParams.estAlgorithm    = bsParams.sensing.estAlgorithm; 
    cellSimuParams.detectionfre    = bsParams.sensing.detectionfre;
    
    % UEs pararmeters re-assignment
    ueParams                  = bsParams.attachedUEs;
    cellSimuParams.numUEs     = ueParams.numUEs;
    cellSimuParams.uePosition = ueParams.position;
    cellSimuParams.ueTxAnts   = ueParams.numAnts * ones(ueParams.numUEs, 1);
    cellSimuParams.ueRxAnts   = ueParams.numAnts * ones(ueParams.numUEs, 1);
    cellSimuParams.ueAntPanel = ueParams.ueAntenna;
    cellSimuParams.ueTxPower  = ueParams.txPower;

    % Target parameters re-assignment
    targetParams                  = bsParams.attachedTargets;
    cellSimuParams.numTargets     = [];
    cellSimuParams.targetPosition = [];
    cellSimuParams.rcs            = [];
    cellSimuParams.velocity       = [];
    for i = 1:length(targetParams)
        cellSimuParams.numTargets     = cat(1, cellSimuParams.numTargets, targetParams(i).numTargets);
        cellSimuParams.targetPosition = cat(1, cellSimuParams.targetPosition, targetParams(i).position);
        cellSimuParams.rcs            = cat(1, cellSimuParams.rcs, targetParams(i).rcs);
        cellSimuParams.velocity       = cat(1, cellSimuParams.velocity, targetParams(1).velocity);
    end
    % Time pararmeters re-assignment
    cellSimuParams.numFrames = time.numFrames;
    cellSimuParams.numSlots  = time.numFrames * bsParams.numSlotsFrame;

    % Scheduling pararmeters re-assignment
    cellSimuParams.schedulerStrategy   = schedulingParams.schedulerStrategy;
    cellSimuParams.ttiGranularity      = schedulingParams.ttiGranularity;
    cellSimuParams.rbAllocationLimitUL = schedulingParams.rbAllocationLimitUL;
    cellSimuParams.rbAllocationLimitDL = schedulingParams.rbAllocationLimitUL;
    
    % Application traffic pararmeters re-assignment
    cellSimuParams.trafficModel  = trafficParams.trafficModel;
    cellSimuParams.dlAppDataRate = trafficParams.dlAppDataRate * ones(ueParams.numUEs, 1); 
    cellSimuParams.ulAppDataRate = trafficParams.ulAppDataRate * ones(ueParams.numUEs, 1);
    
    % Pathloss model pararmeters re-assignment
    cellSimuParams.pathLossModel = pathlossParams.pathLossModel;

    % CDL channel models pararmeters re-assignment
    cellSimuParams.comChannelModel.channelModelUL = comChannelParams.channelModelUL;
    cellSimuParams.comChannelModel.channelModelDL = comChannelParams.channelModelDL;

    % Logging and visualization pararmeters re-assignment
    cellSimuParams.enableTraces     = log.enableTraces; 
    cellSimuParams.cqiVisualization = log.cqiVisualization;
    cellSimuParams.rbVisualization  = log.rbVisualization;
end

