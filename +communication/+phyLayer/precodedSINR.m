%   SINR = precodedSINR(H,SIGMA,W) returns the ratio of the power of a
%   unit-power signal precoded with matrix W at the receive side of a MIMO
%   channel H and the noise power specified by the standard deviation
%   SIGMA. The function uses a linear minimum mean squared error (LMMSE)
%   SINR metric for PMI selection.
%
%   See also pmiSelect, pmiSelectionSINRLoss.

%   Copyright 2019 The MathWorks, Inc.

function sinr = precodedSINR(H,sigma,W)
    
    noise = sigma^2*eye(size(W,2)); % Noise variance per layer
    den = noise/( (W'*H')*H*W+noise );

    sinr = real(sum((1./diag(den))-1));
    
end