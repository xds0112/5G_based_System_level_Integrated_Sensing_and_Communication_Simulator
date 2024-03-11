function gNBs = getgNBpos(numCells, radius, gNBHeight, ROI)
% Get gNB positions in a hexagonal grid with wrap around arrangement
% centered at the first cell


    [xWidth, yWidth] = deal(ROI(1)./2,ROI(2)./2);
    
    dx = 1.5*radius;
    dy = radius*sqrt(3)/2;

    mx = ceil(xWidth/dx);
    my = ceil(yWidth/dy);
    maxCells = mx*my+1;   % maxium number of wrap-around cells in the ROI
    
    if numCells > maxCells
        disp(['Warning: numCells is too large. Taking maximum possible number of cells = ', num2str(maxCells)]);
        numCells = maxCells;
    end

    gNBPositions = zeros(numCells, 3);
    gNBIdx = 1;
    
    for i = -mx:mx
        for j = -my:my
            if mod((i+j),2) == 0

                xp = i*dx;
                yp = j*dy;
                
                % Judge whether the gNB position is in the figure
                if (abs(xp) > xWidth) || (abs(yp) > yWidth)
                    continue
                end
                
                % get gNB positions
                gNBPositions(gNBIdx,:) = [xp, yp, gNBHeight];
                gNBIdx = gNBIdx + 1;
                
                if gNBIdx > numCells
                    break
                end
            end
        end
        
        if gNBIdx > numCells
            break
        end
    end

    gNBs = gNBPositions;


end

