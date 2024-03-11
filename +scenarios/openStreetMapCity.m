function simuParams = openStreetMapCity(simuParams)
%cellPerfomanceEvaluation 
% This scenario is based on the OpenStreetMap™ open-source data.
% It models a 5G New Radio (NR) based integrated sensing and communication
% (ISAC) network with multiple-input multiple-output (MIMO) antenna
% configuration and evaluates the network performance.

    %% Simulation time configuration 
    rng('shuffle'); % Reset the random number generator

    simuParams.time.numFrames = 1;  % Simulation time in terms of number of 10 ms frames

    %% 参数初始化
    % 将距离、角度参数转化为笛卡尔坐标
    % 1为直线，2为菱形，3为三角形
    position = datatrans(1);

    %% Simulation layout
    % Region of interest (ROI)
    simuParams.roi.xSpan = 1000;
    simuParams.roi.ySpan = 1000;
    simuParams.roi.zSpan = 50;
    
    % Define the OpenStreetMap™ city parameters
    osmCity = parameters.city.openStreetMap();
    osmCity.longitude         = [116.3654, 116.3854];
    osmCity.latitude          = [39.9498, 39.9698];
    osmCity.streetWidth       = 5;
    osmCity.minBuildingHeight = 5;
    osmCity.maxBuildingHeight = 35;

    % Restore city parameters in the simulation parameters
    simuParams.cityParameters('osmCity') = osmCity;

    %% UEs configuration
    ue = parameters.user.poisson2D();
    ue.cellID      = 1;
    ue.numUEs      = 1;
    ue.numAnts     = 2;
%     ue.position    = [-100,0,1.5];
    ue.radius      = 250*sqrt(3)/2;
    ue.centerCoord = [0 0];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue') = ue;

%     ue1 = parameters.user.poisson2D();
%     ue1.cellID      = 2;
%     ue1.numUEs      = 0;
%     ue1.numAnts     = 2;
% %     ue.position    = [-100,0,1.5];
%     ue1.radius      = 250*sqrt(3)/2;
%     ue1.centerCoord = [0 0];
%     
%     % Restore user parameters in the simulation parameters
%     simuParams.ueParameters('ue1') = ue1;
% 
%     ue2 = parameters.user.poisson2D();
%     ue2.cellID      = 2;
%     ue2.numUEs      = 0;
%     ue2.numAnts     = 2;
% %     ue.position    = [-100,0,1.5];
%     ue2.radius      = 250*sqrt(3)/2;
%     ue2.centerCoord = [0 0];
%     
%     % Restore user parameters in the simulation parameters
%     simuParams.ueParameters('ue2') = ue2;
% 
%     ue3 = parameters.user.poisson2D();
%     ue3.cellID      = 2;
%     ue3.numUEs      = 0;
%     ue3.numAnts     = 2;
% %     ue.position    = [-100,0,1.5];
%     ue3.radius      = 250*sqrt(3)/2;
%     ue3.centerCoord = [0 0];
%     
%     % Restore user parameters in the simulation parameters
%     simuParams.ueParameters('ue3') = ue3;

%     ue4 = parameters.user.poisson2D();
%     ue4.cellID      = 2;
%     ue4.numUEs      = 5;
%     ue4.numAnts     = 2;
% %     ue.position    = [-100,0,1.5];
%     ue4.radius      = 300;
%     ue4.centerCoord = [-500 0];
%     
%     % Restore user parameters in the simulation parameters
%     simuParams.ueParameters('ue4') = ue4;

    %% Targets configuration
    target = parameters.target.poisson2D();
    target.cellID      = 1;
    target.numTargets  = 2;
%     target.position    = [0,200,30];
    target.radius      = 250*sqrt(3)/2;
    target.centerCoord = [0 0];
    target.height      = 40;
    target.rcs         = 1;
    target.velocity    = randi([-20, 20], target.numTargets, 1);
    target.userMovement.type = parameters.setting.UserMovementType.RandConstDirection; % moving type
    %target.userMovement.positionList = position';

    simuParams.targetParameters('randmovetarget') = target;

