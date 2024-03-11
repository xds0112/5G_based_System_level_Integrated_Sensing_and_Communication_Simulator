%pmiSelect Select precoder matrix indicator
%   [PMI,SINR,SUBBANDIDX] = pmiSelect(NLAYERS, HEST, NOISEEST, BANDSIZE)
%   selects a vector PMI of precoder matrix indicators used for
%   codebook-based transmission of a number of layers NLAYERS over a MIMO
%   channel. Codebook-based transmission is defined in TS 38.211 Section
%   6.3.1.5. The MIMO channel estimates HEST must be an array of dimensions
%   K-by-L-by-R-by-P where K is the number of subcarriers, L is the number
%   of OFDM symbols, R is the number of receive antennas and P is the
%   number of reference signal ports. Each element of PMI contains a
%   precoding matrix indicator for each frequency subband of size BANDSIZE
%   in resource blocks. This function uses a linear minimum mean squared
%   error (LMMSE) SINR metric for PMI selection.
%
%   SINR is a matrix of dimensions NSB-by-(MaxTPMI+1) containing the
%   signal-to-interference-plus-noise ratio per subband after precoding
%   with all possible precoder matrices for a number of ports P and number
%   of layers NLAYERS. NSB is the number of subbands of size BANDSIZE and
%   MaxTPMI the largest precoder matrix indicator for P and NLAYERS.
%
%   SUBBANDIDX is a NSB-by-2 matrix containing the first and last
%   subcarrier indices of HEST for each of the subbands of size BANDSIZE
%   used for PMI selection.
%
%   See also hPrecodedSINR, hMaxPUSCHPrecodingMatrixIndicator.

%   Copyright 2019 The MathWorks, Inc.

function [pmi,sinr,subbandIndices] = pmiSelect(nlayers, hest, noiseest, bandSize)

    nports = size(hest,4);
    maxTPMI = communication.phyLayer.maxPUSCHPrecodingMatrixIndicator(nlayers,nports);
    [numSC,numSymb] = size(hest,[1 2]);
    sinr = zeros(numSC,numSymb,maxTPMI+1);
    
    % Indices where channel estimation information is available
    ind = find( sum(hest,3:4)~=0 ) ;
    [sc,symb]= ind2sub([numSC numSymb],ind);
    subs = [sc,symb]; 
    
    if ~isempty(subs) && noiseest ~= 0      
        H = permute(hest,[3 4 1 2]); % RxAntPorts-by-TxAntPorts-by-NumSubcarriers-by-NumOFDMSymbols
        sigma = sqrt(noiseest); % Standard deviation of noise
        
        for tpmi = 0:maxTPMI
            W = nrPUSCHCodebook(nlayers,nports,tpmi).';
            
            % Get the SINR after precoding with W for each RE
            for i = 1:length(subs)
                scNo = subs(i,1);
                symbNo = subs(i,2);
                sinr(scNo,symbNo,tpmi+1) = communication.phyLayer.precodedSINR(H(:,:,scNo,symbNo),sigma,W); % Perform codebook selection using LMMSE SINR metric
            end
        end
        
        [sinrBands,subbandIndices] = communication.phyLayer.sinrPerSubband(sinr, bandSize);
        [~,pmi]  = max(sinrBands,[],2);
        pmi(isnan(sinrBands(:,1))) = NaN;
        pmi = pmi-1; % PMI is 0-based
        sinr = sinrBands; % Return SINR per subband
        
    else % If there are no channel estimates available
        pmi = NaN;
        sinr = NaN;
        subbandIndices = NaN;
    end
end