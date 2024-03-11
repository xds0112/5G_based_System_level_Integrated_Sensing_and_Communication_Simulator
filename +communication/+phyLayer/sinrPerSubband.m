%   [sinrBand, subbandIndices] = sinrPerSubband(SINR, BANDSIZE) returns
%   the average SINR per frequency subband and precoder matrix indicator
%   (PMI). The input SINR must contain the signal to interference plus
%   noise ratio per resource element. The size of SINR must be K-by-L-by-P
%   with K the number of subcarriers, L the number of OFDM symbols and P
%   the number of TPMI used to calculate the SINR.
%
%   See also pmiSelect, pmiSelectionSINRLoss.

%   Copyright 2019 The MathWorks, Inc.

function [sinrSubband, subbandIndices] = sinrPerSubband(sinr, bandSize)

    nrb = size(sinr,1)/12;
    
    % Subcarrier indices of the PMI subbands
    r = nrb/bandSize;
    
    extraBand = ones(floor(r)~=r);
    subbandIndices(:,1) = 12*bandSize*[0:r-1 floor(r)*extraBand]'+1;
    subbandIndices(:,2) = 12*bandSize*[1:r r*extraBand]';
    
    numTPMI = size(sinr,3);
    numSubbands = ceil(nrb/bandSize);
    sinrSubband = zeros(numSubbands, numTPMI);
    for s = 1:numSubbands
        % Select region of subcarriers in subband s
        scStart  = subbandIndices(s,1);
        scFinish = subbandIndices(s,2);
        
        % Average SINR per subband
        sinrs = sinr(scStart:scFinish,:,:);
        sinrSubband(s,:) = squeeze( sum(sinrs,[1 2])/sum(sum(sinrs,3)~=0,[1 2]) )';
    end
end