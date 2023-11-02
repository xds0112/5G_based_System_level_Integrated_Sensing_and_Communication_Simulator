function [aziEst, eleEst] = mvdrBF(numDets, radarEstParams, Ra)
%MVDRBF Minimum variance distortionless response (MVDR) beamformer for DoA estimation
%
% numDets: Number of detections, integer.
%
%  Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    % Antenna array    
    array = radarEstParams.antennaType;
    d = .5;  % the ratio of element spacing to wavelength, normally set to 0.5

    if isa(array, 'parameters.baseStation.antenna.upa') % UPA model

        % Array parameters
        nAntsX       = array.nV;                                % number of X-axis elements
        nAntsY       = array.nH;                                % number of Y-axis elements
        aGranularity = radarEstParams.azimuthScanGranularity;   % azimuth scan granularity, in degree
        eGranularity = radarEstParams.elevationScanGranularity; % elevation scan granularity, in degree
        aMax         = radarEstParams.azimuthScanScale;         % azimuth scan scale, in degree
        eMax         = radarEstParams.elevationScanScale;       % elevation scan scale, in degree
        aSteps       = floor((aMax+1)/aGranularity);            % azimuth scan steps
        eSteps       = floor((eMax+1)/eGranularity);            % elevation scan steps
        
        % UPA steering vector
        aUPA = @(ph, th, m, n)exp(-2j*pi*sind(th)*(m*d*cosd(ph) + n*d*sind(ph)));
        mm = 0:1:nAntsX-1;
        nn = (0:1:nAntsY-1)';
        
        % Minimum variance distortionless response (MVDR) beamforming method  
        Pmvdr = zeros(eSteps, aSteps);
        for e = 1:eSteps
            for a = 1:aSteps
                scanElevation = (e-1)*eGranularity - eMax/2;
                scanAzimuth   = (a-1)*aGranularity - aMax/2;
                aa = aUPA(scanAzimuth, scanElevation, mm, nn);
                aa = reshape(aa, nAntsX*nAntsY, 1);
                Pmvdr(e,a) = 1./(aa'*Ra^-1*aa + eps(1));
            end
        end
        
        % Normalization
        Pmvdr     = -abs(Pmvdr);
        PmvdrNorm = Pmvdr./max(Pmvdr);
        PmvdrdB   = mag2db(PmvdrNorm);

        % Plot
        plot2DAngularSpectrum
  
        % Assignment
        [ele, azi] = tools.find2DPeaks(PmvdrdB, numDets);
        eleEst = (ele-1)*eGranularity-eMax/2;
        aziEst = (azi-1)*aGranularity-aMax/2;
       
    else

        % Array parameters
        nAnts           = array.numElements;                      % number of antenna elements
        scanGranularity = radarEstParams.azimuthScanGranularity;  % beam scan granularity, in degree
        aMax            = radarEstParams.azimuthScanScale;        % beam scan scale, in degree
        aSteps          = floor((aMax+1)/scanGranularity);        % beam scan steps

        % ULA steering vector
        aULA = @(ph, m)exp(-2j*pi*m*d*sind(ph));
        nn = (0:1:nAnts-1)';
        
        % Minimum variance distortionless response (MVDR) beamforming method  
        Pmvdr = zeros(1, aSteps);
        for a = 1:aSteps
            scanAngle = (a-1)*scanGranularity - aMax/2;
            aa        = aULA(scanAngle, nn);
            Pmvdr(a)  = 1./(aa'*Ra^-1*aa + eps(1));
        end
        
        % Normalization
        Pmvdr     = abs(Pmvdr);
        PmvdrNorm = Pmvdr./max(Pmvdr);
        PmvdrdB   = mag2db(PmvdrNorm);

        % Plot
        plotAngularSpectrum
        
        % DoA estimation
        [~, azi] = findpeaks(PmvdrdB, 'NPeaks', numDets, 'SortStr', 'descend');
        aziEst = (azi-1)*scanGranularity-aMax/2;
        eleEst = NaN([1, numel(aziEst)]);

    end

    %% Local Functions
    function plot2DAngularSpectrum()
    % Plot 2D angular spectrum (in dB)  
        figure('Name', '2D Angular Spectrum')

        % Angular grid for plotting
        aziGrid = linspace(-aMax/2, aMax/2, aSteps); % [-aMax/2, aMax/2]
        eleGrid = linspace(-eMax/2, eMax/2, eSteps); % [-eMax/2, eMax/2]

        % plot DoA spectrum 
        imagesc(aziGrid, eleGrid, PmvdrdB)

        title('DoA Estimation using MVDR Beamforming Method')
        ylabel('Elevation (°)')
        xlabel('Azimuth (°)')
        ylim([-eMax/2 eMax/2])
        xlim([-aMax/2 aMax/2])
        grid on

        end

    function plotAngularSpectrum()
    % Plot angular spectrum (in dB)  
        figure('Name', 'Angular Spectrum')

        % Angular grid for plotting
        aziGrid = linspace(-aMax/2, aMax/2, aSteps); % [-aMax/2, aMax/2]

        % plot DoA spectrum 
        plot(aziGrid, PmvdrdB, 'LineWidth', 1);

        title('DoA Estimation using MVDR Beamforming Method')
        ylabel('Angular Spectrum (dB)')
        xlabel('Azimuth (°)')
        xlim([-aMax/2 aMax/2])
        grid on

    end

end
