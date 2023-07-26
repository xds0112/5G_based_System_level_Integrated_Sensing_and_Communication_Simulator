%maxPUSCHPrecodingMatrixIndicator maximum PUSCH PMI
%   W = maxPUSCHPrecodingMatrixIndicator(NLAYERS,NPORTS) returns the
%   maximum PUSCH Transmitted Precoding Matrix Indicator index for
%   codebook-based transmission in TS 38.211 Section 6.3.1.5 for number of
%   layers NLAYERS (1...4), number of antenna ports NPORTS (1,2,4).
%   
%   maxTPMI=1 for NLAYERS=1 and NPORTS=1 otherwise it is selected from 
%   TS 38.211 Tables 6.3.1.5-1...7, depending on NLAYERS and NPORTS.
%
%   See also nrPUSCHCodebook, nrLayerMap, nrLayerDemap.
 
%   Copyright 2019 The MathWorks, Inc.

function maxTPMI = maxPUSCHPrecodingMatrixIndicator(nlayers,nports)
   
    narginchk(2,2);
    
    fcnName = 'hMaxPUSCHPrecodingMatrixIndicator';
    validateattributes(nlayers,{'numeric'}, ...
        {'scalar','integer','>=',1,'<=',4},fcnName,'NLAYERS');
    validateattributes(nports,{'numeric'}, ...
        {'scalar','integer'},fcnName,'NPORTS');
    
    if ~any(nports==[1 2 4])
        error('nr5g:hMaxPUSCHPrecodingMatrixIndicator:InvalidNPorts','Invalid number of ports (%d). The number of ports must be 1, 2 or 4. ', nports);
    elseif nlayers>nports
        error('nr5g:hMaxPUSCHPrecodingMatrixIndicator:TooManyLayers','The number of layers (%d) must be lower than or equal to the number of ports (%d).',nlayers, nports);
    end
    
    if (nlayers==1) % single-layer transmission
        
        if (nports==1) % single antenna port
            
            % Section 6.3.1.5
            maxTPMI = 0;
            
        elseif (nports==2) % two antenna ports
            
            % Table 6.3.1.5-1
            maxTPMI = 5;
            
        else % four antenna ports
            
            % Table 6.3.1.5-(2/3)
            maxTPMI = 27;
            
        end
        
    elseif (nlayers==2) % two-layer transmission
        
        if (nports==2) % two antenna ports
            
            % Table 6.3.1.5-4
            maxTPMI = 2;
            
        else % four antenna ports
            
            % Table 6.3.1.5-5
            maxTPMI = 21;
        end
        
    elseif (nlayers==3) % three-layer transmission using four antenna ports
        
        % Table 6.3.1.5-6
        maxTPMI = 6;
        
    else % four-layer transmission using four antenna ports
        
        % Table 6.3.1.5-7
        maxTPMI = 4;
    end
    
end

