classdef blockage <  matlab.mixin.Heterogeneous & tools.HiddenHandle
    % super class for all blockage elements
    %
    % see also  blockages.WallBlockage, blockages.WallBlockage
    %
    % initial author: Lukas Nagel
    % extended by: Christoph Buchner, added r for an estimation of blockage

    properties
        % [1x1]double center's x
        % x-coordinate of the center of the blockage
        x

        % [1x1]double center's y
        % y-coordinate of the center of the blockage
        y

        % [1x1] double radius of a circle around the center of the blockage
        % defined by the largest distance from center to corner
        % only consider in the xy Plane
        r
    end

    methods (Abstract)
        % every subclass of blockage must include a checkBlockage function
        % which determines if it is a blockage in the line between user
        % and antenna
        %
        % input:
        %   userPositionsList:      [3 x nUser]double list of user positions
        %   antennaPositionsList:	[3 x nAnt]double list of antenna positions
        % output:
        %   blockageDecision:	[1 x nUser*nAntenna]logical Map of LOS connection which are blocked
        blockageDecision = checkBlockage(obj, userPositionsList, antennaPositionsList)
    end

    methods
        function obj = blockage(x, y, r)
            % set blockage properties
            %
            % input:
            %   x:  [1 x 1]double x-coordinate of the center of the blockage
            %   y:  [1 x 1]double y-coordinate of the center of the blockage
            %   r:  [1 x 1]double radius around the center of the blockage
            if ~nargin
                r = 1;
                x = 0;
                y = 0;
            end
            obj.r = r;
            obj.x = x;
            obj.y = y;
        end
    end

    methods (Static)
        function [wallList] = getOrderedWallList(buildingsList, wallBlockageList)
            % getBlockageList returns a list of all walls in the "global order"
            % the order should be the same as the one returned by the checkLOS
            % functions
            % for now the order is the following:
            % 1. list walls that make up the buildings
            % 2. list of walls that make up wall objects
            %
            % input:
            %   buildingsList:      [1 x nBuildings]handleObject blockages.Building
            %   wallBlockageList:   [1 x nWalls]handleObject blockages.WallBlockage
            %
            % output:
            %   wallList:   [1 x nWalls]handleObject blockages.WallBlockage

            %NOTE: there should be better way to ensure the walls use the same order
            %everywhere

            % initalize wallList
            wallList = [];

            % append building walls to wall list
            for iBuilding = 1:length(buildingsList)
                wallList = [wallList, buildingsList(iBuilding).wallList];
            end

            % append walls to wall list
            if ~isempty(wallBlockageList)
                wallList = [wallList, wallBlockageList];
            end
        end
    end

    methods (Static, Sealed, Access = protected)
        %NOTE: this is necessary to build arrays of different antenna
        %objects, i.e. Omnidirectional and ThreeSector, as is used in two
        %tier scenarios
        function default_object = getDefaultScalarElement
            default_object = networkTopology.blockages.wallBlockage;
        end
    end
end

