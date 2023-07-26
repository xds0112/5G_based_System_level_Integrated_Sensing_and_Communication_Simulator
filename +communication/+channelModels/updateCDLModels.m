function delayProfile = updateCDLModels(simuParams)
%UPDATECDLMODELS 
%   Update channel models based on the LoS conditions
% Default channel model for NLoS conditions is CDL-A, 
% default channel model for LoS conditions is CDL-D.

    delayProfile = cell(simuParams.numUEs, 1);

    for i = 1:simuParams.numUEs
        if (simuParams.ueLoSConditions(i) == 0) % NLoS condition
            delayProfile{i} = 'CDL-A';
        else % LoS condition (remain the CDL-D channel)
            delayProfile{i} = 'CDL-D';
        end
    end
end

