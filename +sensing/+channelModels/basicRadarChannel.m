function rxWaveform = basicRadarChannel(txWaveform, radarParams, targetLoSConditions)
% Simulate Multi-Target OFDM Radar Propagation Channel.

% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% Communication parameters
    [txWaveLength, nTxAnts] = size(txWaveform);

    % OFDM parameters
    c      = physconst('Lightspeed');
    fc     = radarParams.fc; % carrier frequency
    lambda = c/fc;           % wave length
    fs     = radarParams.fs; % sampling rate/symbol rate
    Ts     = 1/fs;           % sampling-time interval

    %% Sensing parameters
    nTargets = radarParams.nTargets;

    % Range parameters
    pathDelay = 2.*radarParams.range./c; % echo delay, [1 x nTargets]
    symbolShift  = ceil(pathDelay./Ts);  % symbol shift caused by echo path delay, [1 x nTargets]

    % Velocity parameters
    fd = 2.*radarParams.velocity./lambda; % echo doppler shift, [1 x nTargets]

    %% Multi-target Radar Propagation Channel
    % Send Tx signal
    sampleTimeTx = (0:Ts:Ts*(txWaveLength-1)).';        % transpose to make a column vector
    phaseTx      = exp(2j*pi*fc*sampleTimeTx);          % carrier corresponding to Rx, [txWaveLength x nTxAnts]
    txWaveform   = bsxfun(@times, txWaveform, phaseTx); % modulation, [txWaveLength x nTxAnts]

    % Simulate small-scale propagation channel
    largeScaleFading = radarParams.largeScaleFading;
    RxSteeringVector = radarParams.RxSteeringVec; % [nTxAnts x nTargets]
    TxSteeringVector = RxSteeringVector; % Tx and Rx steering vectors are the same in the mono-static model
    [rxEchoWave, sampleTimeCh, phaseShift] = deal(cell(1, nTargets));

    for i = 1:nTargets
        if targetLoSConditions(i) == 1
            % Apply echo path delay and doppler effect
            rxEchoWave{i}   = [zeros(symbolShift(i), nTxAnts); txWaveform(1:end-symbolShift(i),:)];

            sampleTimeCh{i} = (0:Ts:Ts*(size(rxEchoWave{i},1)-1)).';        % column vector of sampling times
            phaseShift{i}   = exp(2j*pi*fd(i)*sampleTimeCh{i});             % phase shift caused by doppler effect
            rxEchoWave{i}   = bsxfun(@times, rxEchoWave{i}, phaseShift{i}); % apply phase shift
    
            % Apply large-scale fading
            rxEchoWave{i} = bsxfun(@times, rxEchoWave{i}, largeScaleFading(i));
    
            % Apply angle steering vector
            rxEchoWave{i} = rxEchoWave{i}*RxSteeringVector(:,i)*TxSteeringVector(:,i).';
    
            % Append zero padding
            rxWaveLength = size(rxEchoWave{i}, 1);
            if rxWaveLength < txWaveLength
                rxEchoWave{i} = [rxEchoWave{i}; zeros(txWaveLength-rxWaveLength, nTxAnts)];
            end
        else
            rxEchoWave{i} = []; % No echo is reflected since there is no LoS path
        end
    end

    % Combine echoes
    rxWaveform = sum(cat(3, rxEchoWave{:}), 3); % [rxWaveLength x nRxAnts]

    % Apply additive white gaussian noise (AWGN)
    N0         = sqrt(radarParams.N0/2.0);
    noise      = N0*(randn(size(rxWaveform)) + 1j*randn(size(rxWaveform)));
    rxWaveform = rxWaveform + noise;

    % Receive base-band signal
    sampleTimeRx = (0:Ts:Ts*(size(rxWaveform,1)-1)).';  % transpose to make a column vector
    phaseRx      = exp(-2j*pi*fc*sampleTimeRx);         % carrier corresponding to Rx, [rxWaveLength x 1]
    rxWaveform   = bsxfun(@times, rxWaveform, phaseRx); % base-band signal, [rxWaveLength x nRxAnts]

end