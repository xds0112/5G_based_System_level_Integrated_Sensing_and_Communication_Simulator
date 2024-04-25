function [comResults, senResults] = networkSimulation(simuParams, enableParallelSim)
%NETWORKSIMULATION
%   simulate multi-cell integrated sensing and communication network

    %% Simulation key parameters
    % Time, roi and log decision
    time        = simuParams.time;
    roi         = simuParams.roi;
    logDecision = simuParams.log;

    % Simulation scenario
    cityParams = values(simuParams.cityParameters);

    % Various parameters contributing to the cellular simulation
    bsParams         = values(simuParams.bsParameters);
    ueParams         = values(simuParams.ueParameters);
    targetParams     = values(simuParams.targetParameters);
    schedulingParams = values(simuParams.schedulingParameters);
    trafficParams    = values(simuParams.trafficParameters);
    pathlossParams   = values(simuParams.pathLossParameters);
    comChannelParams = values(simuParams.comChannelParameters);

    % Validate cell parameters
    validateCellParams(bsParams, ueParams, targetParams, schedulingParams, trafficParams, pathlossParams, comChannelParams)

    %% Main simulation loop
    numCells = numel(bsParams);
    [topoParams, targetlists, cellSimuParams, comResults, senResults] = deal(cell(numCells, 1));

    
    % Plot simulation layout
    simuLayout = generateScenario1(roi, cityParams);

    % Get simulation parameters for each cell
    for iCell = 1:numCells
        % Cell simulation parameters
        cellSimuParams{iCell} = simulation.assignCellSimulationParameters(time, bsParams{iCell}, ...
            schedulingParams{iCell}, trafficParams{iCell}, pathlossParams{iCell}, comChannelParams{iCell}, logDecision);

        % Get target path and sector distribution 
        targetlists{iCell} = tools.createtargetlists(bsParams{iCell}.attachedTargets, cellSimuParams{iCell}.numSlots);
        topoParams{iCell} = networkTopology.topo(bsParams{iCell}, targetlists{iCell});
    
        % Get LoS conditions
        [ueLoS, targetLoS] = plotLoS(simuLayout, bsParams{iCell}, ueParams{iCell}, targetlists{iCell});
        [cellSimuParams{iCell}.ueLoSConditions, cellSimuParams{iCell}.targetLoSConditions] = deal(ueLoS, targetLoS);

    end


    % Loop over all the cells
    if enableParallelSim % parallel simulation

        % Parallel computing pool
        delete(gcp('nocreate'));
        parpool();

        % Use parfeval to asynchronously run ISAC cell simulation
        cellResults = parfeval(@simulation.cellSimulation, 2, cellSimuParams{:});

        % Retrieve results once the execution of cellSimulation is complete
        [comResults, senResults] = fetchOutputs(cellResults);

    else % local simulation
        for iCell = 1:numCells
            % ISAC simulation for each cell
            [comResults{iCell}, gNB, cellSimuParam] = simulation.cellSimulation(cellSimuParams{iCell});
            senResults{iCell} = simulation.cellSensing(gNB, cellSimuParam, topoParams{iCell}, targetlists{iCell});          
        end
    end

    % Plot ECDF of communication metrics
    plotComMetricsECDF(comResults)
    
end

%% Local function
function validateCellParams(bsParams, ueParams, targetParams, schedulingParams, trafficParams, pathlossParams, comChannelParams)
% Validate all the parameters to ensure the correctness of cell numbers
    lengths = [length(bsParams), length(ueParams), length(targetParams), length(schedulingParams), ...
        length(trafficParams), length(pathlossParams), length(comChannelParams)];
    
    if ~all(lengths == lengths(1)) % Lengths of cell parameters within the network do not match
        disp('A mismatch occurred in the number of cells, please check the scenario parameters.');
    end
end

function simuLayout = generateScenario1(roi, cityParams)
    % Generate scenario
    % Invoke the constructor to create the simulation scenario
    simuLayout = networkTopology.blockages.openStreetMapCity(cityParams{1}, roi);

    % Plot the layout and network nodes
    figure(1)
    title('Simulation Scenario')
    
    % Plot the layout
    simuLayout.plot(tools.colors.darkGrey) % light grey

    grid on

    xlim([roi.xMin roi.xMax])
    ylim([roi.yMin roi.yMax])
    xlabel('x axis (m)')
    ylabel('y axis (m)')
    zlabel('z axis (m)')

end

