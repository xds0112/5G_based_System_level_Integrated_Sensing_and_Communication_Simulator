function validateParameters(simuParams)
%VALIDATEPARAMETERS 
%   
    % Validate the UE positions
    validateattributes(simuParams.uePosition, {'numeric'}, {'nonempty', 'real', 'nrows', ...
        simuParams.numUEs, 'ncols', 3, 'finite'}, 'simParameters.uePosition', 'uePosition');
    
    % Validate the number of transmitter and receiver antennas at UE
    validateattributes(simuParams.ueTxAnts, {'numeric'}, {'nonempty', 'integer', 'nrows', ...
        simuParams.numUEs, 'ncols', 1, 'finite'}, 'simParameters.ueTxAnts', 'ueTxAnts')
    validateattributes(simuParams.ueRxAnts, {'numeric'}, {'nonempty', 'integer', 'nrows', ...
        simuParams.numUEs, 'ncols', 1, 'finite'}, 'simParameters.ueRxAnts', 'ueRxAnts')

    % Validate the DL application data rate
    validateattributes(simuParams.dlAppDataRate, {'numeric'}, {'nonempty', 'vector', 'numel', ...
        simuParams.numUEs, 'finite', '>', 0}, 'dlAppDataRate', 'dlAppDataRate');
    % Validate the UL application data rate
    validateattributes(simuParams.ulAppDataRate, {'numeric'}, {'nonempty', 'vector', 'numel', ...
        simuParams.numUEs, 'finite', '>', 0}, 'ulAppDataRate', 'ulAppDataRate');
    
end