%     target1 = parameters.target.poisson2D();
%     target1.cellID      = 1;
%     target1.numTargets  = 1;
%     target1.radius      = 300;
%     target1.centerCoord = [0 0];
%     target1.height      = 20;
%     target1.rcs         = 1;
%     target1.velocity    = randi([-20, 20], target1.numTargets, 1);
%     target1.userMovement.type = parameters.setting.UserMovementType.Predefined; % moving type
%     target1.userMovement.positionList = position';
% 
%     simuParams.targetParameters('constmovetarget') = target1;
    
    %% Base station configuration
    bs = parameters.baseStation.gNBParameters();
    bs.cellID         = 1;
    bs.position       = [-250 0 30];
    % Transmission configurations
    bs.duplexMode     = 1;
    bs.schedulingType = 0;
    bs.dlCarrierFreq  = 3.50e9;
    bs.ulCarrierFreq  = 3.50e9;
    bs.dlBandwidth    = 20e6;
    bs.ulBandwidth    = 20e6;
    bs.scs            = 30;
    bs.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs.tddSpecialSlot = [10 2 2];
    % Antenna configurations
    bs.txAntenna      = parameters.baseStation.antenna.upa();
    bs.txAntenna.nH   = 8;
    bs.txAntenna.nV   = 8;
    bs.rxAntenna      = parameters.baseStation.antenna.upa();
    bs.rxAntenna.nH   = 4;
    bs.rxAntenna.nV   = 4;
    bs.txPower        = 46;
    bs.rxGain         = 25.5;

    % Sensing configurations
    bs.sensing              = parameters.baseStation.sensing.radar();
    bs.sensing.detectionfre = 0.5;
    % Attached UEs
    bs.attachedUEs     = ue;
    bs.attachedTargets = target;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs') = bs;

    bs1 = parameters.baseStation.gNBParameters();
    bs1.cellID         = 1;
    bs1.position       = [250 0 30];
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
    bs1.txAntenna.nH   = 8;
    bs1.txAntenna.nV   = 8;
    bs1.rxAntenna      = parameters.baseStation.antenna.upa();
    bs1.rxAntenna.nH   = 4;
    bs1.rxAntenna.nV   = 4;
    bs1.txPower        = 46;
    bs1.rxGain         = 25.5;

    % Sensing configurations
    bs1.sensing        = parameters.baseStation.sensing.radar();
    bs1.sensing.detectionfre = 0.5;
    % Attached UEs
    bs1.attachedUEs     = ue;
    bs1.attachedTargets = target;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs1') = bs1;
% 
%     bs2 = parameters.baseStation.gNBParameters();
%     bs2.cellID         = 1;
%     bs2.position       = [0 250*sqrt(3) 30];
%     % Transmission configurations
%     bs2.duplexMode     = 1;
%     bs2.schedulingType = 0;
%     bs2.dlCarrierFreq  = 3.50e9;
%     bs2.ulCarrierFreq  = 3.50e9;
%     bs2.dlBandwidth    = 20e6;
%     bs2.ulBandwidth    = 20e6;
%     bs2.scs            = 30;
%     bs2.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
%     bs2.tddSpecialSlot = [10 2 2];
%     % Antenna configurations
%     bs2.txAntenna      = parameters.baseStation.antenna.upa();
%     bs2.txAntenna.nH   = 8;
%     bs2.txAntenna.nV   = 8;
%     bs2.rxAntenna      = parameters.baseStation.antenna.upa();
%     bs2.rxAntenna.nH   = 4;
%     bs2.rxAntenna.nV   = 4;
%     bs2.txPower        = 46;
%     bs2.rxGain         = 25.5;
% 
%     % Sensing configurations
%     bs2.sensing        = parameters.baseStation.sensing.radar();
%     bs2.sensing.detectionfre = 0.5;
%     % Attached UEs
%     bs2.attachedUEs     = ue;
%     bs2.attachedTargets = target;
% 
%     % Restore base station parameters in the simulation parameters
%     simuParams.bsParameters('bs2') = bs2;
% 
%     bs3 = parameters.baseStation.gNBParameters();
%     bs3.cellID         = 1;
%     bs3.position       = [0 -250*sqrt(3) 30];
%     % Transmission configurations
%     bs3.duplexMode     = 1;
%     bs3.schedulingType = 0;
%     bs3.dlCarrierFreq  = 3.50e9;
%     bs3.ulCarrierFreq  = 3.50e9;
%     bs3.dlBandwidth    = 20e6;
%     bs3.ulBandwidth    = 20e6;
%     bs3.scs            = 30;
%     bs3.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
%     bs3.tddSpecialSlot = [10 2 2];
%     % Antenna configurations
%     bs3.txAntenna      = parameters.baseStation.antenna.upa();
%     bs3.txAntenna.nH   = 8;
%     bs3.txAntenna.nV   = 8;
%     bs3.rxAntenna      = parameters.baseStation.antenna.upa();
%     bs3.rxAntenna.nH   = 4;
%     bs3.rxAntenna.nV   = 4;
%     bs3.txPower        = 46;
%     bs3.rxGain         = 25.5;
% 
%     % Sensing configurations
%     bs3.sensing        = parameters.baseStation.sensing.radar();
%     bs3.sensing.detectionfre = 0.5;
%     % Attached UEs
%     bs3.attachedUEs     = ue;
%     bs3.attachedTargets = target;
% 
%     % Restore base station parameters in the simulation parameters
%     simuParams.bsParameters('bs3') = bs3;

