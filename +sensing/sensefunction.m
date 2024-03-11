function senResults = sensefunction(gNB,cellSimuParams)
%SENSEFUNCTION 此处显示有关此函数的摘要
%   此处显示详细说明
    carrierInfo = gNB.PhyEntity.CarrierInformation;
    waveInfoDL  = gNB.PhyEntity.WaveformInfoDL;
    radarParams = sensing.radarParams(cellSimuParams, carrierInfo, waveInfoDL);
    cfarConfig  = sensing.detection.cfar2D(radarParams);
    
    % Sensing process
    % Sensing transmission grid and waveform
    senTxGrid = gNB.PhyEntity.senTxGrid;
    senTxWave = gNB.PhyEntity.senTxWave;
    % Mono-static sensing
    senRxGrid = sensing.monoStaticSensing(senTxWave, size(senTxGrid), carrierInfo, radarParams, cellSimuParams.targetLoSConditions);
    % Sensing Results
    try
        senResults = sensing.estimation.fft2D(radarParams, cfarConfig, senRxGrid, senTxGrid);
    catch exception
        errorMessage = getReport(exception, 'extended', 'hyperlinks', 'off');
        fprintf('Error in the cellSimulation function:\n%s\n', errorMessage)
        senResults = NaN;
    end
end

