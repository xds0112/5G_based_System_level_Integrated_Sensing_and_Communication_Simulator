function [L, aziEst, eleEst] = music(numDets, radarEstParams, Ra)
%MUSIC Multiple signal classification (MUSIC) algorithm for DoA estimation
% numDets: Number of detections, which can be an integer or left empty ([]).
%           When set to [], this function will automatically calculate the number
%           of detections by invoking the [determineNumTargets] function.
% 
%  Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    % Antenna array    
    array = radarEstParams.antennaType;
    d = .5;  % the ratio of element spacing to wavelength, normally set to 0.5

    % Eigenvalue decomposition
    % Ua: orthogonal eigen matrix, 
    % Sa: real-value eigenvalue diagonal matrix in descending order
    % Va: a vector taking the diagonal values of Sa
    % L: The number of targets in the DoA of interest
    [Ua, Sa] = eig(Ra);
    Va       = real(diag(Sa));
    if isempty(numDets)
        L = determineNumTargets(Va);
    else
        L = numDets;
    end
    [~, Ia]  = sort(Va, 'descend');
    Ua       = Ua(:,Ia);
    Uan      = Ua(:,L+1:end);
    Uann     = Uan*Uan';

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
    
        % MUSIC spectrum
        Pmusic = zeros(1, aSteps);
        for e = 1:eSteps
            for a = 1:aSteps
                scanElevation = (e-1)*eGranularity - eMax/2;
                scanAzimuth   = (a-1)*aGranularity - aMax/2;
                aa = aUPA(scanAzimuth, scanElevation, mm, nn);
                aa = reshape(aa, nAntsX*nAntsY, 1);
                Pmusic(e,a) = 1./(aa'*Uann*aa + eps(1));
            end
        end
        
        % Normalization
        Pmusic     = -abs(Pmusic);
        PmusicNorm = Pmusic./max(Pmusic);
        PmusicdB   = mag2db(PmusicNorm);

        % Plot
        %plot2DAngularSpectrum

        % Assignment
        [ele, azi] = tools.find2DPeaks(PmusicdB, L);
        eleEst = (ele-1)*eGranularity-eMax/2;
        aziEst = (azi-1)*aGranularity-aMax/2;

    else % ULA model

        % Array parameters
        nAnts           = array.numElements;                      % number of antenna elements
        scanGranularity = radarEstParams.azimuthScanGranularity;  % beam scan granularity, in degree
        aMax            = radarEstParams.azimuthScanScale;        % beam scan scale, in degree
        aSteps          = floor((aMax+1)/scanGranularity);        % beam scan steps

        % ULA steering vector
        aULA = @(ph, m)exp(-2j*pi*m*d*sind(ph));
        nn = (0:1:nAnts-1)';
    
        % MUSIC spectrum
        Pmusic = zeros(1, aSteps);
        for a = 1:aSteps
            scanAngle = (a-1)*scanGranularity - aMax/2;
            aa        = aULA(scanAngle, nn);
            Pmusic(a) = 1./(aa'*Uann*aa + eps(1));
        end
        
        % Normalization
        Pmusic     = abs(Pmusic);
        PmusicNorm = Pmusic./max(Pmusic);
        PmusicdB   = mag2db(PmusicNorm);

        % Plot
        plotAngularSpectrum
    
        % Assignment
        [~, azi] = findpeaks(PmusicdB, 'NPeaks', L, 'SortStr', 'descend');
        aziEst = (azi-1)*scanGranularity-aMax/2;
        eleEst = NaN([1, numel(aziEst)]);

    end

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

    function plot2DAngularSpectrum()
    % Plot 2D angular spectrum (in dB)  
        figure('Name', '2D Angular Spectrum')

        % Angular grid for plotting
        aziGrid = linspace(-aMax/2, aMax/2, aSteps); % [-aMax/2, aMax/2]
        eleGrid = linspace(-eMax/2, eMax/2, eSteps); % [-eMax/2, eMax/2]

        % plot DoA spectrum 
        imagesc(aziGrid, eleGrid, PmusicdB)

        title('DoA Estimation using MUSIC Method')
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
        plot(aziGrid, PmusicdB, 'LineWidth', 1);

        title('DoA Estimation using MUSIC Method')
        ylabel('Angular Spectrum (dB)')
        xlabel('Azimuth (°)')
        xlim([-aMax/2 aMax/2])
        grid on

    end

end

