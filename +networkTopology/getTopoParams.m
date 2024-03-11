function topoParams = getTopoParams(bsParams)
%GETTOPOPARAMS
%   Calculate the position of the target relative to the base station

        % Topology params assignment
        numBSs = numel(bsParams);
        topoParams = repmat(struct,1,numBSs);

        for ibs = 1:numBSs

            bsPos = bsParams{ibs}.position;
            
            % Attached UEs
            ueParams = bsParams{ibs}.attachedUEs;
            numUEs = size(ueParams.position,1);

            % Restore UEs' positions
            uePos = zeros(3,numUEs);

            for iue = 1:numUEs
                uePos(:,iue) = ueParams.position(iue,:)';
            end

            % Attached targets
            tgtParams = bsParams{ibs}.attachedTargets;
            numTgts = size(tgtParams.position,1);

            % Restore targets' positions and velocities
            tgtPos = zeros(3,numTgts);
            tgtVel = zeros(1,numTgts);
      
            for itg = 1:numTgts
                tgtPos(:,itg) = tgtParams.position(itg,:)';
                tgtVel(itg)   = tgtParams.velocity(itg);
            end

            % Calculate relative coords
            coordsUEs  = uePos - repmat(bsPos',1,numUEs);
            coordsTgts = tgtPos - repmat(bsPos',1,numTgts);
    
            % Calculate relative distances and angles
            [azimuthUEs, elevationUEs, rangeUEs] = cart2sph(coordsUEs(1,:), coordsUEs(2,:), coordsUEs(3,:));
            [azimuthTgts, elevationTgts, rangeTgts] = cart2sph(coordsTgts(1,:), coordsTgts(2,:), coordsTgts(3,:));
    
            % Convert the angles to degrees
            [azimuthUEs, elevationUEs]   = deal(rad2deg(azimuthUEs), rad2deg(elevationUEs));
            [azimuthTgts, elevationTgts] = deal(rad2deg(azimuthTgts), rad2deg(elevationTgts));
            numsector = deal(azimuthTgts);
            % UEs
            topoParams(ibs).rangeUEs     = rangeUEs;
            topoParams(ibs).azimuthUEs   = azimuthUEs;
            topoParams(ibs).elevationUEs = elevationUEs;
            % Targets
            topoParams(ibs).rangeTgts     = rangeTgts;
            topoParams(ibs).elevationTgts = elevationTgts;
            topoParams(ibs).velocityTgts  = tgtVel;
%             for i = 1:numel(azimuthTgts)
%                 if azimuthTgts(i) <= 60 && azimuthTgts(i) >= -60
%                     azimuthTgts(i)   = azimuthTgts(i);
%                     numsector(i) = 1;
%                 end
%                 if azimuthTgts(i) <= 180 && azimuthTgts(i) >= 60
%                     azimuthTgts(i)   =  azimuthTgts(i)-120;
%                     numsector(i) = 2;
%                 end
%                 if azimuthTgts(i) <= -60 && azimuthTgts(i) >= -180
%                     azimuthTgts(i)   = azimuthTgts(i)+120;
%                     numsector(i) = 3;
%                 end
%             end
            topoParams(ibs).azimuthTgts   = azimuthTgts;
%             topoParams(ibs).numsector     = numsector;
        end

end

