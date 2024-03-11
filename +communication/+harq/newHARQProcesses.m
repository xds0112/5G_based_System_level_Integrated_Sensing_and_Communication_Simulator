function harqProcesses = newHARQProcesses(numHARQProcesses,rvsequence,ncw)
%newHARQProcesses Create new HARQ processes
%
%   HARQPROCESSES = newHARQProcesses(NUMHARQPROC,RVSEQUENCE,NCW) generates
%   an array of NUMHARQPROC new HARQ processes with the provided RV
%   sequence values RVSEQUENCE. NCW must be 1 or 2 for the number of
%   codewords supported.
%
%   See also hUpdateHARQProcess.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

    harqProcess.RVSequence = rvsequence;    % Sharing one rvsequence per CW
    harqProcess.ncw = ncw;                  % Set number of codewords

    harqProcess.blkerr = zeros(1,ncw);      % Initialize block errors    
    harqProcess.RVIdx = ones(1,ncw);        % Add RVIdx to process
    harqProcess.RV = rvsequence(ones(1,ncw));
        
    % Create HARQ processes as indicated by numHARQProcesses
    harqProcesses = repmat(harqProcess,numHARQProcesses,1);
    
end
