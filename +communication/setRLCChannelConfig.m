function [numLogicalChannels,rlcChannelConfig,simuParams] = setRLCChannelConfig(simuParams)
%setRLCChannelConfig 
%   

    % Specify one logical channel for each UE, and set the logical channel configuration
    % for all nodes (UEs and gNBs).
    
    numLogicalChannels = 1;
    simuParams.lchConfig.LCID = 4;

    % Specify the RLC entity type in the range [0, 3],
    % The values 0, 1, 2, and 3 indicate RLC UM unidirectional DL entity,
    % RLC UM unidirectional UL entity, RLC UM bidirectional entity,
    % and RLC AM entity, respectively.
    simuParams.rlcConfig.EntityType = 2;

    % Create RLC channel configuration structure
    rlcChannelConfig = struct;    
    rlcChannelConfig.LCGID            = 1;  % Mapping between logical channel and logical channel group ID
    rlcChannelConfig.Priority         = 1;  % Priority of each logical channel
    rlcChannelConfig.PBR              = 8;  % Prioritized bitrate (PBR), in kilobytes per second, of each logical channel
    rlcChannelConfig.BSD              = 10; % Bucket size duration (BSD), in ms, of each logical channel
    rlcChannelConfig.EntityType       = simuParams.rlcConfig.EntityType;
    rlcChannelConfig.LogicalChannelID = simuParams.lchConfig.LCID;

end

