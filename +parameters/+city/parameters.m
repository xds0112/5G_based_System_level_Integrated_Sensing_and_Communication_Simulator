classdef parameters < tools.HiddenHandle
    %PARAMETERS superclass for all city parameters
    % With this class cities can be created in a simulation by adding these
    % parameters to parameters.Parameters.cityParameters.
    %
    % initial author: Lukas Nagel
    %
    % see also parameters.Parameters.cityParameters, networkTopology.blockages.city

    properties (SetAccess = public)
        % seed value for the building height random number generator
        % initializes the random height sequence, using the same integer
        % value will produce the same building heights, using 'shuffle'
        % will produce new random values on every simulation run
        % see also: RandStream
        % [1x1]positive integer | 'shuffle'
        heightRandomSeed = 'shuffle';

        % save city to JSON file with specified name and path
        % if left empty, city is not saved
        % see also: parameters.SaveObject for saving simulation results
        % [1x1]string
        saveFile = "dataFiles/blockages/OSM_city.json";

        % load city from JSON file with specified name and path
        % if left empty, no city is loaded
        % [1x1]string
        loadFile = [];
    end

    properties (SetAccess = protected)
        % indicies of the realised buildings
        % [1 x nBuildings]integer indices of buildings of this city
        indicesBuildings
    end

    properties (Abstract, SetAccess = protected)
        createCityFunction % function that creates the city
    end

    methods (Abstract)
        % Estimate the number of buildings in the city
        % input:  [1x1]parameters.Parameters
        % output: [1x1]double estimated building count
        nBuildings = getEstimatedBuildingCount(obj, params)
    end

    methods
        function setIndices(obj, firstIndex, lastIndex)
            % setIndices sets the indices of the buildings
            %
            % input:
            %   firstIndex: [1x1]integer first index of buildings of this city
            %   lastIndex:  [1x1]integer last index of buildings of this city

            obj.indicesBuildings = firstIndex:1:lastIndex;
        end

        function copyPrivate(obj, old)
            % copy old object to this object
            %
            % input:
            %   old:	[1x1]handleObject parameters.city.Parameters

            % copy properties
            obj.createCityFunction = old.createCityFunction;
            obj.indicesBuildings   = old.indicesBuildings;
        end
    end
end

