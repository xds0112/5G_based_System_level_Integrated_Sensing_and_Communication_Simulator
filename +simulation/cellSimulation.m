function [comResults, senResults] = cellSimulation(cellSimuParams)
%CELLSIMULATION
%   Integrated sensing and communication simulation within a single cell

    %% Pre-processing
    % Specify the signal-to-interference-plus-noise ratio (SINR) to a CQI index
    % mapping table for a block error rate (BLER) of 0.1
    cellSimuParams = communication.setupSINRtoCQIMappingTable(cellSimuParams);
    % Configure the SRS and CSI-RS
    [cellSimuParams.srsSubbandSize, cellSimuParams.srsConfig] = communication.setupSRS(cellSimuParams.numRBs, cellSimuParams.numUEs);
    [cellSimuParams.csirsConfig, cellSimuParams.csiReportConfig] = communication.setupCSIRS(cellSimuParams.numRBs);

    % Set the UL rank to be used for precoding matrix and MCS calculation.
    % For each UE, set a number less than or equal to the minimum of UE's
    % transmit antennas and gNB's receive antennas.
    cellSimuParams.ulRankIndicator = 2*ones(1,cellSimuParams.numUEs);

    %% Validate parameters
    communication.validateParameters(cellSimuParams);

    %% Configurate RLC channel
    [~, rlcChannelConfig, cellSimuParams] = communication.setRLCChannelConfig(cellSimuParams);
    
    %% Configurate scheduling type
    % Set the mapping type as per the configured scheduling type.   
    if ~isfield(cellSimuParams, 'schedulingType') || (cellSimuParams.schedulingType == 0)
        % If no scheduling type is specified or slot based scheduling is specified
        [cellSimuParams.PUSCHMappingType, cellSimuParams.PDSCHMappingType] = deal('A');
    elseif cellSimuParams.schedulingType == 1 % Symbol based scheduling
        [cellSimuParams.PUSCHMappingType, cellSimuParams.PDSCHMappingType] = deal('B');
    else
        error('The scheduling type must be set to 0(''slot based'') or 1(''symbol based'').')
    end
    
    %% Channel models
    comChannel = cellSimuParams.comChannelModel;
    
    %% Simulation Scenario and Network Nodes Setup
    % Create the gNB and UE objects, initialize the channel quality information
    % for UEs, and set up the logical channsl at the gNB and UE.
    % The classes <networkNodes.gNB> and <networkNodes.ue> create the
    % gNB node and the UE node, respectively, each containing the RLC, MAC and PHY.

    gNB = networkNodes.gNB(cellSimuParams); % Create gNB node

    % Create scheduler
    switch(cellSimuParams.schedulerStrategy)
        case 'RR'      % Round robin scheduler
            scheduler = communication.scheduling.roundRobin(cellSimuParams);
        case 'PF'      % Proportional fair scheduler
            scheduler = communication.scheduling.proportionalFair(cellSimuParams);
        case 'BestCQI' % Best CQI scheduler
            scheduler = communication.scheduling.bestCQI(cellSimuParams);
    end

    addScheduler(gNB, scheduler);                                  % Add scheduler to gNB
    cellSimuParams.channelModel = comChannel.channelModelUL;
    gNB.PhyEntity = communication.phyLayer.gNBPhy(cellSimuParams); % Create the PHY instance
    configurePhy(gNB, cellSimuParams);                             % Configure the PHY
    setPhyInterface(gNB);                                          % Set the interface to PHY
    
    % Create the set of UE nodes
    UEs     = cell(cellSimuParams.numUEs, 1);
    ueParam = cellSimuParams;

    for ueIdx = 1:cellSimuParams.numUEs
        ueParam.uePosition      = cellSimuParams.uePosition(ueIdx, :); % Position of the UE
        ueParam.ueRxAnts        = cellSimuParams.ueRxAnts(ueIdx);
        ueParam.ueTxAnts        = cellSimuParams.ueTxAnts(ueIdx);
        ueParam.srsConfig       = cellSimuParams.srsConfig{ueIdx};
        ueParam.csiReportConfig = cellSimuParams.csiReportConfig{1}; % Assuming same CSI Report configuration for all UEs
        ueParam.channelModel    = comChannel.channelModelDL{ueIdx};
        UEs{ueIdx}              = networkNodes.ue(ueParam, ueIdx);
        UEs{ueIdx}.PhyEntity    = communication.phyLayer.uePhy(ueParam, ueIdx); % Create the PHY instance
        configurePhy(UEs{ueIdx}, ueParam); % Configure the PHY
        setPhyInterface(UEs{ueIdx});       % Set up the interface to PHY
    
        % Set up logical channel at gNB for the UE
        configureLogicalChannel(gNB, ueIdx, rlcChannelConfig);
        % Set up logical channel at UE
        configureLogicalChannel(UEs{ueIdx}, ueIdx, rlcChannelConfig);
    
        % Set up application traffic
        [dlApp,ulApp] = communication.appLayer.setTrafficModel(cellSimuParams, ueIdx);
        addApplication(gNB, ueIdx, cellSimuParams.lchConfig.LCID, dlApp);
        addApplication(UEs{ueIdx}, ueIdx, cellSimuParams.lchConfig.LCID, ulApp);
    end

    % Update CDL channel models based on the LoS conditions
    updatedDelayProfile = communication.channelModels.updateCDLModels(cellSimuParams);
    for ueIdx = 1:cellSimuParams.numUEs
        gNB.PhyEntity.LoSConditions(ueIdx) = cellSimuParams.ueLoSConditions(ueIdx);
        UEs{ueIdx}.PhyEntity.LoSCondition  = cellSimuParams.ueLoSConditions(ueIdx);
        [gNB.PhyEntity.ChannelModel{ueIdx}.DelayProfile, UEs{ueIdx}.PhyEntity.ChannelModel.DelayProfile] = deal(updatedDelayProfile{ueIdx});
    end

    % Set up the packet distribution mechanism.   
    cellSimuParams.maxReceivers = cellSimuParams.numUEs + 1; % Number of nodes
    % Create packet distribution object
    packetDistributionObj = communication.appLayer.packetDistribution(cellSimuParams);
    communication.appLayer.setUpPacketDistribution(cellSimuParams, gNB, UEs, packetDistributionObj);
    
    %% Processing Loop
    % Run the simulation symbol by symbol to execute these operations.
    % * Run the gNB.
    % * Run the UEs.
    % * Log and visualize metrics for each layer.
    % * Advance the timer for the nodes and send a trigger to application and RLC
    % layers every millisecond. The application and RLC layers execute their scheduled
    % operations based on a 1 ms timer trigger.

    % Create objects to log and visualize MAC traces and PHY traces.
    % Updates the metrics plots periodically. Set the number of updates
    % during the simulation. 
    cellSimuParams.numMetricsSteps = 10;

    % Set the interval at which the example updates metrics visualization in terms
    % of number of slots. Because this example uses a time granularity of one slot,
    % the |MetricsStepSize| field must be an integer.   
    cellSimuParams.metricsStepSize = ceil(cellSimuParams.numSlots / cellSimuParams.numMetricsSteps);
    if mod(cellSimuParams.numSlots, cellSimuParams.numMetricsSteps) ~= 0
        % Update the NumMetricsSteps parameter if NumSlotsSim is not completely divisible by it
        cellSimuParams.numMetricsSteps = floor(cellSimuParams.numSlots / cellSimuParams.metricsStepSize);
    end
    
    if cellSimuParams.enableTraces
        % Create an object for MAC traces logging
        simSchedulingLogger = communication.scheduling.schedulingLogger(cellSimuParams);
        % Create an object for PHY traces logging
        simPhyLogger = communication.phyLayer.phyLogger(cellSimuParams);
        % Create an object for CQI and RB grid visualization
        if cellSimuParams.cqiVisualization || cellSimuParams.rbVisualization
            gridVisualizer = visualizationTools.gridVisualizer(cellSimuParams, 'MACLogger', simSchedulingLogger);
        end
    end
    
    % Create an object for MAC and PHY metrics visualization.
    nodes = struct('UEs', {UEs}, 'GNB', gNB);
    metricsVisualizer = visualizationTools.metricsVisualizer(cellSimuParams, 'Nodes', nodes, ...
        'EnableSchedulerMetricsPlots', true, 'EnablePhyMetricsPlots', true);

    % Initialize sensing variables
    % Radar Tx symbols in all slots combined
    radarTxGrid = [];
    % Radar estimation parameters
    carrierInfo = gNB.PhyEntity.CarrierInformation;
    waveInfoDL  = gNB.PhyEntity.WaveformInfoDL;
    radarParams = sensing.radarParams(cellSimuParams, carrierInfo, waveInfoDL);
    cfarConfig  = sensing.detection.cfar2D(radarParams);

    % Run the processing loop (assuming normal cyclic prefix)  
    slotNum = 0;
    symPerSlot = waveInfoDL.SymbolsPerSlot;
    numSymbols = cellSimuParams.numSlots*symPerSlot; % Simulation time in units of symbol duration
    tickGranularity = symPerSlot; % Set to 1 to execute all the symbols in the simulation (not recommanded)

    for symbolNum = 1 : tickGranularity : numSymbols    
        if mod(symbolNum - 1, symPerSlot) == 0
            slotNum = slotNum + 1;
        end

        % Run the gNB
        run(gNB);
        
        % Run the UEs
        for ueIdx = 1:cellSimuParams.numUEs 
            run(UEs{ueIdx});
        end

        % Sensing signal processing
        % Determine the current slot type
        currentSlot = gNB.PhyEntity.CurrSlot;
        slotType = communication.determineSlotType(cellSimuParams.tddPattern, cellSimuParams.specialSlot, currentSlot);
        if strcmp(slotType, 'D')
            % PDSCH grid in the current slot
            txGrid = gNB.PhyEntity.txGrid;
            % Accumulate PDSCH symbols
            radarTxGrid = cat(2, radarTxGrid, txGrid);
        end
        
        if cellSimuParams.enableTraces
            % MAC logging
            logCellSchedulingStats(simSchedulingLogger, symbolNum, gNB, UEs);
            % PHY logging
            logCellPhyStats(simPhyLogger, symbolNum, gNB, UEs);
        end
        
        % Visualization    
        % Check slot boundary
        if symbolNum > 1 && ((cellSimuParams.schedulingType == 1 && mod(symbolNum, symPerSlot) == 0) || (cellSimuParams.schedulingType == 0 && mod(symbolNum-1, symPerSlot) == 0))
            % If the update periodicity is reached, plot scheduler metrics and PHY metrics at slot boundary
            if mod(slotNum, cellSimuParams.metricsStepSize) == 0
                plotLiveMetrics(metricsVisualizer);
            end
        end
        
        % Advance timer ticks for gNB and UEs
        advanceTimer(gNB, tickGranularity);
        for ueIdx = 1:cellSimuParams.numUEs
            advanceTimer(UEs{ueIdx}, tickGranularity);
        end
    end
    
    %% Communicaiton simulation visualization and Logs
    % For logging the simulation parameters
    parametersFileName = strcat('simulationParams', '_cell_', num2str(cellSimuParams.cellID));
    parametersLogFile  = strcat('dataFiles/', parametersFileName);
    % For logging the simulation traces
    logsFileName      = strcat('simulationLogs', '_cell_', num2str(cellSimuParams.cellID));
    simulationLogFile = strcat('dataFiles/', logsFileName);
    % For logging the simulation metrics
    metricsFileName       = strcat('simulationMetrics', '_cell_', num2str(cellSimuParams.cellID)); 
    simulationMetricsFile = strcat('dataFiles/', metricsFileName);

    % Get the simulation metrics and save it in a MAT-file. The simulation metrics 
    % are saved in a MAT-file with the file name as |simulationMetricsFile|.
    metrics = getMetrics(metricsVisualizer);
    save(simulationMetricsFile, 'metrics');
    
    % Performance indicators displayed are achieved data rate (UL and DL),
    % achieved spectral efficiency (UL and DL), and BLER observed for UEs (DL and UL). 
    % The peak values are calculated as per 3GPP TR 37.910. 
    % The number of layers used for the peak DL and UL data rate calculation is taken 
    % as the average value of the maximum layers possible for each UE in the respective 
    % direction. The maximum number of DL layers possible for a UE is minimum of its Rx 
    % antennas and gNB's Tx antennas. Similarly, the maximum number of UL layers possible
    % for a UE is minimum of its Tx antennas and gNB's Rx antennas.
    comResults = savePerformanceIndicators(metricsVisualizer);

    % Plot ECDF of performance indicators
    plotPerformanceIndicatorsECDF(metricsVisualizer);
    
    % The five types of run-time visualization shown are:
    %
    % * _Display of CQI values for UEs over the PUSCH or PDSCH bandwidth.
    % * _Display of resource grid assignment to UEs.
    % * _Display of UL scheduling metrics plots.
    % * _Display of DL scheduling metrics plots.
    % * _Display of DL and UL Block Error Rates: The two sub-plots displayed in 
    % 'Block Error Rate (BLER) Visualization' shows the block error rate (for each 
    % UE) observed in the uplink and downlink directions, as the simulation progresses. 
    % The plot is updated every |metricsStepSize| slots. 
    %
    % Simulation Logs
    % The parameters used for simulation and the simulation logs are saved in MAT-files 
    % for post-simulation analysis and visualization. The simulation parameters are 
    % saved in a MAT-file with the file name as the value of configuration parameter 
    % |parametersLogFile|. The per time step logs, scheduling assignment logs, and 
    % BLER logs are saved in the MAT-file |simulationLogFile|. After the simulation, 
    % open the file to load |DLTimeStepLogs|, |ULTimeStepLogs|, |SchedulingAssignmentLogs|, 
    % |BLERLogs| in the workspace.
    % 
    % *Time step logs*: Both the DL and UL time step logs follow the same format.
    % 
    % *Scheduling assignment logs*: Information of all the scheduling assignments 
    % and related information is logged in this file. 
    % 
    % *BLER logs*: Block error information observed in the DL and UL direction. 

    if cellSimuParams.enableTraces
        simulationLogs = cell(1,1);
        if cellSimuParams.duplexMode == 0 % FDD
            logInfo = struct('DLTimeStepLogs', [], 'ULTimeStepLogs', [], 'SchedulingAssignmentLogs', [], 'BLERLogs', [], 'AvgBLERLogs', []);
            [logInfo.DLTimeStepLogs, logInfo.ULTimeStepLogs] = getSchedulingLogs(simSchedulingLogger);
        else % TDD
            logInfo = struct('TimeStepLogs', [], 'SchedulingAssignmentLogs', [], 'BLERLogs', [], 'AvgBLERLogs', []);
            logInfo.TimeStepLogs = getSchedulingLogs(simSchedulingLogger);
        end
        [logInfo.BLERLogs, logInfo.AvgBLERLogs] = getBLERLogs(simPhyLogger);  % BLER logs
        logInfo.SchedulingAssignmentLogs = getGrantLogs(simSchedulingLogger); % Scheduling assignments log
        simulationLogs{1} = logInfo;
        save(parametersLogFile, 'cellSimuParams'); % Save simulation parameters in a MAT-file
        save(simulationLogFile, 'simulationLogs'); % Save simulation logs in a MAT-file
    end

    % Run the script <postSimVisualization> to get a post communication simulation visualization of logs.

    %% Radar mono-static sensing and the corresponding results
    senResults = NaN;
%     radarRxGrid = sensing.monoStaticSensing(radarTxGrid, carrierInfo, waveInfoDL, radarParams);
%     senResults  = sensing.estimation.fft2D(radarParams, cfarConfig, radarRxGrid, radarTxGrid);

end

