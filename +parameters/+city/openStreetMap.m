classdef openStreetMap < parameters.city.parameters
    % OpenStreetMap defines a city scenario with buildings and streets,
    % which are arranged in accordance with a real-world city layout.
    % Information about the city layout is downloaded from the
    % OpenStreetMap database, where the real-world area is specified
    % by latitudes and longitudes.
    %
    % initial author: Christoph Buchner
    % extended by: Jan Nausner
    %
    % see also networkTopology.blockages.openStreetMapCity

    properties
        % width of a street in meter
        % [1x1]double street width in meter
        streetWidth

        % minimum building height in meter
        % [1x1]double minimum building height in meter
        minBuildingHeight

        % maximum building height
        % [1x1]double maximum building height in meter
        maxBuildingHeight

        % longitude coordinates of the OSM Data witch should be plotted
        % [2x1]double (minLongitude, maxLongitude)
        longitude

        % latitude coordinates of the OSM Data witch should be plotted
        % [2x1]double (minLatitude, maxLatitude)
        latitude

        % wall loss in dB
        % [1x1]double wall loss in dB
        wallLossdB
    end

    properties (SetAccess = protected)
        % function that creates the city
        createCityFunction = @networkTopology.blockages.OpenStreetMapCity.getCity;
    end

    methods
        function getEstimatedBuildingCount(~)
            % Estimate the number of buildings in the city
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double estimated building count

            error('can''t estimate Buildingcount in OSM City')
        end
    end
end

