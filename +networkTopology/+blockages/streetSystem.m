classdef streetSystem < tools.HiddenHandle
    % system of streets
    % The StreetSystem is defined by specifying the locations of the nodes
    % which correspond to starts and endings of roads as well as a
    % connectionMatrix which node is connected to which node. Two connected
    % nodes make a street with a given width.
    %
    % initial author: Lukas Nagel
    
    properties
        % [2 x nNodes]double position of each node
        nodeLocations
        
        % [nNodes x nNodes]logical specifies succesor of actual node
        connectionMatrix
        
        % [1 x nNodes]integer used for node renumbering
        % links the position in the connectionMatrix to the nodeLocations
        labels
        
        % [1x1]double width of the streets in meter
        streetWidth
        
        % [1x1]integer number of streets
        nStreets
        
        % [1x1]integer number of nodes
        nStreetNodes
        
        % [1x1]double total area of all streets combined in m^2
        totalArea
    end
    
    properties (Access = private)
        % [1 x n]struct with
        %   p1:              [2 x 1]double position of the startnode of a streetelement
        %   p2:              [2 x 1]double position of the endnode of a streetelement
        %   forwardVec:      [2 x 1]double direction from start to end of a streetelement
        %   rightVec:        [2 x 1]double perpendicular vector to forwardVec
        %   length:          [1 x 1]double size (l2) of the vector from p1 to p2
        %   plotCoordinates: [2 x 4]double coordinates around the street
        % the boxes that represent actual streets
        streetBoxes
    end
    
    methods
        function obj = streetSystem(nodeLocations, connectionMatrix, labels, streetWidth)
            % StreetSystem's constructor
            %   Sets several properties and computes the StreetBoxes.
            %
            % input:
            %   nodeLocations    [2      x nNodes] double  position of each node
            %   connectionMatrix [nNodes x nNodes] boolean specifies succesor of actual node
            %   labels           [1      x nNodes] integer maps from connectionMatrix to nodeLocations
            %
            % See also networkGeometry.ManhattanGrid
            
            obj.nodeLocations = nodeLocations;
            obj.connectionMatrix = connectionMatrix;
            obj.labels = labels;
            
            obj.streetWidth = streetWidth;
            
            obj.nStreets = sum(obj.connectionMatrix(:));
            obj.nStreetNodes = size(obj.connectionMatrix,1);
            
            obj.streetBoxes = [];
            
            w = obj.streetWidth;
            
            % create street areas
            for ii = 1:obj.nStreetNodes
                for jj = 1:ii
                    if obj.connectionMatrix(ii, jj) > 0
                        x = obj.nodeLocations(1, :);
                        y = obj.nodeLocations(2, :);
                        
                        p1 = [x(obj.labels(jj)); y(obj.labels(jj))];
                        p2 = [x(obj.labels(ii)); y(obj.labels(ii))];
                        
                        streetBox = struct;
                        streetBox.forwardVec = (p2-p1) / norm(p2-p1,2);
                        streetBox.rightVec   = [streetBox.forwardVec(2); -streetBox.forwardVec(1)]; % rotated to the "right"
                        streetBox.length     = norm(p2-p1,2);
                        
                        streetBox.plotCoordinates = [p1+streetBox.rightVec*w/2, ...
                            p1+streetBox.forwardVec*streetBox.length+streetBox.rightVec*w/2,...
                            p1+streetBox.forwardVec*streetBox.length-streetBox.rightVec*w/2,...
                            p1-streetBox.rightVec*w/2];
                        
                        streetBox.p1 = p1;
                        streetBox.p2 = p2;
                        
                        obj.streetBoxes = [obj.streetBoxes, streetBox];
                    end
                end
                
                totalArea = 0;
                for aa = 1:length(obj.streetBoxes)
                    totalArea = totalArea + obj.streetBoxes(aa).length * obj.streetWidth;
                end
                
                obj.totalArea = totalArea;
            end
        end
        
        function copyPrivate(obj, old)
            % used to copy the streetBoxes from another object to this
            % object
            %
            % input:
            %   old [1 x 1]handleObject blockages.StreetSytem
            
            obj.streetBoxes = old.streetBoxes;
        end
        
        function randomPositions = getRandomPositions2D(obj, nPositions)
            % randomPositions returns nPositions random points on streets
            % of the StreetSystem used to place user randomly on a street
            %
            % input:
            %   nPositions [1 x 1]integer number of desired positions
            % output:
            %   randomPositions [2 x nPositions]double random positions on the street
            %
            randomPositions = zeros(2, nPositions);
            
            nBoxes = length(obj.streetBoxes);
            boxNumbers = randi([1,nBoxes], [nPositions,1]);
            
            randVectors = rand(2, nPositions);
            
            for ii = 1:nPositions
                box = obj.streetBoxes(boxNumbers(ii));
                
                randomPositions (:, ii) = box.p1 + ...
                    randVectors(1, ii) * box.forwardVec * box.length + ....
                    (randVectors(2, ii)-0.5) * box.rightVec * obj.streetWidth;
            end
        end
        
        function plot(obj)
            % plot plots the whole StreetSystem
            grey = [0.8, 0.8, 0.8];
            for ii = 1:length(obj.streetBoxes)
                box = obj.streetBoxes(ii);
                fill(box.plotCoordinates(1,:), box.plotCoordinates(2,:), grey, 'LineStyle', 'None')
                hold on;
                
                tools.drawCircle2D(box.p1, obj.streetWidth/2, 'FaceColor', grey, 'LineStyle', 'None');
                tools.drawCircle2D(box.p2, obj.streetWidth/2, 'FaceColor', grey, 'LineStyle', 'None');
            end
        end
    end
end

