%skipWeakTimingOffset skip timing offset estimates with weak correlation
%   OFFSET = hSkipWeakTimingOffset(OFFSET,T,MAG) manages receiver timing
%   offset OFFSET, using the current timing estimate T and correlation 
%   magnitude MAG. 
%
%   See also nrTimingEstimate.

%   Copyright 2019 The MathWorks, Inc.

function offset = skipWeakTimingOffset(offset,t,mag)

    % Combine receive antennas in 'mag'
    mag = sum(mag,2);
    
    % Empirically determine threshold based on mean correlation magnitude
    threshold = mean(mag) * 5.5;
    
    % If the maximum correlation magnitude equals or exceeds the threshold,
    % accept the current timing estimate 't' as the timing offset
    if (max(mag) >= threshold)
        offset = t;
    end
    
end
