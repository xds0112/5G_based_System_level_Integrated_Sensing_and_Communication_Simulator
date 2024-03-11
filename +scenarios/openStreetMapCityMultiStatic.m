function simuParams = openStreetMapCityMultiStatic(simuParams)
%cellPerfomanceEvaluation 
% This scenario is based on the OpenStreetMap™ open-source data.
% It models a 5G New Radio (NR) based integrated sensing and communication
% (ISAC) network with multiple-input multiple-output (MIMO) antenna
% configuration and evaluates the network performance.

    %% Simulation time configuration 
    rng('default'); % Reset the random number generator

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
    ue1.numUEs      = 1;
    ue1.numAnts     = 2;
    ue1.radius      = 500;
    ue1.centerCoord = [100 500];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue1') = ue1;

    %% Targets configuration
    target1 = parameters.target.predefinedPosition;
    target1.cellID      = 1;
    target1.numTargets  = 1;
    target1.height      = 20;
    target1.rcs         = 1;
    target1.velocity    = randi([-10,10],1,10);
    target.userMovement.type = parameters.setting.UserMovementType.ConstPosition; % moving type
    target.userMovement.positionList = position';
    target1.position    = [-101,-1000.5,20;-51,-800.7,20;-60.8,-601,20;-41,-400.3,20;-61,-200.4,20;-40.5,0.9,20;-10.3,200.5,20;0.7,401,20;-30.7,600.4,20;-70.8,800.3,20];

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target1') = target1;
    
    %% Base station configuration
    bs1 = parameters.baseStation.gNBParameters();
    bs1.cellID         = 1;
    bs1.position       = [-501 503 30];
    % Transmission configurations
    bs1.duplexMode     = 1;
    bs1.schedulingType = 0;
    bs1.dlCarrierFreq  = 3.50e9;
    bs1.ulCarrierFreq  = 3.50e9;
    bs1.dlBandwidth    = 20e6;
    bs1.ulBandwidth    = 20e6;
    bs1.scs            = 30;
    bs1.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs1.tddSpecialSlot = [10 2 2];
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
    ue2.numUEs      = 1;
    ue2.numAnts     = 2;
    ue2.radius      = 500;
    ue2.centerCoord = [-500 -500];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue2') = ue2;

    %% Targets configuration
    target2 = parameters.target.predefinedPosition();
    target2.cellID      = 2;
    target2.numTargets  = 1;
    target2.height      = 20;
    target2.rcs         = 1;
    target2.velocity    = 10;
    target2.position    = [-500,-800,20];
%     target2.radius      = 500;
%     target2.centerCoord = [400 -500];

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target2') = target1;
    
    %% Base station configuration
    bs2 = parameters.baseStation.gNBParameters();
    bs2.cellID         = 2;
    bs2.position       = [-501 -502 30];
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
    bs2.attachedTargets = target1;

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

    %%  cell-3
    %% UEs configuration
    ue3 = parameters.user.poisson2D();
    ue3.cellID      = 3;
    ue3.numUEs      = 1;
    ue3.numAnts     = 2;
    ue3.radius      = 300;
    ue3.centerCoord = [500 -500];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue3') = ue3;

    %% Targets configuration
    target3 = parameters.target.predefinedPosition();
    target3.cellID      = 3;
    target3.numTargets  = 1;
    target3.position    = [900 -600 20];
%     target.radius      = 300;
%     target.centerCoord = [0 0];
    target3.height      = 20;
    target3.rcs         = 1;
    target3.velocity    = 10;%randi([-20, 20], target.numTargets, 1);

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target3') = target1;
    
    %% Base station configuration
    bs3 = parameters.baseStation.gNBParameters();
    bs3.cellID         = 3;
    bs3.position       = [202 -101.9 30];
    % Transmission configurations
    bs3.duplexMode     = 1;
    bs3.schedulingType = 0;
    bs3.dlCarrierFreq  = 3.50e9;
    bs3.ulCarrierFreq  = 3.50e9;
    bs3.dlBandwidth    = 20e6;
    bs3.ulBandwidth    = 20e6;
    bs3.scs            = 30;
    bs3.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs3.tddSpecialSlot = [10 2 2];
    % Antenna configurations
    bs3.txAntenna      = parameters.baseStation.antenna.upa();
    bs3.txAntenna.nH   = 8;
    bs3.txAntenna.nV   = 8;
    bs3.rxAntenna      = parameters.baseStation.antenna.upa();
    bs3.rxAntenna.nH   = 4;
    bs3.rxAntenna.nV   = 4;
    bs3.txPower        = 46;
    bs3.rxGain         = 25.5;
    % Sensing configurations
    bs3.sensing        = parameters.baseStation.sensing.radar();
    % Attached UEs
    bs3.attachedUEs     = ue3;
    bs3.attachedTargets = target1;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs3') = bs3;

    %% Scheduling strategy and traffic model configurations 
    scheduling3 = parameters.schedulingStrategies.parameters();
    scheduling3.schedulerStrategy = 'PF';
    scheduling3.attachedBS        = bs3;

    traffic3 = parameters.trafficModels.parameters();
    traffic3.trafficModel  = 'On-Off';
    traffic3.attachedUEs   = ue3;
    traffic3.dlAppDataRate = 40e3;
    traffic3.ulAppDataRate = 40e3;

    % Restore sheduling parameters in the simulation parameters
    simuParams.schedulingParameters('scheduling3') = scheduling3;
    % Restore traffic parameters in the simulation parameters
    simuParams.trafficParameters('traffic3') = traffic3;

    %% Communication channel model configuration
    pathloss3 = parameters.pathLossModels.parameters();
    pathloss3.pathLossModel = 'UMa';

    comChannel3 = parameters.channelModels.communication.cdl();
    comChannel3.delayProfile = 'CDL-D';
    comChannel3.attachedBS   = bs3;
    comChannel3.attachedUEs  = ue3;

    % Restore pathloss parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss3') = pathloss3;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel3') = comChannel3;

end

