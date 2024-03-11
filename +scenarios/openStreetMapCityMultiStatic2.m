function simuParams = openStreetMapCityMultiStatic2(simuParams)
%cellPerfomanceEvaluation 
% This scenario is based on the OpenStreetMap™ open-source data.
% It models a 5G New Radio (NR) based integrated sensing and communication
% (ISAC) network with multiple-input multiple-output (MIMO) antenna
% configuration and evaluates the network performance.

    %% Simulation time configuration 
    rng('shuffle'); % Reset the random number generator

    simuParams.time.numFrames = 1;  % Simulation time in terms of number of 10 ms frames

    %% Simulation layout
    % Region of interest (ROI)
    simuParams.roi.xSpan = 2000;
    simuParams.roi.ySpan = 2000;
    simuParams.roi.zSpan = 50;
    
    % Define the OpenStreetMap™ city parameters
    osmCity = parameters.city.openStreetMap();
    osmCity.longitude         = [116.3654, 116.3854];
    osmCity.latitude          = [39.9498, 39.9698];
    osmCity.streetWidth       = 5;
    osmCity.minBuildingHeight = 3;
    osmCity.maxBuildingHeight = 30;

    % Restore city parameters in the simulation parameters
    simuParams.cityParameters('osmCity') = osmCity;

    %% Cell ID-1
    %% UEs configuration
    ue1 = parameters.user.poisson2D();
    ue1.cellID      = 1;
    ue1.numUEs      = 5;
    ue1.numAnts     = 2;
%     ue1.position    = [-400,480,1.5;-420,460,1.5;-440,440,1.5;-460,420,1.5;-480,400,1.5];
    ue1.radius      = 500;
    ue1.centerCoord = [-500 600];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue1') = ue1;

    %% Targets configuration
    target1 = parameters.target.predefinedPosition;
    target1.cellID      = 1;
    target1.numTargets  = 1;
    target1.height      = 10;
    target1.rcs         = 1;
    target1.velocity    = 10;
    target1.position    = [-1000,800,10];

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target1') = target1;
    
    %% Base station configuration
    bs1 = parameters.baseStation.gNBParameters();
    bs1.cellID         = 1;
    bs1.position       = [-500 600 30];
    % Transmission configurations
    bs1.duplexMode     = 1;
    bs1.schedulingType = 0;
    bs1.dlCarrierFreq  = 3.50e9;
    bs1.ulCarrierFreq  = 3.50e9;
    bs1.dlBandwidth    = 20e6;
    bs1.ulBandwidth    = 20e6;
    bs1.scs            = 30;
    bs1.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs1.tddSpecialSlot = [9 2 3];
    % Antenna configurations
    bs1.txAntenna      = parameters.baseStation.antenna.upa();
    bs1.txAntenna.nH   = 4;
    bs1.txAntenna.nV   = 4;
    bs1.rxAntenna      = parameters.baseStation.antenna.upa();
    bs1.txAntenna.nH   = 4;
    bs1.txAntenna.nV   = 4;
    bs1.txPower        = 46;
    bs1.rxGain         = 25.5;
    % Sensing configurations
    bs1.sensing        = parameters.baseStation.sensing.radar();
    % Attached UEs
    bs1.attachedUEs     = ue1;
    bs1.attachedTargets = target1;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs1') = bs1;
      
    %% Scheduling strategy and traffic model configurations 
    scheduling1 = parameters.schedulingStrategies.parameters();
    scheduling1.schedulerStrategy = 'PF';
    scheduling1.attachedBS        = bs1;

    traffic1 = parameters.trafficModels.parameters();
    traffic1.trafficModel  = 'On-Off';
    traffic1.dlAppDataRate = 40e3;
    traffic1.ulAppDataRate = 40e3;
    traffic1.attachedUEs   = ue1;

    % Restore sheduling parameters in the simulation parameters
    simuParams.schedulingParameters('scheduling1') = scheduling1;
    % Restore traffic parameters in the simulation parameters
    simuParams.trafficParameters('traffic1') = traffic1;

    %% Communication channel model configuration
    pathloss1 = parameters.pathLossModels.parameters();
    pathloss1.pathLossModel = 'UMa';

    comChannel1 = parameters.channelModels.communication.cdl();
    comChannel1.delayProfile = 'CDL-D';
    comChannel1.attachedBS   = bs1;
    comChannel1.attachedUEs  = ue1;

    % Restore pathloss parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss1') = pathloss1;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel1') = comChannel1;

    %% Cell ID-2
    %% UEs configuration
    ue2 = parameters.user.poisson2D();
    ue2.cellID      = 2;
    ue2.numUEs      = 5;
    ue2.numAnts     = 2;
