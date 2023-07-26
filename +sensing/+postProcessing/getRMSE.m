function radarEstRMSE = getRMSE(radarEstResults, radarEstParams)
% Calculate RMSE of Radar Estimation Results

% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

   %%
   % The estimation result is seen as a non-detection
   % when the corresponding error exceeds the threshold value.
   rngDetThreshold = radarEstParams.rRes;
   velDetThreshold = radarEstParams.vRes; 

   isUPA = 0; 
   % antenna array type
   if isfield(radarEstResults,'eleEst') % UPA
       isUPA = 1;
   end

   %%
   % real & estimated values
        rngReal = extractfield(radarEstParams.tgtRealPos,'Range')';
        velReal = extractfield(radarEstParams.tgtRealPos,'Velocity')';
        eleReal = extractfield(radarEstParams.tgtRealPos,'Elevation')';
        aziReal = extractfield(radarEstParams.tgtRealPos,'Azimuth')';

        rngEst = extractfield(radarEstResults,'rngEst');
        velEst = extractfield(radarEstResults,'velEst');
        if isUPA
            eleEst = extractfield(radarEstResults,'eleEst');
            aziEst = extractfield(radarEstResults,'aziEst');
        else
            aziEst = extractfield(radarEstResults,'aziEst');
        end

        if isempty(rngEst)
            disp('No target is detected, please alter the CFAR configuration')
            radarEstRMSE = NaN;
            return
        else
            % error values
            for r = 1:size(rngEst,1)

                detIdx = find(abs(rngReal - rngEst(r)) < rngDetThreshold);

                if size(detIdx,1) == 1 % rng detection matches
                    rError(r) = rngReal(detIdx) - rngEst(r);
                    vError(r) = velReal(detIdx) - velEst(r);
                    if isUPA
                        eleError(r) = eleReal(detIdx) - eleEst(r);
                        aziError(r) = aziReal(detIdx) - aziEst(r);
                    else
                        aziError(r) = aziReal(detIdx) - aziEst(r);
                    end

                elseif size(detIdx,1) > 1 % vel detection matches

                    newIdx = find(abs(velReal(detIdx) - velEst(r)) < velDetThreshold);

                    if ~isempty(newIdx)
                        rError(r) = rngReal(detIdx(newIdx)) - rngEst(r);
                        vError(r) = velReal(detIdx(newIdx)) - velEst(r);
                        if isUPA
                            eleError(r) = eleReal(detIdx(newIdx)) - eleEst(r);
                            aziError(r) = aziReal(detIdx(newIdx)) - aziEst(r);
                        else
                            aziError(r) = aziReal(detIdx(newIdx)) - aziEst(r);
                        end 
                    else
                        [rError(r),vError(r),eleError(r),aziError(r)] = deal(NaN);
                    end

                else % rng & vel detection fail to match
                
                    [rError(r),vError(r),eleError(r),aziError(r)] = deal(NaN);

                end
            end
        end

   %% RMSE
   radarEstRMSE = struct;

   % empty non-detections
   if isUPA
       [rError,vError,eleError,aziError] = ...
          deal(rmmissing(rError),rmmissing(vError),rmmissing(eleError),rmmissing(aziError)); 
   else
       [rError,vError,aziError] = ...
          deal(rmmissing(rError),rmmissing(vError),rmmissing(aziError)); 
   end

   % RMSE calculation
   for i = 1:length(rError)

       radarEstRMSE(i).rRMSE = sqrt(sum(rError(i,:).^2)/size(rError(i,:),1));
       radarEstRMSE(i).vRMSE = sqrt(sum(vError(i,:).^2)/size(vError(i,:),1));
       if isUPA % UPA
          radarEstRMSE(i).eleRMSE = sqrt(sum(eleError(i,:).^2)/size(eleError(i,:),1));
          radarEstRMSE(i).aziRMSE = sqrt(sum(aziError(i,:).^2)/size(aziError(i,:),1));
       else % ULA
          radarEstRMSE(i).doaRMSE = sqrt(sum(aziError(i,:).^2)/size(aziError(i,:),1));
       end

   end

end