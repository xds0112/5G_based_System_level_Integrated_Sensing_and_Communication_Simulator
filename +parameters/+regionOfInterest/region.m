classdef region < tools.HiddenHandle
    %REGION basic class for a region
    % This class is used as interference region and as superclass for the
    % region of interest. The geometric size of the region is defined here.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.regionOfInterest.RegionOfInterest

    properties
        % center of the region of interest
        %[1x2]double [x,y]-coordinate of the center of the ROI
        % These are the coordinates by which the center of the ROI is
        % offset from the (0,0) coordinate.
        origin2D = [0;0];

        % length of the region of interest
        %[1x1]double length of ROI in (x coordinate) in meter
        xSpan = 1000;

        % width of the region of interest
        %[1x1]double width of ROI in (y coordinate) in meter
        ySpan = 1000;

        % height of the region of interest
        %[1x1]double height of ROI in (z coordinate) in meter
        zSpan = 100;
    end

    properties (Dependent, SetAccess = protected)
        % minimal x coordinate of the ROI
        % [1x1]double minimal x-coordinate of the ROI
        xMin

        % maximal x coordinate of the ROI
        % [1x1]double maximal x-coordinate of the ROI
        xMax

        % minimal y coordinate of the ROI
        % [1x1]double minimal y-coordinate of the ROI
        yMin

        % maximal y coordinate of the ROI
        % [1x1]double maximal y-coordinate of the ROI
        yMax
    end

    methods
        function obj = region()
            % empty class constructor - for default values see property definitions
        end

        function xMin = get.xMin(obj)
            % getter function for xMin
            %
            % output:
            %   xMin:   [1x1]double minimal x-coordinate of the ROI

            xMin = -obj.xSpan/2 + obj.origin2D(1);
        end

        function xMax = get.xMax(obj)
            % getter function for xMax
            %
            % output:
            %   xMax:   [1x1]double maximal x-coordinate of the ROI

            xMax = obj.xSpan/2 + obj.origin2D(1);
        end

        function yMin = get.yMin(obj)
            % getter function for yMin
            %
            % output:
            %   yMin:   [1x1]double minimal y-coordinate of the ROI

            yMin = -obj.ySpan/2 + obj.origin2D(2);
        end

        function yMax = get.yMax(obj)
            % getter function for yMax
            %
            % output:
            %   yMax:   [1x1]double maximal y-coordinate of the ROI

            yMax = obj.ySpan/2 + obj.origin2D(2);
        end
    end
end

