classdef city < tools.HiddenHandle
    % super class for cities
    %
    % initial author: Lukas Nagel
    % extended by: Jan Nausner
    %
    % see also blockages.StreetSystem, blockages.Building

    properties (SetAccess = protected)
        % [1x1]blockages.StreetSystem container for the streetsystem
        streetSystem

        % [1 x nBuilding]blockages.Building List of all Buildings
        buildings

        % [2x1]double (x, y) carthesian coordinates of the city origin
        origin2D

        % [1x1]positive integer seed value for the building height random number generator
        % see also: parameters.city.Parameters
        heightRandomSeed

        % [1x1]string save city to JSON file with specified name and path
        saveFile

        % [1x1]string load city from JSON file with specified name and path
        loadFile

        % [1x1]RandStream random number stream for building height generation
        randomHeightStream
    end

    methods
        function obj = city(cityParameter, interferenceRegion)
            % City constructor that inits the City superclass according to
            % the parameters passed through cityParameter
            %
            % input:
            %   cityParameter:      [1x1]handleObject parameters.city
            %   interferenceRegion: [1x1]handleObject parameters.regionOfInterest.Region
            %                       region in which blockages are placed
            %
            % see also: parameters.city.Parameters, parameters.regionOfInterest.Region

            obj.origin2D            = interferenceRegion.origin2D;
            obj.saveFile            = cityParameter.saveFile;
            obj.loadFile            = cityParameter.loadFile;
            obj.heightRandomSeed    = cityParameter.heightRandomSeed;

            % initialize random number stream with specified seed
            obj.randomHeightStream = RandStream('mt19937ar', 'Seed', cityParameter.heightRandomSeed);
        end

        function plot(obj, buildingscolour)
            % this function pots the whole city including all buildings and streets
            %
            % input:
            %    buildingscolout    [3x1]double rgb values between 1 and 0

            hold on

            if ~isempty(obj.streetSystem)
                obj.streetSystem.plot()
            end

            if ~isempty(obj.buildings)
                for building = obj.buildings
                    building.plot(buildingscolour, 0.5)
                end
            end

            hold off
        end

        function saveCityToFile(obj)
            % This function saves building and streetSystem information of
            % a city to a JSON file.
            %
            % see also: blockages.Building, blockages.StreetSystem,
            % blockages.OpenStreetMapCity, blockages.ManhattanCity

            % open specified file in write mode
            [fID, errmsg] = fopen(obj.saveFile, 'w');
            if fID < 0
                error('Error saving City to file: %s', errmsg);
            end

            % extract building information to save to file
            % this loop runs backwards so matlab can automatically
            % preallocate memory for the array
            for iBuilding = length(obj.buildings):-1:1
                b = obj.buildings(iBuilding);
                buildingData = struct("name", b.name, ...
                    "floorPlan", b.floorPlan, ...
                    "height", b.height, ...
                    "loss", b.wallList(1).loss);
                buildingsData(iBuilding) = buildingData;
            end

            % extract streetSystem information to save to file
            streetSystemData = struct("nodeLocations", obj.streetSystem.nodeLocations, ...
                "connectionMatrix", obj.streetSystem.connectionMatrix, ...
                "labels", obj.streetSystem.labels, ...
                "streetWidth", obj.streetSystem.streetWidth);

            % combine buildings and streetSystem
            cityData = struct("buildings", buildingsData, "streetSystem", streetSystemData);
            % encode buildings and streetSystem in JSON format
            encodedJSON = jsonencode(cityData);

            % write JSON string to file
            fprintf(fID, encodedJSON);
            fclose(fID);
        end

        function loadCityFromFile(obj)
            % This function loads building and streetSystem information of
            % a city from a JSON file.
            %
            % see also: blockages.Building, blockages.StreetSystem,
            % blockages.OpenStreetMapCity, blockages.ManhattanCity

            % load JSON file and decode data
            encodedJSON = fileread(obj.loadFile);
            decodedJSON = jsondecode(encodedJSON);
            fileBuildings = decodedJSON.buildings';
            fileStreetSystem = decodedJSON.streetSystem;

            % create buildings list
            obj.buildings = [];
            for ii = 1:length(fileBuildings)
                b = fileBuildings(ii);
                newBuilding = blockages.Building(b.floorPlan, b.height, b.loss, b.name);
                obj.buildings = [obj.buildings, newBuilding];
            end

            % create streetSystem object
            obj.streetSystem = blockages.StreetSystem(fileStreetSystem.nodeLocations, ...
                fileStreetSystem.connectionMatrix, ...
                fileStreetSystem.labels', ...
                fileStreetSystem.streetWidth);
        end
    end
end

