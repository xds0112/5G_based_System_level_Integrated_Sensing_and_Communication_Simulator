function simuParams = setupSINRtoCQIMappingTable(simuParams)
%SETUPSINRTOCQIMAPPINGTABLE 
%   % Specify the signal-to-interference-plus-noise ratio (SINR) to a CQI index
    % mapping table for a block error rate (BLER) of 0.1. The lookup table corresponds
    % to the CQI table as per 3GPP TS 38.214 Table 5.2.2.1-3.
    
    simuParams.downlinkSINR90pc = [-3.4600 1.5400 6.5400 11.0500 13.5400 16.0400 ...
        17.5400 20.0400 22.0400 24.4300 26.9300 27.4300 29.4300 32.4300 35.4300];

    simuParams.uplinkSINR90pc   = [-5.4600 -0.4600 4.5400 9.0500 11.5400 14.0400 ...
        15.5400 18.0400 20.0400 22.4300 24.9300 25.4300 27.4300 30.4300 33.4300];
    
end

