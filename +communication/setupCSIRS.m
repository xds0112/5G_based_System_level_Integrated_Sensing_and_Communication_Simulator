function [csirsConfig, csiReportConfig] = setupCSIRS(numRBs)
%SETUPCSIRS 
%       % Specify the CSI-RS configuration.
    
    csirs = nrCSIRSConfig;
    csirs.NID = 1;
    csirs.NumRB = numRBs;
    csirs.RowNumber = 5;
    csirs.SubcarrierLocations = 1;
    csirs.SymbolLocations = 0;
    csirs.CSIRSPeriod = [5 2];
    csirsConfig = {csirs};
    
    % CSI report configuration
    % Specify the CSI report configuration.
    
    csiReportConfig.PanelDimensions = communication.csirsPanelDimensions(csirs.NumCSIRSPorts); % [N1 N2] as per 3GPP TS 38.214 Table 5.2.2.2.1-2
    csiReportConfig.CQIMode = 'Subband'; % 'Wideband' or 'Subband'
    csiReportConfig.PMIMode = 'Subband'; % 'Wideband' or 'Subband'
    csiReportConfig.SubbandSize = communication.subbandSize(numRBs); % Refer TS 38.214 Table 5.2.1.4-2 for valid subband sizes
    % Set codebook mode as 1 or 2. It is applicable only when the number of transmission layers is 1 or 2 and
    % number of CSI-RS ports is greater than 2
    csiReportConfig.CodebookMode  = 1;
    csiReportConfig = {csiReportConfig};

end

