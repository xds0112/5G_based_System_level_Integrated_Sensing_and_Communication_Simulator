function [srsSubbandSize, srsConfig] = setupSRS(numRBs,numUEs)
%SETUPSRS 
%   % Specify the SRS configuration for each UE. The example assumes full-bandwidth
    % SRS and transmission comb number as 4, so up to 4 UEs are frequency multiplexed
    % in the same SRS symbol by giving different comb offset. When number of UEs are
    % more than 4, they are assigned different SRS slot offsets.
    
    srsSubbandSize = communication.subbandSize(numRBs);
    srsConfig = cell(1, numUEs);
    combNumber = 4; % SRS comb number
    for ueIdx = 1:numUEs
        % Ensure non-overlapping SRS resources when there are more than 4 UEs by giving different offset
        srsPeriod = [8 3+floor((ueIdx-1)/4)];
        srsBandwidthMapping = nrSRSConfig.BandwidthConfigurationTable{:,2};
        csrs = find(srsBandwidthMapping <= numRBs, 1, 'last') - 1;
        % Set full bandwidth SRS
        srsConfig{ueIdx} = nrSRSConfig;
        srsConfig{ueIdx}.NumSRSPorts = 2;
        srsConfig{ueIdx}.SymbolStart = 13;
        srsConfig{ueIdx}.SRSPeriod = srsPeriod;
        srsConfig{ueIdx}.KTC = combNumber;
        srsConfig{ueIdx}.KBarTC = mod(ueIdx-1, combNumber);
        srsConfig{ueIdx}.BSRS = 0;
        srsConfig{ueIdx}.CSRS = csrs;
    end
    
end

