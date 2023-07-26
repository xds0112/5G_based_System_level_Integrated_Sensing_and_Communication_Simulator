classdef parameters < tools.HiddenHandle
    %PARAMETERS superclass for building placement scenarios
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.Parameters.buildingParameters,
    % networkTopology.blockages.building

    properties (SetAccess = private)
        % the indices of the realisations
        % [1 x nBuildings]integer indices of buildings of this type
        indices
    end

    properties (Abstract, SetAccess = private)
        createBuildingsFunction % creates the actual buildings
    end

    methods (Abstract)
        % Estimate the number of buildings
        % input:  [1x1]parameters.Parameters
        % output: [1x1]double estimated building count
        nBuildings = getEstimatedBuildingCount(obj, params)
    end

    methods
        function setIndices(obj, firstIndex, lastIndex)
            % setIndices sets the indices of the realisations
            %
            % input:
            %   firstIndex: [1x1]integer first index of buildings of this type
            %   lastIndex:  [1x1]integer last index of buildings of this type

            obj.indices = firstIndex:1:lastIndex;
        end

        function copyPrivate(obj, old)
            % copy old object into this object
            %
            % input:
            %   old:    [1x1]handleObject parameters.building.Parameters

            % copy class properties
            obj.createBuildingsFunction = old.createBuildingsFunction;
        end
    end
end

