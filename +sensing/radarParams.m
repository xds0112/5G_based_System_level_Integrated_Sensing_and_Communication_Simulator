function radarParams = radarParams(cellSimuParams, carrierInfo, waveInfo)
% Calculate radar signal-to-noise ratio (SNR) values and 2D-FFT estimation resolutions

% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% Radar estimation parameters
    radarParams = struct; 

    %% Topology parameters
    nTargets = cellSimuParams.numTargets; % number of targets
    coords   = cellSimuParams.targetPosition' - repmat(cellSimuParams.gNBPosition', 1, nTargets); % Calculate relative coordinates
    [aziRad, eleRad, range] = cart2sph(coords(1,:), coords(2,:), coords(3,:)); % Calculate azimuth and elevation angles, in radian
    [azi, ele] = deal(rad2deg(aziRad)', rad2deg(eleRad)'); % Convert the angles to degrees, [1 x nTargets]

    %% Radar SNR calculation 
    % time, frequency, and space resources
    dlRatio  = cellSimuParams.numDLSlots/numel(cellSimuParams.tddPattern); % ratio of downlink slots in TDD mode
    nDLSlots = dlRatio*cellSimuParams.numSlots;                            % number of downlink slots in TDD mode
    nSc      = carrierInfo.NRBsDL*12;                                      % number of downlink OFDM subcarriers 
    nSym     = nDLSlots*waveInfo.SymbolsPerSlot;                           % number of downlink OFDM symbols
    uf       = 1;                                                          % freq domain even occupation spacing factor
    ut       = 1;                                                          % time domain even occupation spacing factor  
    nTxAnts  = cellSimuParams.gNBTxAnts;                                   % base station antenna size

    % OFDM parameters
    c      = physconst('Lightspeed');           % light propagation speed
    fc     = cellSimuParams.dlCarrierFreq;      % downlink carrier frequency
    scs    = carrierInfo.SubcarrierSpacing*1e3; % subcarrier spacing, in Hz
    lambda = c/fc;                              % wavelength
    fs     = waveInfo.SampleRate;               % sample rate
    Ts     = 1/fs;                              % sampling-time interval
    Tofdm  = 1/scs;                             % duration of an effective OFDM symbol
    Tcp    = Ts*ceil(nSc/8);                    % duration of normal OFDM CP
    Tsri   = Tofdm + Tcp;                       % duration of a whole OFDM symbol

    % Physical parameters
    NF  = db2pow(cellSimuParams.gNBNoiseFigure);
    Teq = cellSimuParams.gNBTemperature + 290*(NF-1); % equivalent noise temperature, in Kelvin
    N0  = fs*physconst('Boltzmann')*Teq;
    Pt  = db2pow(cellSimuParams.gNBTxPower-30)*sqrt(waveInfo.Nfft^2/(carrierInfo.NRBsDL*12*nTxAnts)); % in Walt
    Ar  = db2pow(cellSimuParams.gNBRxGain);
    At  = Ar;
    
    % Large-scale fading
    rcs   = cellSimuParams.rcs';
    r     = range';
    v     = cellSimuParams.velocity';
    Pr    = Pt.*At.*Ar.*(lambda.^2.*rcs)./((4.*pi).^3.*r.^4); % Rx power
    snr   = Pr./N0;
    snrdB = pow2db(snr);
    
    % radarEstParams
    radarParams.fc               = fc;                        % carrier frequency
    radarParams.fs               = fs;                        % sample rate
    radarParams.Tsri             = Tsri;                      % duration of a whole OFDM symbol
    radarParams.N0               = N0;                        % noise factor
    radarParams.nTxAnts          = nTxAnts;                   % number of antenna elements 
    radarParams.nTargets         = nTargets;                  % number of targets
    radarParams.range            = r;                         % range
    radarParams.velocity         = v;                         % velocity
    radarParams.largeScaleFading = sqrt(Pr./Pt);              % large-scale fading
    radarParams.snrdB            = snrdB;                     % SNR points (dB) [1 x nTargets]
    radarParams.txPower          = cellSimuParams.gNBTxPower; % transmitting power
    radarParams.Pfa              = cellSimuParams.Pfa;        % false alarm rate
    
    %% 2D-FFT resolutions and antenna array steering vector generation
    % Range estimation parameters
    nIFFT             = 2^nextpow2(nSc/uf);
    radarParams.nIFFT = nIFFT;                % 2^n closest to subcarrier numbers
    radarParams.rRes  = c/(2*(scs*uf)*nIFFT); % range resolution
    radarParams.rMax  = c/(2*(scs*uf));       % maxium unambiguous range

    % Velocity estimation parameters
    nFFT             = 2^nextpow2(nSym/ut);
    radarParams.nFFT = nFFT;                      % 2^n closest to symbol numbers
    radarParams.vRes = lambda/(2*(Tsri*ut)*nFFT); % velocity resolution
    radarParams.vMax = lambda/(2*(Tsri*ut));      % maxium unambiguous velocity

    % Antenna array orientation parameters
    txArray     = cellSimuParams.gNBSenAntenna;
    steeringVec = cell(1, nTargets); % steering vector, [1 x nTargets]

    if isa(txArray, 'parameters.baseStation.antenna.upa')  % UPA model

        spacingX = txArray.dV;                 % array X-axis element spacing
        spacingY = txArray.dH;                 % array Y-axis element spacing
        nAntsX   = txArray.nV;                 % array X-axis element number
        nAntsY   = txArray.nH;                 % array Y-axis element number
        nRxAnts  = nTxAnts;                    % Rx and Tx share the antenna array
        antAryX  = (0:1:nAntsX-1)*spacingX;    % array X-axis element indices, [1 x nRxAntsX]
        antAryY  = ((0:1:nAntsY-1)*spacingY)'; % array Y-axis element indices, [nRxAntsY x 1]

        % UPA steering vector, defined in the spheric coordinate system
        aUPA = @(ph, th, m, n)exp(2j*pi*sind(th)*(m*cosd(ph) + n*sind(ph))/lambda);
        
        for t = 1:nTargets
            upaSteeringVec = aUPA(azi(t), ele(t), antAryX, antAryY);
            steeringVec{t} = reshape(upaSteeringVec, nRxAnts, 1);
        end
    
    else                                      % ULA model

        spacing = txArray.d;                  % antenna array element spacing
        nRxAnts = nTxAnts;                    % Rx and Tx share the antenna array
        antAry  = ((0:1:nRxAnts-1)*spacing)'; % array element, [nRxAnts x 1]

        % ULA steering vector
        aULA = @(ph, m)exp(2j*pi*m*sind(ph)/lambda);

        for t = 1:nTargets
            ulaSteeringVec = aULA(azi(t), antAry);
            steeringVec{t} = ulaSteeringVec;
        end

    end

    steeringVec = cat(2, steeringVec{:}); % [nRxAnts x nTargets]
    
    radarParams.antennaType              = txArray;     % antenna array type
    radarParams.azimuthScanScale         = 360;         % azimuth scan scale, normally set to 120°, meaning [-180°, 180°]
    radarParams.elevationScanScale       = 180;         % elevation scan scale, normally set to 180°, meaning [-90°, 90°]
    radarParams.azimuthScanGranularity   = 1;           % azimuth scan granularity, in degrees
    radarParams.elevationScanGranularity = 1;           % elevation scan granularity, in degrees
    radarParams.RxSteeringVec            = steeringVec; % steering vector, [nRxAnts x nTargets]

    %% Restore target real positions' configuration
    % CFAR detection zone
    radarParams.cfarEstZone = cellSimuParams.detectionArea;

    % Sort by SNR in descending order
    radarParams.targetRealPos = struct;
    [~, idx] = sort(radarParams.snrdB, 'descend');
    [snrdB(:), r(:), v(:), ele(:), azi(:)] = deal(snrdB(idx), r(idx), v(idx), ele(idx), azi(idx));

    % Assignment
    for i = 1:nTargets
        radarParams.targetRealPos(i).ID        = i;
        radarParams.targetRealPos(i).Range     = r(i);
        radarParams.targetRealPos(i).Velocity  = v(i);
        radarParams.targetRealPos(i).Elevation = ele(i);
        radarParams.targetRealPos(i).Azimuth   = azi(i);
        radarParams.targetRealPos(i).snrdB     = snrdB(i);
    end

end

