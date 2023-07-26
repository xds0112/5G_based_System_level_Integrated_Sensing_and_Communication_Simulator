function subbandPRB = subbandSize(prb)
%SRSSUBBANDSIZE 
%   Refer to TS 38.214 Table 5.2.1.4-2.

    if (prb >= 24) &&  (prb <= 72)
        subbandPRB = [4 8];   % 4 or 8
    elseif (prb >= 73) &&  (prb <= 144)
        subbandPRB = [8 16];  % 8 or 16
    elseif (prb >= 145) &&  (prb <= 275)
        subbandPRB = [16 32]; % 16 or 32
    else
        error('NumRBs is out of limit')    
    end
    subbandPRB = subbandPRB(randperm(2,1));

end

