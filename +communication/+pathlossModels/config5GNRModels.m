function pathLoss = config5GNRModels(pathLossConfig, carrierFreq, losCondition, bsPosition, uePosition)
%CONFIGPATHLOSSMODELS
%   Calculate pathloss (in dB) as defined in TR 38.901 Section 7.4.1
% pathLossConfig: string to create an nrPathLossConfig object
% carrierFreq: carrier frequency, in Hz
% losCondition : 0 (false) specifies the NLoS condition, 1 (true) specifies the LoS condition
%
% supported models: 
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

    pathLossConfig = nrPathLossConfig('Scenario', pathLossConfig);

    bsPosition = bsPosition'; % Transpose to make a column vector
    uePosition = uePosition'; % Transpose to make a column vector

    if isequal(bsPosition, uePosition)
        pathLoss = 0; % Avoid the -Inf value
    else
        pathLoss = nrPathLoss(pathLossConfig, carrierFreq, losCondition, bsPosition, uePosition);
    end
end

