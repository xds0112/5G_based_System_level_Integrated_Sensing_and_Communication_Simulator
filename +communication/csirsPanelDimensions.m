function csirsPanel = csirsPanelDimensions(antennaPorts)
%UNTITLED
%   Refer to 3GPP TS 38.214 Table 5.2.2.2.1-2.
     switch antennaPorts
         case 4
             csirsPanel = [2 1];            % [2 1]
         case 8
             csirsPanel = [2 2; 4 1];       % [2 2] or [4 1]
         case 12
             csirsPanel = [3 2; 6 1];       % [3 2] or [6 1]
         case 16
             csirsPanel = [4 2; 8 1];       % [4 2] or [8 1]
         case 24
             csirsPanel = [4 3; 6 2; 12 1]; % [4 3] or [6 2] or [12 1]
         case 32
             csirsPanel = [4 4; 8 2; 16 1]; % [4 4] or [8 2] or [16 1]            
     end
     csirsPanel = csirsPanel(randperm(size(csirsPanel,1),1),:);
end