%    ue2.position    = [400,-480,1.5;420,-460,1.5;440,-440,1.5;460,-420,1.5;480,-400,1.5];
    ue2.radius      = 500;
    ue2.centerCoord = [-400 400];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue2') = ue2;

    %% Targets configuration
    target2 = parameters.target.predefinedPosition();
    target2.cellID      = 2;
    target2.numTargets  = 1;
    target2.height      = 10;
    target2.rcs         = 1;
    target2.velocity    = 10;
    target2.position    = [-650,-600,10];
%     target2.radius      = 500;
%     target2.centerCoord = [400 -500];

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target2') = target2;
    
    %% Base station configuration
    bs2 = parameters.baseStation.gNBParameters();
    bs2.cellID         = 2;
    bs2.position       = [-400 400 30];
    % Transmission configurations
    bs2.duplexMode     = 1;
    bs2.schedulingType = 0;
    bs2.dlCarrierFreq  = 3.50e9;
    bs2.ulCarrierFreq  = 3.50e9;
    bs2.dlBandwidth    = 20e6;
    bs2.ulBandwidth    = 20e6;
    bs2.scs            = 30;
    bs2.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs2.tddSpecialSlot = [10 2 2];
    % Antenna configurations
    bs2.txAntenna      = parameters.baseStation.antenna.upa();
    bs2.txAntenna.nH   = 4;
    bs2.txAntenna.nV   = 4;
    bs2.rxAntenna      = parameters.baseStation.antenna.upa();
    bs2.txAntenna.nH   = 4;
    bs2.txAntenna.nV   = 4;
    bs2.txPower        = 46;
    bs2.rxGain         = 25.5;
    % Sensing configurations
    bs2.sensing        = parameters.baseStation.sensing.radar();
    % Attached UEs
    bs2.attachedUEs     = ue2;
    bs2.attachedTargets = target2;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs2') = bs2;
      
    %% Scheduling strategy and traffic model configurations 
    scheduling2 = parameters.schedulingStrategies.parameters();
    scheduling2.schedulerStrategy = 'PF';
    scheduling2.attachedBS        = bs2;

    traffic2 = parameters.trafficModels.parameters();
    traffic2.trafficModel  = 'On-Off';
    traffic2.dlAppDataRate = 40e3;
    traffic2.ulAppDataRate = 40e3;
    traffic2.attachedUEs   = ue2;

    % Restore sheduling parameters in the simulation parameters
    simuParams.schedulingParameters('scheduling2') = scheduling2;
    % Restore traffic parameters in the simulation parameters
    simuParams.trafficParameters('traffic') = traffic2;

    %% Communication channel model configuration
    pathloss2 = parameters.pathLossModels.parameters();
    pathloss2.pathLossModel = 'UMa';

    comChannel2 = parameters.channelModels.communication.cdl();
    comChannel2.delayProfile = 'CDL-D';
    comChannel2.attachedBS   = bs2;
    comChannel2.attachedUEs  = ue2;

    % Restore pathloss parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss2') = pathloss2;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel2') = comChannel2;

    %% Logging and visualization configuration
    simuParams.log.enableTraces     = false;
    simuParams.log.cqiVisualization = false;
    simuParams.log.rbVisualization  = false;

