function estResults = music2D(rdrEstParams, bsParams, rxGrid, txGrid)
%MUSIC 
%  Multiple signal classification (MUSIC) algorithm for DoA, range 
% and velocity estimation.
%
% Input parameters:
%
% radarEstParams: structure containing radar system parameters 
% such as the number of IFFT/FFT points, range and velocity resolutions, and angle FFT size.
%
% rxGrid: M-by-N-by-P matrix representing the received signal 
% at P antenna elements from N samples over M chirp sequences.
%
% txGrid: M-by-N-by-P matrix representing the transmitted signal 
% at P antenna elements from N samples over M chirp sequences.
%
% gNBParams: structure containing gNB system parameters 
%
%
% Output parameters: 
%
% estResults containing the estimated range, velocity, and angle
% for each target detected. The function also includes functions to plot results.
%
% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.
%
% See also: X. Chen et al., "Multiple Signal Classification Based Joint 
% Communication and Sensing System," in IEEE Transactions on Wireless 
% Communications, 2023.

    %% Parameters
    [nSc, nSym, nAnts] = size(rxGrid);                % OFDM rxGrid
    scs    = bsParams.scs*1e3;                        % subcarrier spacing
    c      = physconst('LightSpeed');                 % light speed
    fc     = rdrEstParams.fc;                         % carrier frequency
    lambda = c/fc;                                    % wavelength
    T      = rdrEstParams.Tsri;                       % duration time of a whole OFDM symbol

    % MUSIC spectra configuration
    rMax         = rdrEstParams.cfarEstZone(1,2);     % in meters
    vMax         = rdrEstParams.cfarEstZone(2,2)*2;   % in meters per second
    rGranularity = .5;                                % range search granularity, in meters
    vGranularity = .5;                                % velocity search granularity, in meters per second
    rSteps       = floor((rMax+1)/rGranularity);      % range searching steps
    vSteps       = floor((vMax+1)/vGranularity);      % velocity searching steps
    Prmusic      = zeros(1, rSteps);                  % range spectrum
    Pvmusic      = zeros(1, vSteps);                  % velocity spectrum
    rngGrid      = linspace(0, rMax-1, rSteps);       % range grid for plotting
    velGrid      = linspace(-vMax/2, vMax/2, vSteps); % velocity grid for plotting
    
    % Estimated results
    estResults = struct;

    %% DoA Estimation
    % Array correlation matrix
    rxGridReshaped = reshape(rxGrid, nSc*nSym, nAnts)'; % [nAnts x nSc*nSym]
    Ra = rxGridReshaped*rxGridReshaped'./(nSc*nSym);    % [nAnts x nAnts]

    % MUSIC method
    [L, aziEst, eleEst] = sensing.estimation.doaEstimation.music([], rdrEstParams, Ra);
    estResults.aziEst = aziEst;
    estResults.eleEst = eleEst;

    %% Range and Doppler Estimation
    % Element-wise multiplication
    channelInfo = bsxfun(@times, rxGrid, pagectranspose(pagetranspose(txGrid))); % [nSc x nSym x nAnts]
    H = channelInfo(:,:,1);  % [nSc x nSym]

    % Range and Doppler correlation matrices
    Rr = H*H'./nSym;         % H*(hermitian transpose(H)),  [nSc x nSc]
    Rv = H.'*conj(H)./nSc;   % transpose(H)*conjugate(H), [nSym x nSym]

    % Eigenvalue decomposition
    % Ur,Uv: orthogonal eigen matrices,
    % Sr,Sv: real-value eigenvalue diagonal matrices in descending order
    [Ur, Sr] = eig(Rr);
    Vr       = real(diag(Sr));
    [~, Ir]  = sort(Vr, 'descend');
    Ur       = Ur(:,Ir);
    Urn      = Ur(:,L+1:end);
    Urnn     = Urn*Urn';

    [Uv, Sv] = eig(Rv);
    Vv       = real(diag(Sv));
    [~, Iv]  = sort(Vv, 'descend');
    Uv       = Uv(:,Iv);
    Uvn      = Uv(:,L+1:end);
    Uvnn     = Uvn*Uvn';

    % Range and Doppler steering vector
    rSteeringVec = @(r, n)exp(-2j*pi*scs*2*r*n/c);
    vSteeringVec = @(v, m)exp(2j*pi*T*2*v*m/lambda);
    nn = (0:1:nSc-1)';
    mm = (0:1:nSym-1)';

    % Range and Doppler spectra
    for r = 1:rSteps
        searchRange = (r-1)*rGranularity;
        ar          = rSteeringVec(searchRange, nn);
        Prmusic(r)  = 1./(ar'*Urnn*ar);
    end

    for v = 1:vSteps
        searchVelocity = (v-1)*vGranularity-vMax/2;
        av             = vSteeringVec(searchVelocity, mm);
        Pvmusic(v)     = 1./(av'*Uvnn*av);
    end
    
    % Normalization
    Prmusic     = abs(Prmusic);
    PrmusicNorm = Prmusic./max(Prmusic);
    PrmusicdB   = mag2db(PrmusicNorm);

    Pvmusic     = abs(Pvmusic);
    PvmusicNorm = Pvmusic./max(Pvmusic);
    PvmusicdB   = mag2db(PvmusicNorm);
    
    % Assignment
    [~, rng] = findpeaks(PrmusicdB, 'NPeaks', L, 'SortStr', 'descend');
    [~, vel] = findpeaks(PvmusicdB, 'NPeaks', L, 'SortStr', 'descend');
    estResults.rngEst = (rng-1)*rGranularity;
    estResults.velEst = (vel-1)*vGranularity-vMax/2;

    %% Plots
    plotMUSICSpectra;

    %% Local Functions
    function plotMUSICSpectra
    % Plot MUSIC spectra
        figure('Name', 'MUSIC Estimation')
        
        t = tiledlayout(2, 1, 'TileSpacing', 'compact');
        title(t, 'MUSIC Estimation')
        ylabel(t, 'MUSIC Spectra (dB)')

        % plot range estimation 
        nexttile(1)
        plot(rngGrid, PrmusicdB, 'LineWidth', 1)
        title('Range Estimation')
        xlabel('Range (m)')
        xlim([0 rMax])
        grid on

        % plot doppler/velocity estimation 
        nexttile(2)
        plot(velGrid, PvmusicdB, 'LineWidth', 1)
        title('Velocity(Doppler) Estimation')
        xlabel('Radial Velocity (m/s)')
        xlim([-vMax/2 vMax/2])
        grid on

    end

end

