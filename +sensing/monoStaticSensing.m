function echoGrid = monoStaticSensing(txWaveform, txDimension, carrierInfo, radarParams, targetLoSConditions)
% Simulate gNB-based mono-static sensing.
%
% Author: D.S.Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    % Carrier information
    carrier = nrCarrierConfig;
    carrier.SubcarrierSpacing = carrierInfo.SubcarrierSpacing;
    carrier.NSizeGrid         = carrierInfo.NRBsDL;

    % Pass txWaveform through radar propagation channel
    txEcho = sensing.channelModels.basicRadarChannel(txWaveform, radarParams, targetLoSConditions);

    % OFDM demodulation
    echoGrid = nrOFDMDemodulate(carrier, txEcho);

    % Echo grid dimension validation
    if size(echoGrid, 2) < txDimension(2)
        echoGrid = [echoGrid zeros(size(echoGrid, 1), txDimension(2)-size(echoGrid, 2), size(echoGrid, 3))];
    end

end
