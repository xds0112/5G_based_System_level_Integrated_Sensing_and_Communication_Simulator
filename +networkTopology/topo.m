function topoParams = topo(bsParams,targetlists)
%GETTOPOPARAMS
%   Calculate the position of the target relative to the base station

% Topology params assignment

    bsPos = bsParams.position;
    NumTargets = length(targetlists);
    sectors = cell(NumTargets,1);
    rngs = cell(NumTargets,1);
    azis = cell(NumTargets,1);
    eles = cell(NumTargets,1);
    topoParams = struct;

    for ii = 1:NumTargets
        % Attached targets
        tgtParams = targetlists{ii};
        numTgts = size(tgtParams,2);

        % Restore path' positions 
        tgtPos = tgtParams;

        % Calculate relative coords
        coordsTgts = tgtPos - repmat(bsPos',1,numTgts);

        % Calculate relative distances and angles
        [azimuthTgts,eleRad, range] = cart2sph(coordsTgts(1,:), coordsTgts(2,:), coordsTgts(3,:));

        % Convert the angles to degrees
        %azimuthTgts = deal(rad2deg(azimuthTgts));
        [azimuthTgts, ele] = deal(rad2deg(azimuthTgts), rad2deg(eleRad));
        numsector = deal(azimuthTgts);
    
        % Determine the sector scope , Convert azimuth
        for i = 1:numel(azimuthTgts)
            if azimuthTgts(i) <= 60 && azimuthTgts(i) >= -60
                azimuthTgts(i)   = azimuthTgts(i);
                numsector(i) = 1;
            end
            if azimuthTgts(i) <= 180 && azimuthTgts(i) >= 60
                azimuthTgts(i)   =  azimuthTgts(i)-120;
                numsector(i) = 2;
            end
            if azimuthTgts(i) <= -60 && azimuthTgts(i) >= -180
                azimuthTgts(i)   = azimuthTgts(i)+120;
                numsector(i) = 3;
            end
        end
        sectors{ii} = numsector;
        rngs{ii} = range;
        azis{ii} = azimuthTgts;
        eles{ii} = ele;
    end
    topoParams.numsector = sectors;
    topoParams.rng = rngs;
    topoParams.azi = azis;
    topoParams.ele = eles;
end
