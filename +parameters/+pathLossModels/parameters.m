classdef parameters
    %PARAMETERS traffic model parameters
    % supported models: 
    %
    % 'fspl' — Free space
    %
    % 'UMa' — Urban macrocell
    % 
    % 'UMi' — Urban microcell
    % 
    % 'RMa' — Rural macrocell
    % 
    % 'InH' — Indoor hotspot
    % 
    % 'InF-SL' — Indoor factory with sparse clutter and low base station (BS) height
    % 
    % 'InF-DL' — Indoor factory with dense clutter and low BS height
    % 
    % 'InF-SH' — Indoor factory with sparse clutter and high BS height
    % 
    % 'InF-DH' — Indoor factory with dense clutter and high BS height
    % 
    % 'InF-HH' — Indoor factory with high Tx and high Rx
    % 
    % see also: communication.pathLossModels
        
    properties
        % Pathloss models, supported models: 
        % 'fspl' (free space), 'UMa', 'UMi', 'RMa', 'InH',
        % 'InF-SL', 'InF-DL', 'InF-SH', 'InF-DH', 'InF-HH'.
        pathLossModel
    end
    
    methods
        function obj = parameters()
            %PARAMETERS
            % creates scheduling parameters class
        end
    end
end

