function cfarConfig = cfar2D(radaParams)
%CFAR Two-dimensional (2D) constant false alarm rate detector (CFAR)
%   
% Note that selecting the values of |GuardBandSize| and |TrainingBandSize|
% for a |CFARDetector2D| object can be a challenging problem,
% as it depends on the specifics of the radar system, the signal environment,
% and the requirements of the application. 
% There is no one-size-fits-all approach to selecting these values.
%
% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% Range and velocity detection zone
    % Used in 2D-FFT algorithm only
    nIFFT                 = radaParams.nIFFT;
    nFFT                  = radaParams.nFFT;
    rngGrid               = ((0:1:nIFFT-1)*radaParams.rRes)';        % [0,nIFFT-1]*rRes
    dopGrid               = ((-nFFT/2:1:nFFT/2-1)*radaParams.vRes)'; % [-nFFT/2,nFFT/2-1]*vRes
    rngDetec              = radaParams.cfarEstZone(1,:);             % x to y m
    dopDetec              = radaParams.cfarEstZone(2,:);             % x to y m/s
    [~, rngIdx]           = min(abs(rngGrid - rngDetec));
    [~, dopIdx]           = min(abs(dopGrid - dopDetec));
    [columnIdxs, rowIdxs] = meshgrid(dopIdx(1):dopIdx(2), rngIdx(1):rngIdx(2));
    CUTIdx                = [rowIdxs(:) columnIdxs(:)]';             % cell-under-test (CUT) index

    %% 2D-CFAR
    cfarDetector2D                       = phased.CFARDetector2D;
    cfarDetector2D.Method                = 'CA';                  % supported algorithms: 'CA', 'GOCA', 'SOCA', 'OS'
    cfarDetector2D.ThresholdFactor       = 'Auto';                % 'Auto', 'Input port', 'Custom'
    cfarDetector2D.ProbabilityFalseAlarm = radaParams.Pfa;        % only when 'ThresholdFactor' is set to 'Auto'
    cfarDetector2D.OutputFormat          = 'Detection index';     % 'CUT result', 'Detection index'
    cfarDetector2D.GuardBandSize         = [2 2];                 % size of guard band
    cfarDetector2D.TrainingBandSize      = [1 1];                 % size of training band

    % assignment
    cfarConfig.CUTIdx         = CUTIdx;
    cfarConfig.cfarDetector2D = cfarDetector2D;

end

