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

    %% Parameters
    [nSc, nSym, nAnts] = size(rxGrid);
    nIFFT = radarEstParams.nIFFT;
    nFFT  = radarEstParams.nFFT;

    %% 2D-FFT Processing
    % Element-wise division
    channelInfo = bsxfun(@times, rxGrid, pagectranspose(pagetranspose(txGrid)));  % [nSc x nSym x nAnts]

    % Select window
    [rngWin, dopWin] = selectWindow('kaiser', nSc, nIFFT, nSym);

    % Generate windowed RDM
    chlInfo = channelInfo.*rngWin;                             % apply window to the channel info matrix
    rngIFFT = ifftshift(ifft(chlInfo, nIFFT, 1).*sqrt(nIFFT)); % IDFT per columns, [nIFFT x nSym x nAnts]
    rngIFFT = rngIFFT.*dopWin;                                 % apply window to the ranging matrix
    rdm     = fftshift(fft(rngIFFT, nFFT, 2)./sqrt(nFFT));     % DFT per rows, [nIFFT x nFFT x nAnts]

    % Range and velocity estimation
    % CFAR detection
    cfarDetector = cfar.cfarDetector2D;
    CUTIdx       = cfar.CUTIdx;
    if ~strcmp(cfarDetector.OutputFormat,'Detection index')
        cfarDetector.OutputFormat = 'Detection index';
    end

    % Initialize arrays to store rngEst and velEst values
    [allRngEst, allVelEst] = deal([]);

    for r = 1:nAnts

        rdResponse  = abs(rdm(:,:,r)).^2;
        [m,im]=max(rdResponse);
        [m2,im2]=max(m);
        x=im(im2);
        y=im2;
%         detections  = cfarDetector(rdResponse, CUTIdx);
%         detections  = rmmissing(detections, 2);
        detections = [x;y];
        nDetections = size(detections, 2);
    
        % Restore estimation values
        [rngEst, velEst, peaks] = deal(zeros(1, nDetections));
    
        if ~isempty(detections)
    
            for i = 1:nDetections
    
                % Peak levels
                peaks(i) = rdResponse(detections(1,i), detections(2,i));
    
                % Detection indices
                rngIdx = detections(1,i)-1;
                velIdx = detections(2,i)-nFFT/2-1;
    
                % Range and velocity estimation
                rngEst(i) = rngIdx.*radarEstParams.rRes;
                velEst(i) = velIdx.*radarEstParams.vRes;
                
            end
    
        end

        % Sort estimations by descending order
        [~, idx] = sort(peaks, 'descend');
%         if isempty(idx)
            
            [rngEst(:), velEst(:)] = deal(rngEst(idx), velEst(idx));

            % collect rngEst and velEst values
            allRngEst = cat(2, allRngEst, rngEst);
            allVelEst = cat(2, allVelEst, velEst);

