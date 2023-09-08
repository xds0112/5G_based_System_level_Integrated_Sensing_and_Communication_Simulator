function results = simulate(scenarioFunctionHandle, enableParallelSim)
% System-Level 5G-based integrated sensing and communcation Simulator 

% Simulate multi-node integrated sensing and communcation network. 

% Author: D.S.Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% BUPT copyright    
    tools.printCopyright

    %% Initialize simulation parameters
    simuParams = parameters.simulationParameters;
    simuParams = scenarioFunctionHandle(simuParams);

    %% ISAC multi-node simulation 
    [comResults, senResults] = simulation.networkSimulation(simuParams, enableParallelSim);

    %% Restore results
    results = struct;
    results.communicationResults = comResults;
    results.sensingResults       = senResults;

end
