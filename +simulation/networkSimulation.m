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
    [cellSimuParams, comResults, senResults] = deal(cell(numCells, 1));

    % Plot simulation layout
    simuLayout = generateScenario(cityParams{1}, roi);

    % Loop over all the cells
    for iCell = 1:numCells
        % Get simulation parameters for each cell
        cellSimuParams{iCell} = simulation.assignCellSimulationParameters(time, bsParams{iCell}, ...
            schedulingParams{iCell}, trafficParams{iCell}, pathlossParams{iCell}, comChannelParams{iCell}, logDecision);

        % check the LoS conditions for each cell
        [cellSimuParams{iCell}.ueLoSConditions, cellSimuParams{iCell}.targetLoSConditions] = checkLoS(simuLayout, bsParams{iCell}, ueParams{iCell}, targetParams{iCell});

        % ISAC simulation for each cell
        [comResults{iCell}, senResults{iCell}] = simulation.cellSimulation(cellSimuParams{iCell});
    end

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

function simuLayout = generateScenario(cityParams, roi)
    % Generate scenario
    % Invoke the constructor to create the simulation scenario
    simuLayout = networkTopology.blockages.openStreetMapCity(cityParams, roi);
    
    % Plot the layout, gNB and UEs
    figure(1)
    title('Simulation Scenario')
    
    simuLayout.plot(tools.colors.lightGrey) % light grey

    grid on

    xlim([roi.xMin roi.xMax])
    ylim([roi.yMin roi.yMax])

    xlabel('x axis (m)')
    ylabel('y axis (m)')
    zlabel('z axis (m)')
end

function [ueLoSConditions, targetLoSConditions] = checkLoS(simuLayout, bsParams, ueParams, targetParams)
% Check and plot the LoS conditions between antennas
% on the gNB and UEs within each cell

    % gNB and UEs topology parameters
    gNBPos     = bsParams.position;
    uePos      = ueParams.position;
    numUEs     = ueParams.numUEs;
    targetPos  = targetParams.position;
    numTargets = targetParams.numTargets;

    % Plot the layout, gNB/antennas, UEs and targets
    figure(1)
    gNBPlot = tools.plotScatter3D(gNBPos, 15, tools.colors.darkRed); % dark red

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

    % LoS conditions corresponding with targets, 
    % [numTargets x 1] row vector
    targetLoSConditions = zeros(numTargets,1);
    for t = 1:numTargets
        targetPlot = tools.plotScatter3D(targetPos(t,:), 10, tools.colors.darkGreen); % dark green

        % Update the LoS condition for each target
        targetLoSConditions(t) = simuLayout.checkLoS(targetPos(t,:), gNBPos);

        % Draw the LoS link
        hold on
        if targetLoSConditions(t)
            losLink = tools.drawLine3D(gNBPos, targetPos(t,:), tools.colors.lightRed);
        end
        hold off
    end

    % Check if there is a LoS link
    if any(ueLoSConditions) || any(targetLoSConditions)
        legend([gNBPlot uePlot targetPlot losLink], {'gNB' 'UEs' 'Targets' 'LoS link'})
    else % LoS path doesn't exist in both gNB-UEs links and gNB-targets links
        legend([gNBPlot uePlot targetPlot], {'gNB' 'UEs' 'Targets'})
        disp('Note that no LoS path exists in the simulation scenario')
    end
end