%         else
%             idx = idx(1:size(radarEstParams.range,1));
%             % Restore real values
%             [rngEstreal, velEstreal] = deal(zeros(1, size(radarEstParams.range,1)));
%             [rngEstreal(:), velEstreal(:)] = deal(rngEst(idx), velEst(idx));
% 
%             % collect rngEst and velEst values
%             allRngEst = cat(2, allRngEst, rngEstreal);
%             allVelEst = cat(2, allVelEst, velEstreal);
% 
%         end

    end
   
    % Use the unique function to remove duplicates from allRngEst and allVelEst
    %[uniqueRngEst, uniqueVelEst] = deal(unique(allRngEst, 'stable'), unique(allVelEst, 'stable'));
    [uniqueRngEst, uniqueVelEst] = deal(max(allRngEst), max(allVelEst));

    % Store the unique estimation values in a single structure
    estResults = struct('rngEst', uniqueRngEst, 'velEst', uniqueVelEst);

    %% DoA Estimation
    % Array correlation matrix
    rxGridReshaped = reshape(rxGrid, nSc*nSym, nAnts)'; % [nAnts x nSc*nSym]
    Ra = rxGridReshaped*rxGridReshaped'./(nSc*nSym);    % [nAnts x nAnts]

    % MUSIC method
    numDets = numel(uniqueRngEst);
    [~, aziEst, eleEst] = sensing.estimation.doaEstimation.music(numDets, radarEstParams, Ra);

    % Assignment
    estResults.aziEst = aziEst;
    estResults.eleEst = eleEst;

    %% Plot Results
    % plot 2D-RDM (1st Rx antenna array element)
    %plotRDM(1)

    % Uncomment to plot 2D-FFT spectra
    % plotFFTSpectra(1,1,1)

    %% Local functions
    function [rngWin, dopWin] = selectWindow(winType, nSc, nIFFT, nSym)
        % Default to Hamming window
        rngWin = [];
        dopWin = [];
        
        % Define window functions and their parameters
        windows = struct(...
            'hamming', @(n) hamming(n), ...
            'hann', @(n) hann(n), ...
            'blackman', @(n) blackman(n), ...
            'kaiser', @(n) kaiser(n, 3), ...
            'taylorwin', @(n) taylorwin(n, 4, -30), ...
            'chebwin', @(n) chebwin(n, 50), ...
            'barthannwin', @(n) barthannwin(n), ...
            'gausswin', @(n) gausswin(n, 2.5), ...
            'tukeywin', @(n) tukeywin(n, 0.5) ...
        );
    
        % Check if the specified window type exists in the 'windows' struct
        if isfield(windows, winType)
            windowFunc = windows.(winType);
            rngWin = repmat(windowFunc(nSc), [1 nSym]);
            dopWin = repmat(windowFunc(nIFFT), [1 nSym]);
        end
    end

    function plotRDM(aryIdx)
    % plot 2D range-Doppler(velocity) map
        figure('Name','2D RDM')

        % Range and Doppler grid for plotting
        rngGrid = ((0:nIFFT-1)*radarEstParams.rRes)';        % [0, nIFFT-1]*rRes
        dopGrid = ((-nFFT/2:nFFT/2-1)*radarEstParams.vRes)'; % [-nFFT/2, nFFT/2-1]*vRes

        rdmdB = mag2db(abs(rdm(:,:,aryIdx)));
        h = imagesc(dopGrid, rngGrid, rdmdB);
        h.Parent.YDir = 'normal';

        title('Range-Doppler Map')
        xlabel('Radial Velocity (m/s)')
        ylabel('Range (m)')

    end

    function plotFFTSpectra(fastTimeIdx, slowTimeIdx, aryIdx)
    % Plot 2D-FFT spectra (in dB)  
        figure('Name', '2D FFT Results')
     
        t = tiledlayout(2, 1, 'TileSpacing', 'compact');
        title(t, '2D-FFT Estimation')
        ylabel(t, 'FFT Spectra (dB)')

        % Range and Doppler grid for plotting
        rngGrid = ((0:nIFFT-1)*radarEstParams.rRes)';        % [0, nIFFT-1]*rRes
        dopGrid = ((-nFFT/2:nFFT/2-1)*radarEstParams.vRes)'; % [-nFFT/2, nFFT/2-1]*vRes
        
        % plot range spectrum 
        nexttile(1)
        rngIFFTPlot = abs(ifftshift(rngIFFT(:, slowTimeIdx, aryIdx)));
        rngIFFTNorm = rngIFFTPlot./max(rngIFFTPlot);
        rngIFFTdB   = mag2db(rngIFFTNorm);
        plot(rngGrid, rngIFFTdB, 'LineWidth', 1);
        title('Range Estimation')
        xlabel('Range (m)')
        grid on

        % plot Doppler/velocity spectrum 
        nexttile(2)    
        % DFT per rows, [nSc x nFFT x nAnts]
        velFFTPlot = abs(rdm(fastTimeIdx, :, aryIdx));
        velFFTNorm = velFFTPlot./max(velFFTPlot);
        velFFTdB   = mag2db(velFFTNorm);
        plot(dopGrid, velFFTdB, 'LineWidth', 1);
        title('Velocity(Doppler) Estimation')
        xlabel('Radial Velocity (m/s)')
        grid on

    end
    
end
