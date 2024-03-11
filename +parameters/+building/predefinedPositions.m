classdef predefinedPositions < parameters.building.parameters
    %PREDEFINEDPOSITIONS generates buildings with predefined positions and fixed dimensions
    %
    % initial author: Lukas Nagel
    %
    % see also networkTopology.blockages.building

    properties
        % wall loss in dB
        % [1x1]double wall loss in dB
        loss

        % building's height in meter
        % [1x1]double building height in meter
        height

        % floorPlans of the buildings
        % [2 x nCorners] double coordinates of the
        % corners which define the floorplan of the building
        %
        floorPlan

        % predefined positions
        % [2 x nBuildings]double (x;y)-positions of building positions
        positions
    end

    properties (SetAccess = private)
        % function handle to building creation function
        createBuildingsFunction = @networkTopology.blockages.building.generatePredefinedPositions;
    end

    methods
        function nBuildings = getEstimatedBuildingCount(obj, ~)
            % Estimate the number of buildings
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double estimated building count
            nBuildings = size(obj.positions, 2);
        end
    end
end

