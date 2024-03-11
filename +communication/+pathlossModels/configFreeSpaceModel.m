function pathLoss = configFreeSpaceModel(carrierFreq, bsPosition, uePosition)
%CONFIGFRESSSPACEMODEL 
%   Calculate free space pathloss (in dB): L = 20*log10(4πR/λ)
    lambda = physconst('LightSpeed')/carrierFreq;
    distance = vecnorm(uePosition' - bsPosition');
    pathLoss = fspl(distance, lambda);
end

