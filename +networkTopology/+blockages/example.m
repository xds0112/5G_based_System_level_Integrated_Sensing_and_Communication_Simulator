% example script for blockages package - shows how to create and plot blockages
%
% initial author: Christoph Buchner
%
% see also: parameters.building, parameters.city, scenarios.example,
% scenarios.ManhattanGridScenario, scenarios.openStreetMapScenario

% plot created buildings
showPlots = true;
% set building color for plots as rgb values between 0 and 1
grey = [0.75, 0.75, 0.75];

%% Building
%--------------------------------------------------------------------------
% set loss in dB of each wall traversed
wallLossdB = 10;
% set height in meter of the building
heightm = 50; % m

% set the floorplan of the building make sure to set the first corner equal
% to the last unless you want the building to be open
floorPlanX = [20,10,15,20,30,30,20]; % m
floorPlanY = [0 ,20,25,10,20,0 ,0 ]; % m
floorPlan = [floorPlanX; floorPlanY];

% invoke the constructor to build the object
bu = networkTopology.blockages.building(floorPlan, heightm, wallLossdB);

% plots the created building
if showPlots
    figure(1);
    title('building of type "blockages.Building"');
    grid on;
    transparency = 0.5;
    bu.plot(grey, transparency);
    bu.plotFloorPlan(tools.myColors.black);
end

%% WallBlockage
%--------------------------------------------------------------------------
% set loss of the wall when traversed
wallLossdB = 10; % dB

% set the corners of the Wall make sure to set the first corner equal
% to the last, also make sure the points lie on a plane
% statisfying x*a+y*b+z*c=d
% with the normal vector of the plane as [a;b;c] and
% the distance to the origin in that direction as d
cornerListX = [20,20,10,10,40,40,30,30,20]; % m
cornerListY = [ 0,20,20,25,25,20,20, 0, 0]; % m
cornerListZ = [ 0, 0, 0, 0, 0, 0, 0, 0, 0]; % m
cornerList=[cornerListX; cornerListY; cornerListZ];

% invoke the constructor to create the object
wu = networkTopology.blockages.wallBlockage(cornerList, wallLossdB);

% plots the created wall
if showPlots
    figure(2);
    title('wall and rotated wall of type "blockages.WallBlockage"');
    grid on;
    wu.plotWall(grey, 0.5);
end

%--------------------------------------------------------------------------
% To create a rotated WallBlockages, it is the easiest to use a rotation
% matrix on the non-rotated wall.
%--------------------------------------------------------------------------
% In the following section the rotation is executed in the order X Y Z keep
% in mind the previous rotations change the axis position relative to the
% object.

% create rotaion matrix

% around x Axis
alpha	= pi/180 * 45; % rad
% around y Axis
beta	= pi/180 * 45; % rad
% around z Axis
gamma	= pi/180 * 45; % rad

cx = cos(alpha);
sx = sin(alpha);
cy = cos(beta);
sy = sin(beta);
cz = cos(gamma);
sz = sin(gamma);
rotMatx = [1    0  0;  0 cx -sx;   0 sx cx];
rotMaty = [cy   0 sy;  0  1   0; -sy  0 cy];
rotMatz = [cz -sz  0; sz cz   0;   0  0  1];

% rotate corner list
cornerListRotated = rotMatz * rotMaty * rotMatx * cornerList;

% invoke the constructor  with rotated corner list to create the object
wu_rot = blockages.WallBlockage(cornerListRotated, wallLossdB);

% plot the created wall
if showPlots
    figure(2);
    wu_rot.plotWall(grey, 0.5);
end

%% OpenStreetMapCity
%--------------------------------------------------------------------------
% define borders
% make sure that the simulation region is at least as large as the region
% that is read in from the map
placementRegion = parameters.regionOfInterest.Region();
placementRegion.xSpan = 1000;
placementRegion.ySpan = 1000;
placementRegion.zSpan = 150;
placementRegion.origin2D = [0; 0];

% define city parameters
cityParameter             = parameters.city.OpenStreetMap();

% longitude coordinate [min max]
cityParameter.longitude   = [116.3492, 116.3547];
% latitude coordinate
cityParameter.latitude    = [39.9567, 39.9637];
% width for the street
cityParameter.streetWidth = 5;
% define the boundaries of the height of the buildings
cityParameter.minBuildingHeight = 10;
cityParameter.maxBuildingHeight = 50;
% use new random building heights on every run
cityParameter.heightRandomSeed  = 'shuffle';
% to manually change building heights, edit the height parameter in the
% saved JSON file after the first run and load the file on the second run
cityParameter.saveFile          = "dataFiles/blockages/OSM_city.json";
cityParameter.loadFile          = [];

% invoke the constructor to create the city
city = networkTopology.blockages.openStreetMapCity(cityParameter, placementRegion);

% plots the created city
if showPlots
    figure(4);
    title('City layout pulled from OpenStreetMap with random building heights');
    grid on;
    city.plot(grey);
end