%     bs4 = parameters.baseStation.gNBParameters();
%     bs4.cellID         = 1;
%     bs4.position       = [-500 0 30];
%     % Transmission configurations
%     bs4.duplexMode     = 1;
%     bs4.schedulingType = 0;
%     bs4.dlCarrierFreq  = 3.50e9;
%     bs4.ulCarrierFreq  = 3.50e9;
%     bs4.dlBandwidth    = 20e6;
%     bs4.ulBandwidth    = 20e6;
%     bs4.scs            = 30;
%     bs4.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
%     bs4.tddSpecialSlot = [10 2 2];
%     % Antenna configurations
%     bs4.txAntenna      = parameters.baseStation.antenna.upa();
%     bs4.txAntenna.nH   = 8;
%     bs4.txAntenna.nV   = 8;
%     bs4.rxAntenna      = parameters.baseStation.antenna.upa();
%     bs4.rxAntenna.nH   = 4;
%     bs4.rxAntenna.nV   = 4;
%     bs4.txPower        = 46;
%     bs4.rxGain         = 25.5;
% 
%     % Sensing configurations
%     bs4.sensing        = parameters.baseStation.sensing.radar();
%     bs4.sensing.detectionfre = 0.5;
%     % Attached UEs
%     bs4.attachedUEs     = ue4;
%     bs4.attachedTargets = target;
% 
%     % Restore base station parameters in the simulation parameters
%     simuParams.bsParameters('bs4') = bs4;

    %% Scheduling strategy and traffic model configurations 
    scheduling = parameters.schedulingStrategies.parameters();
    scheduling.schedulerStrategy = 'PF';
    scheduling.attachedBS        = bs;

    traffic = parameters.trafficModels.parameters();
    traffic.trafficModel  = 'On-Off';
    traffic.attachedUEs   = ue;
    traffic.dlAppDataRate = 40e3;
    traffic.ulAppDataRate = 40e3;

    % Restore sheduling parameters in the simulation parameters
    simuParams.schedulingParameters('scheduling') = scheduling;
    % Restore traffic parameters in the simulation parameters
    simuParams.trafficParameters('traffic') = traffic;

    scheduling1 = parameters.schedulingStrategies.parameters();
    scheduling1.schedulerStrategy = 'PF';
    scheduling1.attachedBS        = bs1;

    traffic1 = parameters.trafficModels.parameters();
    traffic1.trafficModel  = 'On-Off';
    traffic1.attachedUEs   = ue;
    traffic1.dlAppDataRate = 40e3;
    traffic1.ulAppDataRate = 40e3;

    % Restore sheduling parameters in the simulation parameters
    simuParams.schedulingParameters('scheduling1') = scheduling1;
    % Restore traffic parameters in the simulation parameters
    simuParams.trafficParameters('traffic1') = traffic1;
