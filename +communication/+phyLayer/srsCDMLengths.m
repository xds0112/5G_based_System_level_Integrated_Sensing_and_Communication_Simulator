%   CDML = srsCDMLengths(SRS) returns the CDM lengths for the SRS
%   configuration SRS. 
%   
%   SRS is an SRS-specific configuration object as described in
%   <a href="matlab:help('nrSRSConfig')">nrSRSConfig</a> with properties:
%   NumSRSPorts     - Number of SRS antenna ports (1,2,4)    
%   KTC             - Transmission comb number (2,4)
%   CyclicShift     - Cyclic shift number offset (0...NCSmax-1). 
%                     NCSmax = 12 if KTC = 4 and NCSmax = 8 if KTC = 2
%
%   See also nrSRSConfig, nrSRS, nrSRSIndices.

%   Copyright 2019 The MathWorks, Inc.

function cdmLengths = srsCDMLengths(srs)
    if srs.NumSRSPorts == 1
        cdmLengths = [1 1];
    elseif srs.NumSRSPorts == 2
        cdmLengths = [2 1];
    elseif (srs.KTC == 2 && srs.CyclicShift >= 4) || (srs.KTC == 4 && srs.CyclicShift >= 6)
        cdmLengths = [2 1];
    else
        cdmLengths = [4 1];
    end
end