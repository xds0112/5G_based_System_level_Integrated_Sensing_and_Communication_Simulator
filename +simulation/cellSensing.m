function res = cellSensing(gNB, cellSimuParam, topoParams, targetlists)

    res = cell(1,length(targetlists));
    vel = cellSimuParam.velocity;
    rcs = cellSimuParam.rcs;
    gNBposition = cellSimuParam.gNBPosition;
    targetLoSConditions = cellSimuParam.targetLoSConditions;
    detectionfre =cellSimuParam.detectionfre/(10*cellSimuParam.numFrames/cellSimuParam.numSlots);
    for ii = 1:length(targetlists)

        % Data initialization
        pos = targetlists{ii}';
        r = zeros(1,size(pos,1));
        v = zeros(1,size(pos,1));
        a = zeros(1,size(pos,1));
        e = zeros(1,size(pos,1)); 
        realposition = zeros(size(pos,1),3);
        RMSE = zeros(size(pos,1),1);
        rngRMSE = zeros(size(pos,1),1);
        aziRMSE = zeros(size(pos,1),1);
        eleRMSE = zeros(size(pos,1),1);
    
        % result restore
        for i = 1:detectionfre:size(pos,1)           
            cellSimuParam.targetPosition = pos(i,:);
            cellSimuParam.velocity = vel(ii);
            cellSimuParam.rcs = rcs(1);
            cellSimuParam.targetLoSConditions = targetLoSConditions{ii}(i);
            if cellSimuParam.targetLoSConditions == 1
                senResult = simulation.sensingfunction(gNB, cellSimuParam);               
                r(i) = senResult.rngEst;
                v(i) = senResult.velEst;
                a(i) = senResult.aziEst;
                e(i) = senResult.eleEst;
            else
                r(i) = 0;
                v(i) = 0;
                a(i) = 0;
                e(i) = 0;
            end
            % sector distribution
            if topoParams.numsector{ii}(i) == 1
                realposition(i,:) = [r(i)*cos(e(i)*pi/180)*cos(a(i)*pi/180) + gNBposition(1),r(i)*cos(e(i)*pi/180)*sin(a(i)*pi/180) + gNBposition(2),r(i)*sin(e(i)*pi/180) + gNBposition(3)];
            end
            if topoParams.numsector{ii}(i) == 2
                realposition(i,:) = [r(i)*cos(e(i)*pi/180)*cos((a(i)+120)*pi/180) + gNBposition(1),r(i)*cos(e(i)*pi/180)*sin((a(i)+120)*pi/180) + gNBposition(2),r(i)*sin(e(i)*pi/180) + gNBposition(3)];
            end
            if topoParams.numsector{ii}(i) == 3
                realposition(i,:) = [r(i)*cos(e(i)*pi/180)*cos((a(i)-120)*pi/180) + gNBposition(1),r(i)*cos(e(i)*pi/180)*sin((a(i)-120)*pi/180) + gNBposition(2),r(i)*sin(e(i)*pi/180) + gNBposition(3)];
            end
            RMSE(i) = sqrt((realposition(i,1)-pos(i,1))^2 + (realposition(i,2)-pos(i,2))^2 + (realposition(i,3)-pos(i,3))^2);
            rngRMSE(i) = abs(r(i)-topoParams.rng{ii}(i));
            eleRMSE(i) = abs(e(i)-topoParams.ele{ii}(i));
            aziRMSE(i) = abs(a(i)-topoParams.azi{ii}(i));

        end
        res{ii} = struct('rngEst', r, 'velEst', v, 'aziEst', a, 'eleEst', e, 'sensingEst', realposition, 'positionRMSE', RMSE,...
            'rangeRMSE', rngRMSE, 'eleRMSE', eleRMSE, 'aziRMSE', aziRMSE);

    end

end
