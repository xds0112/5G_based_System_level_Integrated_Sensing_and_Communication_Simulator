function cfar2D = cfarConfig(radarEstParams)
%CFAR Constant false alarm rate detector
%   
% Note that selecting the values of [GuardBandSize] and [TrainingBandSize]
% for a [CFARDetector2D] object can be a challenging problem,
% as it depends on the specifics of the radar system, the signal environment,
% and the requirements of the application. 
% There is no one-size-fits-all approach to selecting these values.
%
% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% Range and velocity detection zone
    % Used in 2D-FFT algorithm only
    nIFFT                = radarEstParams.nIFFT;
    nFFT                 = radarEstParams.nFFT;
    rngGrid              = ((0:1:nIFFT-1)*radarEstParams.rRes)';           % [0,nIFFT-1]*rRes
    dopGrid              = ((-nFFT/2:1:nFFT/2-1)*radarEstParams.vRes)';    % [-nFFT/2,nFFT/2-1]*vRes
    rngDetec             = radarEstParams.cfarEstZone(1,:);    % x to y m
    dopDetec             = radarEstParams.cfarEstZone(2,:);    % x to y m/s
    [~,rngIdx]           = min(abs(rngGrid-rngDetec));
    [~,dopIdx]           = min(abs(dopGrid-dopDetec));
    [columnIdxs,rowIdxs] = meshgrid(dopIdx(1):dopIdx(2), rngIdx(1):rngIdx(2));
    CUTIdx               = [rowIdxs(:) columnIdxs(:)]';        % Cell-under-test index

    %% 2D-CFAR
    cfarDetector2D                       = phased.CFARDetector2D;
    cfarDetector2D.Method                = 'CA';                % 'CA', 'GOCA', 'SOCA', 'OS'
    cfarDetector2D.ThresholdFactor       = 'Auto';              % 'Auto', 'Input port', 'Custom'
    cfarDetector2D.ProbabilityFalseAlarm = radarEstParams.Pfa;  % Only when 'ThresholdFactor' is set to 'Auto'
    cfarDetector2D.OutputFormat          = 'Detection index';   % 'CUT result', 'Detection index'
    cfarDetector2D.GuardBandSize         = [1 1];               % guardbandSize
    cfarDetector2D.TrainingBandSize      = [8 8];               % trainingbandSize

    %%
    cfar2D.CUTIdx         = CUTIdx;
    cfar2D.cfarDetector2D = cfarDetector2D;

end

