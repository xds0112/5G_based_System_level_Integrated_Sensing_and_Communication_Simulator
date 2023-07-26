function estResults = music(rdrEstParams, bsParams, rxGrid, txGrid)
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
    [nSc, nSym, nAnts] = size(rxGrid);               % OFDM receiving grid
    scs    = bsParams.scs*1e3;                       % subcarrier spacing
    c      = physconst('LightSpeed');                % light speed
    fc     = rdrEstParams.fc;                        % carrier frequency
    lambda = c/fc;                                   % wavelength
    T      = rdrEstParams.Tsri;                      % duration time of a whole OFDM symbol
    d      = bsParams.txArray.ElementSpacing/lambda; % antenna array element spacing, normally set to 0.5

    % MUSIC spectra configuration
    aMax    = 180;              % in degrees
    rMax    = 500;              % in meters
    vMax    = 100;              % in meters per second
    Pamusic = zeros(1, aMax+1); % azimuth spectrum
    Prmusic = zeros(1, rMax+1); % range spectrum
    Pvmusic = zeros(1, vMax+1); % velocity spectrum
    aziGrid = -aMax/2:aMax/2;   % azimuth grid
    rngGrid = 1:rMax+1;         % range grid
    velGrid = -vMax/2:vMax/2;   % velocity grid
    
    % Estimated results
    estResults = struct;

    % Antenna array type
    if isa(bsParams.txArray,'phased.NRRectangularPanelArray') % UPA model is not supported yet
        disp('MUSIC algorithm is not supported for UPA model')
        return
    end

    %% DoA Estimation
    % Angle autocorrelation matrix
    rxGridReshaped = reshape(rxGrid, nSc*nSym, nAnts)'; % [nAnts x nSc*nSym]
    Ra = rxGridReshaped*rxGridReshaped'./(nSc*nSym);    % [nAnts x nAnts]

    % Eigenvalue decomposition
    % Ua: orthogonal eigen matrix, 
    % Sa: real-value eigenvalue diagonal matrix in descending order
    % Va: a vector taking the diagonal values of Sa
    % L: The number of targets in the DoA of interest
    [Ua,Sa] = eig(Ra);
    Va      = real(diag(Sa));
    L       = determineNumTargets(Va);
    [~,Ia]  = sort(Va,'descend');
    Ua      = Ua(:,Ia);
    Uan     = Ua(:,L+1:end);

    % Angle spectrum
    for a = 1:aMax+1
        aa         = exp(-2j.*pi.*sind(a-aMax/2-1).*d.*(0:1:nAnts-1)).';  % angle steering vector
        Pamusic(a) = 1./((aa'*Uan)*(Uan'*aa));
    end
    
    % Normaliztion
    Pamusic     = abs(Pamusic);
    PamusicNorm = Pamusic./max(Pamusic);
    PamusicdB   = mag2db(PamusicNorm);

    % Assignment
    [~,azi] = findpeaks(PamusicdB, 'Threshold', 5, 'SortStr', 'descend');
    estResults.azi = azi-aMax/2-1;

    %% Range and Doppler Estimation
    % Element-wise multiplication
    channelInfo = bsxfun(@times, rxGrid, pagectranspose(pagetranspose(txGrid))); % [nSc x nSym x nAnts]
    H = channelInfo(:,:,1);  % [nSc x nSym]

    % Range and Doppler autocorrelation matrices
    Rr = H*H'./nSym;       % H*(hermitian transpose(H)),  [nSc x nSc]
    Rv = H.'*conj(H)./nSc; % transpose(H)*conjugate(H), [nSym x nSym]

    % Eigenvalue decomposition
    % Ur,Uv: orthogonal eigen matrices,
    % Sr,Sv: real-value eigenvalue diagonal matrices in descending order
    [Ur,Sr] = eig(Rr);
    Vr      = real(diag(Sr));
    [~,Ir]  = sort(Vr,'descend');
    Ur      = Ur(:,Ir);
    Urn     = Ur(:,L+1:end);

    [Uv,Sv] = eig(Rv);
    Vv      = real(diag(Sv));
    [~,Iv]  = sort(Vv,'descend');
    Uv      = Uv(:,Iv);
    Uvn     = Uv(:,L+1:end);

    % Range and Doppler spectra
    for r = 1:rMax+1
        ar         = exp(-2j.*pi.*scs.*2.*r.*(0:1:nSc-1)./c).';  % range steering vector
        Prmusic(r) = 1./((ar'*Urn)*(Urn'*ar));
    end

    for v = 1:vMax+1
        av         = exp(2j.*pi.*T.*2.*(v-vMax/2-1).*(0:1:nSym-1)./lambda).';  % velocity steering vector
        Pvmusic(v) = 1./((av'*Uvn)*(Uvn'*av));
    end
    
    % Normaliztion
    Prmusic     = abs(Prmusic);
    PrmusicNorm = Prmusic./max(Prmusic);
    PrmusicdB   = mag2db(PrmusicNorm);

    Pvmusic     = abs(Pvmusic);
    PvmusicNorm = Pvmusic./max(Pvmusic);
    PvmusicdB   = mag2db(PvmusicNorm);
    
    % Assignment
    [~,rng] = findpeaks(PrmusicdB,'Threshold',1e-2,'SortStr','descend');
    [~,vel] = findpeaks(PvmusicdB,'Threshold',2,'SortStr','descend');
    estResults.rng = rng;
    estResults.vel = vel-vMax/2-1;

    %% Plots
    plotMUSICSpectra;

    %% Local Functions
    function L = determineNumTargets(V)
    % Determine the number of detected targets

        % [∆v]i = [v]i - [v]i+1
        deltaV = -diff(V);

        % The mean value of the latter half of ∆v
        n = length(deltaV);
        halfMeanV = mean(deltaV(ceil((n+1)./2):1:end));

        % ε, the parameter used to avoid false 
        % detection cause by a small error
        epsilon = 1;
        % L = argmax [∆v] > (1 + ε)*halfMeanV
        [~,L] = max(deltaV - (1+epsilon).*halfMeanV);
        
    end

    function plotMUSICSpectra
    % Plot MUSIC spectra
        figure('Name', 'MUSIC Estimation')
        
        t = tiledlayout(3, 1, 'TileSpacing', 'compact');
        title(t, 'MUSIC Estimation')
        ylabel(t, 'MUSIC Spectra (dB)')

        % plot DoA estimation
        nexttile(1)
        plot(aziGrid, PamusicdB, 'LineWidth', 1)
        title('DoA Estimation')
        xlabel('Azimuth (°)')
        xlim([-aMax/2 aMax/2])
        grid on

        % plot range estimation 
        nexttile(2)
        plot(rngGrid, PrmusicdB, 'LineWidth', 1)
        title('Range Estimation')
        xlabel('Range (m)')
        xlim([0 rMax])
        grid on

        % plot doppler/velocity estimation 
        nexttile(3)
        plot(velGrid, PvmusicdB, 'LineWidth', 1)
        title('Velocity(Doppler) Estimation')
        xlabel('Radial Velocity (m/s)')
        xlim([-vMax/2 vMax/2])
        grid on

    end

end

