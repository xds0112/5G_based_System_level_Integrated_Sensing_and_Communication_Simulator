classdef building < networkTopology.blockages.blockage
    % building with a arbitrary layout and height
    % Each building contains WallBlockage elements to construct a building.
    %
    % initial author: Christoph Buchner
    %
    % see also blockages.Wall

    properties
        % [1x1]double max xSize of the layout
        % x-size of the building
        xSize

        % [1x1]double max ySize of the layout
        % y-size of the building
        ySize

        % [1x1]double height of the building
        % z-size of the building
        height

        % [1x1]integer number of walls in this blockage
        nWall

        % [1 x nWall]handleObject blockages.WallBlockage walls of the building
        wallList

        % [2 x n] nodes (xpos;ypos)
        % composed from all corners in the wallList with zpos = 0
        floorPlan

        % [1x1]string name or address of building
        name
    end

    methods
        function obj = building(floorPlan, height, loss, name)
            % Building's constructor
            % set object properties
            % Takes a path and calculates its walls.
            %
            % also see blockage.Blockage,
            %          blockage.Walls
            %
            % input:
            %   floorPlan:  [2 x n]double (x,y) specifies a path wich should
            %                           be used to create walls alongside it
            %   height:     [1 x 1]double building height in m
            %   loss:       [1 x 1]double loss through its wall in dB
            %   name:       [1 x 1]string name or address of the building
            %
            % initial author: Christoph Buchner

            if nargin == 0
                floorPlan = [1,0,0,1,1;0,0,1,1,0];
                height    = 5;
                loss      = 3;
                name      = "";
            elseif nargin == 3
                name = "";
            end

            % calculate properties for Superclass
            xSize   = max(floorPlan(1,:)) - min(floorPlan(1,:)); % span in x direction
            ySize   = max(floorPlan(2,:)) - min(floorPlan(2,:)); % span in y direction
            xCenter = min(floorPlan(1,:)) + xSize/2;
            yCenter = min(floorPlan(2,:)) + ySize/2;
            r = 1/2*sqrt(ySize^2 + xSize^2);

            % call superclass constructor
            obj = obj@networkTopology.blockages.blockage(xCenter, yCenter, r);

            % calculate dimensions
            obj.floorPlan = floorPlan;
            obj.ySize     = ySize;
            obj.xSize     = xSize;
            obj.height    = height;

            obj.name = name;

            %% generate walls
            % initialize wallList
            obj.wallList = [];

            for iCorner = 1:size(floorPlan,2)-1
                % generate corners
                lowerLeft  = [floorPlan(:,iCorner); 0];
                lowerRight = [floorPlan(:,iCorner+1); 0];
                upperLeft  = [floorPlan(:,iCorner); height];
                upperRight = [floorPlan(:,iCorner+1); height];
                % update WallList
                obj.wallList = [obj.wallList, networkTopology.blockages.wallBlockage([lowerLeft, lowerRight, upperRight, upperLeft], loss)];
            end

            % Create and add ceiling to WallList
            zCeiling = height*ones(1, size(floorPlan,2));
            ceiling  = [obj.floorPlan; zCeiling];
            obj.wallList = [obj.wallList, networkTopology.blockages.wallBlockage(ceiling, loss)];
        end

        function nWall = get.nWall(obj)
            % getter function for the number of walls of this blockage
            %
            % output:
            %   nWall:  [1x1]integer number of walls of the blockage
            %
            % initial author: Christoph Buchner

            % get number of walls
            nWall = length(obj.wallList);
        end

        function blockageDecision = checkBlockage(obj, userPositionList, antennaPositionList)
            % Evaluats the LOS blockage status on building level
            %
            % input:
            %   userPositionsList:      [3 x nUser]double list of user positions
            %   antennaPositionsList:	[3 x nAnt]double list of antenna positions
            % output:
            %   blockageDecision:	[1 x nUser*nAntenna]logical Map of LOS connection which are blocked
            %
            % see also: blockages.WallBlockage.checkBlockage
            %
            % initial author: Christoph Buchner

            % initialize output
            blockageDecision = zeros(1,size(userPositionList,2)*size(antennaPositionList,2));

            % loop over all walls describing the building
            for wall = obj.wallList
                blockageDecision = blockageDecision + wall.checkBlockage(userPositionList,antennaPositionList);
            end

            % if only one wall blocks a LOS, the building will block the LOS
            % cast to logical
            blockageDecision = blockageDecision > 0;
        end

        function isIndoorDecision = checkIsInside(obj, userPositionList)
            % this function calls the checkIsInside function of the ceiling
            % to determin if a user is currently inside the building
            %
            % Input:
            %   userPositionList:	[3 x nUser] double karthesian coordinates of a user
            %
            % Output:
            %   isIndoorDecision [1 x nUser]logical true if ue is inside this building
            %
            % initial author: Christoph Buchner
            %
            % see also: blockages.WallBlockage.checkIsInside
            %          simulation.ChunkSimulation.checkBlockagesInLOS

            % switch for debug plots
            checkInsideDebug = 0;

            % check dimension of uePosList
            switch size(userPositionList,1 )
                case 2
                    % valid dimension continue operation
                    isIndoorDecision = true(size(userPositionList, 2));
                    userPositionList = [userPositionList; zeros(1, size(userPositionList, 2))];
                case 3
                    % check 3 dimension height and than discard 3 dimension
                    isIndoorDecision      = userPositionList(3, :) < obj.height;
                    userPositionList(3,:) = ones(1,size(userPositionList,2)) * obj.height;
                otherwise
                    error('userPositionList is must be of dimension 3 x nUser.');
            end

            % get ceiling as last element in the WallList
            ceiling = obj.wallList(end);
            isIndoorDecision = isIndoorDecision & ceiling.checkIsInside(userPositionList);

            if checkInsideDebug == 1
                figure();
                plot(obj.floorPlan(1,:), obj.floorPlan(2,:));
                hold on;
                color=(indoorDecision').* [0, 1, 0] +(~indoorDecision') .* [1 , 0, 0];
                scatter(userPositionList(1, :), userPositionList(2, :), [], color);
                hold off;
            end
        end

        function plot(obj, color, transparency)
            % plot  plots the building in a given color
            %
            % input:
            %   color:          [1x3]double  expects a [r, g, b] vector in the range (0,1)
            %   transparency:   [1x1]double transparency 0...1 (0 is fully transparent)
            %
            % initial author : Christoph Buchner

            hold on;

            % plot all walls
            for iWall = obj.wallList
                iWall.plotWall(color, transparency);
            end

            hold off;
        end

        function plotFloorPlan(obj, color)
            % plotFloorPlan plots the floorplan of the building
            % input:
            %   color:  [1x3]double  expects [r, g, b] vector in the range (0,1)

            hold on;
            plot3(obj.floorPlan(1,:), obj.floorPlan(2,:), zeros(1,length(obj.floorPlan)), 'Color', color);
            hold off;
        end

        function plotFloorPlan2D(obj, color)
            % plotFloorPlan plots the floorplan of the building
            % input:
            %   color:  [1x3]double  expects [r, g, b] vector in the range (0,1)

            hold on;
            plot(obj.floorPlan(1,:), obj.floorPlan(2,:), 'Color', color);
            hold off;
        end
    end

    methods (Static)
        function buildingList = generatePredefinedPositions(buildingParameters, ~)
            % generatePredefinedPositions constructs Buildings
            %   This method is used to create the buildings as specified
            %   with the class parameters.building.PredefinedPositions
            %
            % inputs:
            %    buildingParameters [1 x 1]parameters.building.PredefinedPositions
            %
            % outputs:
            %    buildingList       [1 x n]blockages.Building
            %
            % See also parameters.building.PredefinedPositions,
            % blockages.Building
            %
            % initial author: Christoph Buchner

            % get number of buildings to create
            nBuildings = size(buildingParameters.positions, 2);

            % initalize buildings
            buildingList(nBuildings) = networkTopology.blockages.building();
            positionsMat  = repmat(buildingParameters.positions,1,1,size(buildingParameters.floorPlan,2));

            % set building parameters
            for bb = 1:nBuildings
                % create building object
                newBuilding = networkTopology.blockages.building(...
                    squeeze(positionsMat(:,bb,:)) + buildingParameters.floorPlan, ...
                    buildingParameters.height, buildingParameters.loss);

                % save building object
                buildingList(bb) = newBuilding;
            end
        end
    end
end

