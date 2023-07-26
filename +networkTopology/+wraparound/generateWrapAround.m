function [distances, azimuths] = generateWrapAround(ROI, numCells, cellRadius, gNBHeight, ueDensity, maxUEs)
%TOPOLOGY 
%
% This function generates the topology of a wireless network by randomly 
% placing cells (base stations) and user equipments (UEs) within a given 
% region of interest (ROI).

    % Define UE heights
    ueHeight = 1.5; % in meters

    % Get gNB positions (center of the cell)
    gNBs = getgNBPositions(numCells, cellRadius, gNBHeight, ROI);
    [x,y,z] = deal(gNBs.x, gNBs.y, ones(size(gNBs.x))*gNBHeight);

    % Get hex region coordinates of each cell
    hexVertices = zeros(7, 2, numCells);
    for ibs = 1:numCells
        hexVertices(:,:,ibs) = hexGrid(cellRadius, [x(ibs) y(ibs)]);
    end

    % Poisson distribution of UEs in each cell
    numUEsperCell = poissrnd(ueDensity * (pi*cellRadius^2), numCells, 1);
    numUEsperCell(numUEsperCell > maxUEs) = maxUEs;

    allUEs = []; % Variable to store all UE positions and sector labels
    allDistances = cell(3,numCells); % Cell array to store distance values
    allAzimuths  = cell(3,numCells); % Cell array to store azimuth values
    
    for i = 1:numCells

        % Generate random UE in a cell
        numUEs = numUEsperCell(i);
    
        if numUEs > 0
            uePositions = zeros(numUEs, 3);
            for j = 1:numUEs
                % Generate random position within cellRadius from cell center
                r     = cellRadius * sqrt(rand());
                theta = 2*pi*rand();
                xj    = r*cos(theta) + x(i);
                yj    = r*sin(theta) + y(i);
            
                % Check if position falls inside the hexagon and not at cell center
                if inpolygon(xj, yj, hexVertices(:,1,i), hexVertices(:,2,i)) && norm([xj,yj]-[x(i),y(i)])>0.1
                    uePositions(j,:) = [xj yj ueHeight];
                else
                    % Position falls outside hexagon or at cell center, discard it
                    j = j - 1;
                end
            end
        
        else
            uePositions = [];
        end

        % Delete UE positions that are all zeros
        uePositions( ~any(uePositions,2), : ) = [];
        % Initialize sector labels array to be same size as uePositions
        cellLabels = zeros(size(uePositions,1),1);
        cellLabels(:) = i;
    
        % Store distances and azimuths in struct array
        d  = vecnorm(uePositions - [x(i) y(i) z(i)], 2, 2);
        az = atan2d(uePositions(:,2) - y(i), uePositions(:,1) - x(i));

        % Divide azimuths into three sectors based on 5G convention
        sector1 = find((az >= 0) & (az <= 120));
        sector2 = find((az > 120) & (az <= 180) | (az >= -180) & (az < -120));
        sector3 = find((az >= -120) & (az < 0));
       
        allDistances{1,i} = d(sector1)';
        allDistances{2,i} = d(sector2)';
        allDistances{3,i} = d(sector3)';
    
        allAzimuths{1,i} = az(sector1)';
        allAzimuths{2,i} = az(sector2)';
        allAzimuths{3,i} = az(sector3)';
        
        % Add cell's UE positions and sector labels to all UEs variable
        cellUEs = [uePositions cellLabels];
        allUEs  = [allUEs; cellUEs];

    end

    % Plot all UEs
    scatter3(allUEs(:,1), allUEs(:,2), allUEs(:,3), 5, 'b', 'filled', 'DisplayName', 'UEs')

    distances = allDistances;
    azimuths  = allAzimuths;

end

%% Local Functions
function gNBs = getgNBPositions(numCells, radius, gNBHeight, ROI)
% Get gNB positions in a hexagonal grid with wrap around arrangement
% centered at the first cell

    figure('Name','Network Topology')
    title('Network Topology')
    [xWidth, yWidth] = deal(ROI(1)./2,ROI(2)./2);
    axis([-xWidth xWidth -yWidth yWidth 0 gNBHeight])
    xlabel('x (m)')
    ylabel('y (m)')
    zlabel('height (m)')
    grid on
    hold on
    
    dx = 1.5*radius;
    dy = radius*sqrt(3)/2;
    A  = 0:pi/3:2*pi;
    px = radius*cos(A);  
    py = radius*sin(A);

    mx = ceil(xWidth/dx);
    my = ceil(yWidth/dy);
    maxCells = mx*my+1;   % maxium number of wrap-around cells in the ROI
    
    if numCells > maxCells
        disp(['Warning: numCells is too large. Taking maximum possible number of cells = ', num2str(maxCells)]);
        numCells = maxCells;
    end

    gNBPositions = zeros(maxCells, 2);
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
                
                plot(px+xp, py+yp, 'k-', 'linewidth', .5, 'DisplayName', 'Cell Region');
                scatter3(xp, yp, gNBHeight, 25, 'r', 'filled', 'DisplayName', 'gNBs')

                offset = radius/6;
                text(xp+offset, yp-offset, num2str(gNBIdx), ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                    'middle', 'Color', 'black', 'FontWeight', 'bold');

                legend('Cell Region', 'gNBs')
                
                % get gNB positions
                gNBPositions(gNBIdx,:) = [xp, yp];
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

    gNBs.x = gNBPositions(:,1);
    gNBs.y = gNBPositions(:,2);

end

function vertices = hexGrid(radius, center)
    % Generate the coordinates of a hexagon centered at 'center' with radius 'radius'
    vertices = zeros(7,2);
    
    for i = 1:6
        angle_deg = 60 * i;
        angle_rad = pi / 180 * angle_deg;
        vertices(i+1,1) = center(1) + radius * cos(angle_rad);
        vertices(i+1,2) = center(2) + radius * sin(angle_rad);
    end

    vertices(1,:) = vertices(end,:);

end
