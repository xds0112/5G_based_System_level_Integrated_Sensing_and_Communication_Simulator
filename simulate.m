function results = simulate(scenarioFunctionHandle, enableParallelSim)
% System-Level 5G-based integrated sensing and communcation Simulator 

% Simulate multi-node integrated sensing and communcation network. 

% Author: D.S.Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% BUPT copyright    
    printCopyRight

    %% Initialize simulation parameters
    simuParams = parameters.simulationParameters;
    simuParams = scenarioFunctionHandle(simuParams);

    %% ISAC multi-node simulation 
    [comResults, senResults] = simulation.networkSimulation(simuParams, enableParallelSim);

    %% Restore results
    results = struct;
    results.communicationResults = comResults;
    results.sensingResults       = senResults;

    %% Local functions
    function printCopyRight

        currentTime = datetime('now');
    
        fprintf('5G-based System-level Integrated Sensing and Communication Simulator\n')
        fprintf('\n')
        fprintf('Copyright (C) 2023 Beijing University of Posts and Telecommunications\n')
        fprintf('All rights reserved.\n')
        fprintf('\n')
        fprintf('Authors: Dongsheng Xue, et.al\n')
        fprintf('Key Laboratory of Universal Wireless Communications, Ministry of Education\n')
        fprintf('Date: %s\n', char(currentTime))
        fprintf('\n')

    end

end
