classdef wallBlockage < networkTopology.blockages.blockage
    % describes a wall blockage
    % This class is for the individual walls that make up a building or a
    % wall blockage. Each Wall contains at least 3 corners and has a wall
    % loss.
    %
    % initial author: Christoph Buchner
    %
    % see also blockages, blockages.Building

    properties
        % [3 x nCorners]double (x;y;z)coordinates of the corners
        cornerList

        % [3x1]double is the normal vector of the plane in which the wall is defined
        normVec

        % [1x1]double distance in direction of the normal vector from coordinate origin to the plane
        normDist

        % [1x1]double penetration loss through this wall in dB
        loss
    end

    methods
        function obj = wallBlockage(cornerList, loss)
            % wall's constructor
            %
            % input:
            %   cornerList: [3xn]double (x;y;z)-coordinates of each corner
            %                            at least 3 corners must be
            %                            specified
            %   loss:       [1x1]double loss through this wall in dB

            % set class properties
            if ~nargin
                cornerList = [1,0,0,1,1;0,0,1,1,0;0,0,1,1,0];
                loss       = 10;
            end
            nCorners = size(cornerList,2);
            if nCorners < 3
                error('use at least three points to specify a wall');
            end
            nDimCorn = size(cornerList,1);
            if nDimCorn < 3
                error('use 3D points for corners');
            end

            % call superclass constructor
            xSize = max(cornerList(1,:)) - min(cornerList(1,:));
            ySize = max(cornerList(2,:)) - min(cornerList(2,:));

            xCenter = min(cornerList(1,:)) + xSize/2;
            yCenter = min(cornerList(2,:)) + ySize/2;

            %radius
            r = 1/2 * sqrt(xSize^2 + ySize^2);
            obj = obj@networkTopology.blockages.blockage(xCenter,yCenter,r);

            %build vectors from the points
            vectors = repmat(cornerList(:,1), 1, nCorners-1) - cornerList(:, 2:end);
            basis   = orth(vectors);
            %calc all the possible normalVectors and build the mean of them
            normVector     = cross(basis(:,1), basis(:,2));
            obj.normVec    = 1/norm(normVector,2) * normVector;
            obj.normDist   = obj.normVec' * cornerList(:,1);
            obj.cornerList = cornerList;
            obj.loss       = loss;
        end

        function isInsideDecision  = checkIsInside(obj, ue)
            % This function determines the isinside property of a user
            % it checks if the user is inside the boundry of the wall
            %
            % input:
            %   ue [3 x n] double carthesian coordinates of a user
            %
            % output:
            %   isIndoorDecision [1 x n]logical true if ue is inside this
            %                                    building
            %
            % see also: blockages.Building.checkIsInside

            % set user z cordinate to normaldist assume this function is
            % called on the ceiling

            isInsideDecision = obj.getWindingNumber(ue) > 0.1;
        end

        function blockageDecision = checkBlockage(obj,ue,ant)
            % This function checks if this wall blocks any line of
            % sight path defined by ue and ant. This is achieved by first
            % projecting the user onto the plane of the wall and a calculation
            % of the winding number.
            %
            % inputs:
            %   ue [3 x n]double (x;y;z) Coordinates of the users in the scenario
            %   ant[3 x n]double (x;y;z) Coordinates of the antennas in the scenario
            %
            % output:
            %   blockageDecision [1xn]logical list of logical values
            %                   true  -> Collision
            %                   false -> Line of sight
            %
            % initial Author : Christoph Buchner
            %
            % See also
            % simulation.ChunckSimulation.checkBlockagesInLOS
            % blockages.Blockage , blockages.WallBlockages , blockages.Buildings

            % switch to plot some graphs to manually verify the result
            wallCollisionDebug = 0;

            vec = ue - ant;
            % project the user onto the plane of the wall
            projUe = ue + vec .* repmat((obj.normDist - obj.normVec'*ue)./(obj.normVec' * vec), 3, 1);

            % get collision information by calculating the winding number
            blockageDecision = obj.getWindingNumber(projUe) > 0.1;

            % correct Users in the corner to be considered as blocked
            % blockageDecision(iCornerUser)=1;

            if wallCollisionDebug == 1
                figure();
                plotCornerList = [obj.cornerList,obj.cornerList(:,1)];
                plot3(plotCornerList(1,:)', plotCornerList(2,:)', plotCornerList(3,:)','Color','b');
                hold on;
                color=(blockageDecision').*[1,0,0] +(~blockageDecision').*[0,1,0];
                scatter3(projUe(1,:)',projUe(2,:)',projUe(3,:)',[],color);
                for ii = 1: length(ant)
                    plot3([ant(1,ii)',ue(1,ii)'],[ant(2,ii)',ue(2,ii)'],[ant(3,ii)',ue(3,ii)'],'Color',color(ii,:));
                end
                xlim([min(obj.cornerList(1,:)),max(obj.cornerList(1,:))]);
                ylim([min(obj.cornerList(2,:)),max(obj.cornerList(2,:))]);
                zlim([min(obj.cornerList(3,:)),max(obj.cornerList(3,:))]);
                hold off;
            end
        end

        function handle = plotWall(obj, color, transparency)
            % plots the wall in a given color and transparency
            %
            % input:
            %   color [1 x 3]double [r, g, b]vector in the range (0,1)
            %   transparency:   [1x1]double transparency 0..1
            % output:
            %   handle [1 x 1]handleObject plot of the wall

            hold on;
            c      = obj.cornerList;
            c1     = [c, c(:,1)];
            handle = fill3(c1(1,:), c1(2,:), c1(3,:), color, 'FaceAlpha', transparency);
            hold off;
        end

        function plotFloorPlanEdge(obj, color)
            % plotFloorPlanEdge plots the Floorplan of the Wall in the given color
            %
            % input:
            %   color [1 x 3]double [r, g, b]vector in the range (0,1)

            c = obj.cornerList;
            plot3([c(1,1), c(1,2)], [c(2,1), c(2,2)], [0, 0], 'Color', color);
        end
    end

    methods (Access = private)
        function windingNum = getWindingNumber(obj, point)
            % This function is used to solve the point in polygon problem
            % It should determine if the point is inside or outside a given
            % polygon.
            % This is done by calculating the angles between the vectors
            % pointing from the point to each corner. If the sum over these
            % is n*2Pi the point lies inside the polygon.
            %
            % input:
            %   point [3 x n]double coords of points which we want to consider
            %
            % output:
            %   windingNum [1xn]double calculated winding number

            polygon  = obj.cornerList;
            nPoints  = size(point,2);
            nCorners = size(polygon,2);

            % calculate vectors pointing from the corners of the polygon to
            % the point
            vec = permute(repmat(polygon,1,1,nPoints),[1,3,2]) - ...
            repmat(point,1,1,nCorners);
            lenVec = vecnorm(vec,2,1);
            % set users wich are place in the corners to 0;
            invalid = (lenVec < 10^-10);

            % normate vectors we want to just consider the relative
            % arguments between the vecs
            vec = vec ./ (lenVec);

            shiftvec = circshift(vec,1,3); % shift for later calculation of angles between vectors
            dotvec   = dot(shiftvec,vec,1); % dot product of consecutive vectors
            crossvec = cross(shiftvec,vec,1);
            nmat     = repmat(obj.normVec,1,nPoints,nCorners); % generate normal vector in matrix form

            % calculate angle between the vectors
            diffAngle = atan2(dot(nmat,crossvec,1),dotvec) ;

            % sum over the difference angels to calculate the winding
            % number if sum over diffAngle = 0 the point is inside the
            % boundry, to cope with numerical inprecision 0.1 is the
            % threshold
            windingNum = abs(sum(diffAngle,3));

            windingNum(sum(invalid,3)>0) = 1;
        end
    end

    methods (Static)
        function newWallBlockages = generatePredefinedPositions(wallParameter, ~)
            % generatePredefinedPositions creates WallBlockage objects
            % This function generate Walls and place copies at the
            % predefined wallParameter.positions.
            %
            %   parameters.WallBlockage.PredefinedPositions
            %
            % See also parameters.WallBlockage.PredefinedPositions

            % get number of walls
            nWalls = size(wallParameter.positions, 2);

            % initialize wall blockages
            newWallBlockages(nWalls) = networkTopology.blockages.wallBlockage();
            positionsMat = repmat(wallParameter.positions,1,1,size(wallParameter.cornerList,2));

            % set wall blockages
            for iWall = 1:nWalls
                % set creat wall obj
                newWallBlockage = networkTopology.blockages.wallBlockage(squeeze(positionsMat(:,iWall,:)) + wallParameter.cornerList, wallParameter.loss);
                % save it into return value
                newWallBlockages(iWall) = newWallBlockage;
            end
        end
    end
end