% 
%     scheduling2 = parameters.schedulingStrategies.parameters();
%     scheduling2.schedulerStrategy = 'PF';
%     scheduling2.attachedBS        = bs2;
% 
%     traffic2 = parameters.trafficModels.parameters();
%     traffic2.trafficModel  = 'On-Off';
%     traffic2.attachedUEs   = ue;
%     traffic2.dlAppDataRate = 40e3;
%     traffic2.ulAppDataRate = 40e3;
% 
%     % Restore sheduling parameters in the simulation parameters
%     simuParams.schedulingParameters('scheduling2') = scheduling2;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.trafficParameters('traffic2') = traffic2;
% 
%     scheduling3 = parameters.schedulingStrategies.parameters();
%     scheduling3.schedulerStrategy = 'PF';
%     scheduling3.attachedBS        = bs3;
% 
%     traffic3 = parameters.trafficModels.parameters();
%     traffic3.trafficModel  = 'On-Off';
%     traffic3.attachedUEs   = ue;
%     traffic3.dlAppDataRate = 40e3;
%     traffic3.ulAppDataRate = 40e3;
% 
%     % Restore sheduling parameters in the simulation parameters
%     simuParams.schedulingParameters('scheduling3') = scheduling3;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.trafficParameters('traffic3') = traffic3;
% 
%     scheduling4 = parameters.schedulingStrategies.parameters();
%     scheduling4.schedulerStrategy = 'PF';
%     scheduling4.attachedBS        = bs4;
% 
%     traffic4 = parameters.trafficModels.parameters();
%     traffic4.trafficModel  = 'On-Off';
%     traffic4.attachedUEs   = ue4;
%     traffic4.dlAppDataRate = 40e3;
%     traffic4.ulAppDataRate = 40e3;
% 
%     % Restore sheduling parameters in the simulation parameters
%     simuParams.schedulingParameters('scheduling4') = scheduling4;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.trafficParameters('traffic4') = traffic4;

    %% Communication channel model configuration
    pathloss = parameters.pathLossModels.parameters();
    pathloss.pathLossModel = 'UMa';

    comChannel = parameters.channelModels.communication.cdl();
    comChannel.delayProfile = 'CDL-D';
    comChannel.attachedBS   = bs;
    comChannel.attachedUEs  = ue;

    % Restore pathloss parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss') = pathloss;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel') = comChannel;

    pathloss1 = parameters.pathLossModels.parameters();
    pathloss1.pathLossModel = 'UMa';

    comChannel1 = parameters.channelModels.communication.cdl();
    comChannel1.delayProfile = 'CDL-D';
    comChannel1.attachedBS   = bs1;
    comChannel1.attachedUEs  = ue;

    % Restore pathloss parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss1') = pathloss1;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel1') = comChannel1;
% 
%     pathloss2 = parameters.pathLossModels.parameters();
%     pathloss2.pathLossModel = 'UMa';
% 
%     comChannel2 = parameters.channelModels.communication.cdl();
%     comChannel2.delayProfile = 'CDL-D';
%     comChannel2.attachedBS   = bs2;
%     comChannel2.attachedUEs  = ue;
% 
%     % Restore pathloss parameters in the simulation parameters
%     simuParams.pathLossParameters('pathloss2') = pathloss2;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.comChannelParameters('comChannel2') = comChannel2;
% 
%     pathloss3 = parameters.pathLossModels.parameters();
%     pathloss3.pathLossModel = 'UMa';
% 
%     comChannel3 = parameters.channelModels.communication.cdl();
%     comChannel3.delayProfile = 'CDL-D';
%     comChannel3.attachedBS   = bs3;
%     comChannel3.attachedUEs  = ue;
% 
%     % Restore pathloss parameters in the simulation parameters
%     simuParams.pathLossParameters('pathloss3') = pathloss3;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.comChannelParameters('comChannel3') = comChannel3;
% 
%     pathloss4 = parameters.pathLossModels.parameters();
%     pathloss4.pathLossModel = 'UMa';
% 
%     comChannel4 = parameters.channelModels.communication.cdl();
%     comChannel4.delayProfile = 'CDL-D';
%     comChannel4.attachedBS   = bs4;
%     comChannel4.attachedUEs  = ue4;
% 
%     % Restore pathloss parameters in the simulation parameters
%     simuParams.pathLossParameters('pathloss4') = pathloss4;
%     % Restore traffic parameters in the simulation parameters
%     simuParams.comChannelParameters('comChannel4') = comChannel4;

    %% Logging and visualization configuration
    simuParams.log.enableTraces     = false;
    simuParams.log.cqiVisualization = false;
    simuParams.log.rbVisualization  = false;

end

