function echoGrid = monoStaticSensing(txGrid, carrierInfo, waveInfo, radarParams)
% Simulate gNB-based mono-static sensing.

% Author: D.S.Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    % Carrier information
    carrier = nrCarrierConfig;
    carrier.SubcarrierSpacing = carrierInfo.SubcarrierSpacing;
    carrier.NSizeGrid         = carrierInfo.NRBsDL;

    % OFDM modulation
    txWaveform = nrOFDMModulate(carrier, txGrid);

    % Calculate the amplitude of the transmitted signal
    nTxAnts = radarParams.nTxAnts;
    sigAmp  = db2mag(radarParams.txPower-30)*sqrt(waveInfo.Nfft^2/(carrier.NSizeGrid*12*nTxAnts));
    txWaveform = sigAmp*txWaveform;

    % Apply radar propagation channel
    txEcho = sensing.channelModels.basicRadarChannel(txWaveform, radarParams);

    % OFDM demodulation
    echoGrid = nrOFDMDemodulate(carrier, txEcho);

    % Echo grid dimension validation
    if size(echoGrid,2) < carrier.SymbolsPerSlot
        echoGrid = [echoGrid zeros(size(echoGrid,1), carrier.SymbolsPerSlot-size(echoGrid,2), size(echoGrid,3))];
    end

end
