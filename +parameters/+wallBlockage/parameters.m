classdef parameters < tools.HiddenHandle
    % superclass for wall object creation parameters
    % Adding these parameters to parameters.Parameters.wallParameters
    % creates walls with the indicated properties in the simulation.
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.Parameters.wallParameters, networkTopology.blockages.wallBlockage

    properties
        % loss of the walls in dB
        % [1x1]double wall loss in dB
        loss

        % corners of the walls
        % [1 x nWalls] struct
        %   -corners  [3 x nCorners] double coordinates of the
        %                       corners which define the wall
        cornerList

        % predefined positions
        % [3 x nWall]double (x;y)-positions of wallBlockage positions
        positions
    end

    properties (SetAccess = private)
        % indices of the realised walls
        % [1 x nWalls]integer indices of this wall type in wall list
        indicesWalls
    end

    properties (Abstract, SetAccess = private)
        createWallFunction % function handle to the wall generation
    end

    methods
        function setIndices(obj, firstIndex, lastIndex)
            % setIndices sets the indices for the generated walls
            %
            % input:
            %   firstIndex: [1x1]integer first index of walls of this type in wall list
            %   lastIndex:  [1x1]integer last index of walls of this type in wall list

            % set wall idices
            obj.indicesWalls = firstIndex:1:lastIndex;
        end
    end
end

