function estResults = fft2D(radarEstParams, cfar, rxGrid, txGrid)
%2D-FFT Algorithm for Range, Velocity and Angle Estimation.
%
% Input parameters:
%
% radarEstParams: structure containing radar system parameters 
% such as the number of IFFT/FFT points, range and velocity resolutions, and angle FFT size.
%
% cfarDetector: an object implementing the Constant False Alarm Rate (CFAR) detection algorithm.
%
% CUTIdx: index of the cells under test (CUT)
%
% rxGrid: M-by-N-by-P matrix representing the received signal 
% at P antenna elements from N samples over M chirp sequences.
%
% txGrid: M-by-N-by-P matrix representing the transmitted signal 
% at P antenna elements from N samples over M chirp sequences.
%
% txArray: phased array System object™ or a NR Rectangular Panel Array (URA) System object™
%
%
% Output parameters: 
%
% estResults containing the estimated range, velocity, and angle
% for each target detected. The function also includes functions to plot results.
%
% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% Input Parameters
    [nSc,nSym,nAnts] = size(rxGrid);
    nIFFT = radarEstParams.nIFFT;
    nFFT  = radarEstParams.nFFT;

    % Range and Doppler grid
    rngGrid = ((0:nIFFT-1)*radarEstParams.rRes)';        % [0,nIFFT-1]*rRes
    dopGrid = ((-nFFT/2:nFFT/2-1)*radarEstParams.vRes)'; % [-nFFT/2,nFFT/2-1]*vRes

    % CFAR
    cfarDetector = cfar.cfarDetector2D;
    CUTIdx       = cfar.CUTIdx;
    if ~strcmp(cfarDetector.OutputFormat,'Detection index')
        cfarDetector.OutputFormat = 'Detection index';
    end

    %% Simulation params initialization
    % 3D-FFT parameters
    detections  = cell(nAnts, 1);

    % Estimated results
    estResults = struct;
    rngEst     = cell(nAnts, 1);
    velEst     = cell(nAnts, 1);

    % Angular data extracted from RDM per antenna array element
    angleData = NaN;


    %% 2D-FFT Algorithm
    % Element-wise multiplication
    channelInfo = bsxfun(@times, rxGrid, pagectranspose(pagetranspose(txGrid)));  % [nSc x nSym x nAnts]

    % Select window
    [rngWin, dopWin] = selectWindow('kaiser');

    % Generate windowed RDM
    chlInfoWindowed = channelInfo.*rngWin;                                     % Apply window to the channel info matrix
    rngIFFT         = ifftshift(ifft(chlInfoWindowed, nIFFT, 1).*sqrt(nIFFT)); % IDFT per columns, [nIFFT x nSym x nAnts]
    rngIFFTWindowed = rngIFFT.*dopWin;                                         % Apply window to the ranging matrix
    rdm             = fftshift(fft(rngIFFTWindowed, nFFT, 2)./sqrt(nFFT));     % DFT per rows, [nIFFT x nFFT x nAnts]

    % Range and velocity estimation
    for r = 1:nAnts
        % CFAR detection
        detections{r} = cfarDetector(abs(rdm(:,:,r).^2), CUTIdx);
        nDetecions = size(detections{r}, 2);

        % Range and velocity estimation
        for i = 1:nDetecions
            
            if ~isempty(detections{r})

                % Detection indices
                rngIdx = detections{r}(1,i)-1;
                velIdx = detections{r}(2,i)-nFFT/2-1;

                % Assignment
                rngEst{r} = rngIdx.*radarEstParams.rRes;
                velEst{r} = velIdx.*radarEstParams.vRes;

                % Angle steering vector, [nAnts x nDetecions]
                angleData(r,i) = rdm(rngIdx, velIdx+nFFT/2, r);

            end

            % Mean range and Doppler estimation values
            estResults(i).rngEst = mean(cat(2, rngEst{:}), 2);
            estResults(i).velEst = mean(cat(2, velEst{:}), 2);

         end
    end

    %% Plot Results
    % plot 2D-RDM (1st Rx antenna array element)
    plotRDM(1)

    % Uncomment to plot 2D-FFT spectra
    plotFFTSpectra(1,1,1)

    %% Local functions
    function [rngWin,dopWin] = selectWindow(winType)
        % Windows for sidelobe suppression: 'hamming, hann, blackman, 
        % kaiser, taylorwin, chebwin, barthannwin, gausswin, tukeywin'
        switch winType
            case 'hamming'      % Hamming window
                rngWin = repmat(hamming(nSc,3),[1 nSym]);
                dopWin = repmat(hamming(nSym,3),[1 nIFFT]).';
            case 'hann'         % Hanning window
                rngWin = repmat(hann(nSc,3),[1 nSym]);
                dopWin = repmat(hann(nSym,3),[1 nIFFT]).';
            case 'blackman'     % Blackman window
                rngWin = repmat(blackman(nSc,3),[1 nSym]);
                dopWin = repmat(blackman(nSym,3),[1 nIFFT]).';
            case 'kaiser'       % Kaiser window
                rngWin = repmat(kaiser(nSc,3),[1 nSym]);
                dopWin = repmat(kaiser(nSym,3),[1 nIFFT]).';
            case 'taylorwin'    % Taylor window
                rngWin = repmat(taylorwin(nSc,3),[1 nSym]);
                dopWin = repmat(taylorwin(nSym,3),[1 nIFFT]).';
            case 'chebwin'      % Chebyshev window
                rngWin = repmat(chebwin(nSc,3),[1 nSym]);
                dopWin = repmat(chebwin(nSym,3),[1 nIFFT]).';
            case 'barthannwin'  % Modified Bartlett-Hann window
                rngWin = repmat(barthannwin(nSc,3),[1 nSym]);
                dopWin = repmat(barthannwin(nSym,3),[1 nIFFT]).';
            case 'gausswin'     % Gaussian window
                rngWin = repmat(gausswin(nSc,3),[1 nSym]);
                dopWin = repmat(gausswin(nSym,3),[1 nIFFT]).';
            case 'tukeywin'     % Gaussian window
                rngWin = repmat(tukeywin(nSc,3),[1 nSym]);
                dopWin = repmat(tukeywin(nSym,3),[1 nIFFT]).';
            otherwise           % Default to Hamming window
                rngWin = repmat(hamming(nSc,3),[1 nSym]);
                dopWin = repmat(hamming(nIFFT,3),[1 nSym]).';
        end
    end

    function plotRDM(aryIdx)
    % plot 2D range-Doppler(velocity) map
        figure('Name','2D RDM')

        h = imagesc(dopGrid,rngGrid,mag2db(abs(rdm(:,:,aryIdx))));
        h.Parent.YDir = 'normal';
        colorbar

        title('Range-Doppler Map')
        xlabel('Radial Velocity (m/s)')
        ylabel('Range (m)')

    end

    function plotFFTSpectra(fastTimeIdx,slowTimeIdx,aryIdx)
    % Plot 3D-FFT spectra (in dB)  
        figure('Name','2D FFT Results')
     
        t = tiledlayout(2,1,'TileSpacing','compact');
        title(t,'2D-FFT Estimation')
        ylabel(t,'FFT Spectra (dB)')

        % plot range spectrum 
        nexttile(1)
        rngIFFT     = abs(ifftshift(rngIFFT(:,slowTimeIdx,aryIdx)));
        rngIFFTNorm = rngIFFT./max(rngIFFT);
        rngIFFTdB   = mag2db(rngIFFTNorm);
        plot(rngGrid,rngIFFTdB,'LineWidth',1);
        title('Range Estimation')
        xlabel('Range (m)')
        xlim([0 500])
        grid on

        % plot Doppler/velocity spectrum 
        nexttile(2)    
        % DFT per rows, [nSc x nFFT x nAnts]
        velFFT     = abs(fftshift(fft(chlInfoWindowed(fastTimeIdx,:,aryIdx),nFFT,2)./sqrt(nFFT)));
        velFFTNorm = velFFT./max(velFFT);
        velFFTdB   = mag2db(velFFTNorm);
        plot(dopGrid,velFFTdB,'LineWidth',1);
        title('Velocity(Doppler) Estimation')
        xlabel('Radial Velocity (m/s)')
        xlim([-50 50])
        grid on

    end
    
end
