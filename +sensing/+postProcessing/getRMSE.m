function radarEstRMSE = getRMSE(radarEstResults, radarEstParams)
% Calculate the root mean squre error (RMSE) of estimation results
%
% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.
    
    %% Parameters
    % The estimation result is seen as a non-detection
    % when the corresponding error exceeds the threshold value.
    rngDetThreshold = radarEstParams.rRes;
    
    % antenna array type
    isUPA = isa(radarEstParams.antennaType, 'phased.NRRectangularPanelArray'); 

    %% Calculate errors
    % real & estimated values
    rngReal = extractfield(radarEstParams.tgtRealPos, 'Range')';
    velReal = extractfield(radarEstParams.tgtRealPos, 'Velocity')';
    eleReal = extractfield(radarEstParams.tgtRealPos, 'Elevation')';
    aziReal = extractfield(radarEstParams.tgtRealPos, 'Azimuth')';
    
    rngEst = extractfield(radarEstResults, 'rngEst');
    velEst = extractfield(radarEstResults, 'velEst');
    if isUPA
        eleEst = extractfield(radarEstResults, 'eleEst');
        aziEst = extractfield(radarEstResults, 'aziEst');
    else
        aziEst = extractfield(radarEstResults, 'aziEst');
    end
    
     if isempty(rngEst)
        disp('No target is detected')
        radarEstRMSE = NaN;
        return
    end
    
    % Initialize error variables
    numDets = numel(rngEst);
    [rngError, velError, eleError, aziError] = deal(NaN(1, numDets));
    [rngRMSE, velRMSE, eleRMSE, aziRMSE]     = deal(NaN(1, numDets));
    
    for r = 1:numDets
        detIdx = find(abs(rngReal - rngEst(r)) < rngDetThreshold);
    
        if numel(detIdx) >= 1
            % rng detection matches or vel detection matches
            rngError(r) = rngReal(detIdx(1)) - rngEst(r);
            velError(r) = velReal(detIdx(1)) - velEst(r);
            if isUPA
                eleError(r) = eleReal(detIdx(1)) - eleEst(r);
            end
            aziError(r) = aziReal(detIdx(1)) - aziEst(r);
        end

        % Calculate RMSEs for each detection
        rngRMSE(r) = sqrt(mean(rmmissing(rngError(r)).^2)); % RMSE for rngError
        velRMSE(r) = sqrt(mean(rmmissing(velError(r)).^2)); % RMSE for vError
        eleRMSE(r) = sqrt(mean(rmmissing(eleError(r)).^2)); % RMSE for eleError (if applicable)
        aziRMSE(r) = sqrt(mean(rmmissing(aziError(r)).^2)); % RMSE for aziError

    end

    %% Calculate RMSEs
    radarEstRMSE = struct;
    
    % Store RMSE values in a struct
    radarEstRMSE.rngRMSE = rngRMSE;
    radarEstRMSE.velRMSE = velRMSE;
    radarEstRMSE.eleRMSE = eleRMSE;
    radarEstRMSE.aziRMSE = aziRMSE;

end