function [ueLoSConditions, targetLoSConditions] = plotLoS(simuLayout, bsParams, ueParams, targetParams)
% Check and plot the LoS conditions between antennas
% on the gNB and UEs within each cell

    % gNBs and UEs topology parameters
    gNBPos     = bsParams.position;
    uePos      = ueParams.position;
    numUEs     = ueParams.numUEs;
    numTargets = length(targetParams);

    % Plot the layout, gNB/antennas, UEs and targets
    figure(1)
    gNBPlot = tools.plotScatter3D(gNBPos, 20, tools.colors.darkRed); % dark red

    % LoS conditions corresponding with UEs, 
    % [numUEs x 1] row vector
    ueLoSConditions = zeros(numUEs,1);
    for i = 1:numUEs
        uePlot = tools.plotScatter3D(uePos(i,:), 10, tools.colors.darkBlue); % dark blue
        % Update the LoS condition for each UE
        ueLoSConditions(i) = simuLayout.checkLoS(uePos(i,:), gNBPos);
        % Draw the LoS link
        hold on
        if ueLoSConditions(i)
            losLink = tools.drawLine3D(gNBPos, uePos(i,:), tools.colors.lightRed);
        end
        hold off
    end

    % LoS conditions corresponding with targets
    targetLoSConditions = cell(1,numTargets);
    for uu = 1:numTargets
        targetPos  = targetParams{uu}';
        targetLoSConditions{uu} = zeros(size(targetPos,1),1);
        for t = 1:size(targetPos,1)
            targetPlot = tools.plotScatter3D(targetPos(t,:), 10, tools.colors.darkGreen); % dark green
    
            % Update the LoS condition for each target
            targetLoSConditions{uu}(t) = simuLayout.checkLoS(targetPos(t,:), gNBPos);
            targetLoSConditions{uu}(t) = 1;
            % Draw the LoS link
            hold on
            if targetLoSConditions{uu}(t)
                losLink = tools.drawLine3D(gNBPos, targetPos(t,:), tools.colors.lightRed);
            end
            hold off
        end
    end

%     % Check if there is a LoS link
%     if any(ueLoSConditions) || any(targetLoSConditions)
    legend([gNBPlot uePlot targetPlot losLink], {'gNB' 'UEs' 'Targets' 'LoS link'})
%     else % LoS path doesn't exist in both gNB-UEs links and gNB-targets links
%         legend([gNBPlot uePlot targetPlot], {'gNB' 'UEs' 'Targets'})
%         disp('Note that no LoS path exists in the simulation scenario')
%     end
end

function plotComMetricsECDF(results)

    numCells = numel(results);

    % Plot uplink throughput 
    figure('Name', 'ECDF of UL Throughput')

    for n = 1:numCells
        cellstr = ['cell-' num2str(n)];
        ulThroughputDataRate = results{n}.ueULThroughput;
        %ulGoodPutDataRate    = results{n}.ueULGoodput;
        ulTp = tools.plotECDF(ulThroughputDataRate, 1);
        %hold on
        %ulGp = tools.plotECDF(ulGoodPutDataRate, 1);
        %legend([ulTp, ulGp], {['Uplink throughput of ' cellstr], ['Uplink goodput of ' cellstr]})
        legend(ulTp, ['Uplink throughput of ' cellstr])
    end
    grid on
    title('ECDF of Uplink Throughput')
    xlabel('Data Rate (Mbps)')
    ylabel('Cumulative Probability')


    % Plot downlink throughput  

    for n = 1:numCells
        cellstr = ['cell-' num2str(n)];
        figure('Name', 'ECDF of DL Throughput')
        dlThroughputDataRate = results{n}.ueDLThroughput;
        %dlGoodputDataRate    = results{n}.ueDLGoodput;
        dlTp = tools.plotECDF(dlThroughputDataRate, 1);
        %hold on
        %dlGp = tools.plotECDF(dlGoodputDataRate, 1);
        legend(dlTp, ['Downlink throughput of ' cellstr])
        grid on
        title('ECDF of Downlink Throughput')
        xlabel('Data Rate (Mbps)')
        ylabel('Cumulative Probability')
    end

    % Plot uplink & downlink BLER
    figure('Name', 'ECDF of DL & UL BLER')

    for n = 1:numCells
        ulBLER = results{n}.ueULBLER;
        dlBLER = results{n}.ueDLBLER;
        if ~any(isnan(ulBLER)) && ~any(isnan(dlBLER))
            ulbl = tools.plotECDF(ulBLER, 1);
            hold on
            dlbl = tools.plotECDF(dlBLER, 1);
            legend([ulbl dlbl], {['Uplink BLER of ' cellstr], ['Downlink BLER of ' cellstr]})
        end
    end

    grid on
    xlim([0 1])
    xlabel('Block Error Rate')
    ylabel('Cumulative Probability')
    title('ECDF of Uplink and Downlink Block Error Rates')

end

