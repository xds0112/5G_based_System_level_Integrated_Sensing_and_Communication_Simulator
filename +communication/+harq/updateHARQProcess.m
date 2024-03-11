function harqProcess = updateHARQProcess(harqProcess,ncw)
%updateHARQProcess Update HARQ process
%
%   HARQPROC = hUpdateHARQProcess(HARQPROC,NCW) updates the HARQ process,
%   HARQPROC, redundancy version values based on block errors to the next
%   value from the RVSequence. If there are no errors, it resets this to
%   the starting value. NCW is the number of codewords for the process,
%   which must be 1 or 2.
%
%   See also hNewHARQProcesses.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

    % Update HARQ process redundancy version (RV)
    if any(harqProcess.blkerr)
        L = length(harqProcess.RVSequence);
        for cwIdx = 1:ncw
            if harqProcess.blkerr(cwIdx)
                harqProcess.RVIdx(cwIdx) = mod(harqProcess.RVIdx(cwIdx),L)+1; % 1-based indexing
                harqProcess.RV(cwIdx) = harqProcess.RVSequence(harqProcess.RVIdx(cwIdx));
            else % no error => reset
                harqProcess.RVIdx(cwIdx) = 1;
                harqProcess.RV(cwIdx) = harqProcess.RVSequence(1);
            end
        end        
    else % no error => reset
        harqProcess.RVIdx(:) = 1;
        harqProcess.RV(:) = harqProcess.RVSequence(1);
    end
    
end
