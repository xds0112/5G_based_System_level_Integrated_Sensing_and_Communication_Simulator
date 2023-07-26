function simuParams = openStreetMapCity(simuParams)
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
    simuParams.roi.xSpan = 800;
    simuParams.roi.ySpan = 800;
    simuParams.roi.zSpan = 50;
    
    % Define the OpenStreetMap™ city parameters
    osmCity = parameters.city.openStreetMap();
    osmCity.longitude         = [116.3490, 116.3547];
    osmCity.latitude          = [39.9566, 39.9637];
    osmCity.streetWidth       = 5;
    osmCity.minBuildingHeight = 3;
    osmCity.maxBuildingHeight = 30;

    % Restore city parameters in the simulation parameters
    simuParams.cityParameters('osmCity') = osmCity;

    %% UEs configuration
    ue = parameters.user.poisson2D();
    ue.cellID      = 1;
    ue.numUEs      = 5;
    ue.numAnts     = 2;
    ue.radius      = 100;
    ue.centerCoord = [0 0];
    
    % Restore user parameters in the simulation parameters
    simuParams.ueParameters('ue') = ue;

    %% Targets configuration
    target = parameters.target.poisson2D();
    target.cellID      = 1;
    target.numTargets  = 1;
    target.height      = 1.5;
    target.rcs         = 1;
    target.velocity    = randi([-10, 10], target.numTargets, 1);
    target.radius      = 100;
    target.centerCoord = [0 0];

    % Restore target parameters in the simulation parameters
    simuParams.targetParameters('target') = target;
    
    %% Base station configuration
    bs = parameters.baseStation.gNBParameters();
    bs.cellID         = 1;
    bs.position       = [0 0 30];
    % Transmission configurations
    bs.duplexMode     = 1;
    bs.schedulingType = 0;
    bs.dlCarrierFreq  = 3.50e9;
    bs.ulCarrierFreq  = 3.50e9;
    bs.dlBandwidth    = 100e6;
    bs.ulBandwidth    = 100e6;
    bs.scs            = 30;
    bs.tddPattern     = ['D' 'D' 'D' 'S' 'U'];
    bs.tddSpecialSlot = [10 2 2];
    % Antenna configurations
    bs.txAntenna      = parameters.baseStation.antenna.ula();
    bs.txAntenna.nV   = 8;
    bs.rxAntenna      = parameters.baseStation.antenna.ula();
    bs.rxAntenna.nV   = 8;
    bs.txPower        = 46;
    bs.rxGain         = 25.5;
    % Sensing configurations
    bs.sensing        = parameters.baseStation.sensing.radar();
    % Attached UEs
    bs.attachedUEs     = ue;
    bs.attachedTargets = target;

    % Restore base station parameters in the simulation parameters
    simuParams.bsParameters('bs') = bs;
      
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

    %% Communication channel model configuration
    pathloss = parameters.pathLossModels.parameters();
    pathloss.pathLossModel = 'UMa';

    comChannel = parameters.channelModels.communication.cdl();
    comChannel.delayProfile = 'CDL-D';
    comChannel.attachedBS   = bs;
    comChannel.attachedUEs  = ue;

    % Restore traffic parameters in the simulation parameters
    simuParams.pathLossParameters('pathloss') = pathloss;
    % Restore traffic parameters in the simulation parameters
    simuParams.comChannelParameters('comChannel') = comChannel;

    %% Logging and visualization configuration
    simuParams.log.enableTraces     = false;
    simuParams.log.cqiVisualization = false;
    simuParams.log.rbVisualization  = false;

end

