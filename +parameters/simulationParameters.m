classdef simulationParameters
    %SIMULATIONPARAMETERS main class where all simulation parameters are defined
    %   
    
    properties
        % simulation time parameters
        time

        % simulation region of interest parameters
        roi

        % simulation logging parameter
        log

        % simulation city layout parameters
        cityParameters

        % base station parameters
        bsParameters

        % user equipment parameters
        ueParameters

        % radar target parameters
        targetParameters

        % scheduling strategy parameters
        schedulingParameters

        % traffic model parameters
        trafficParameters

        % macroscopic pathloss parameters
        pathLossParameters

        % communication channel model parameters
        comChannelParameters

        % sensing channel model parameters
        senChannelParameters
    end
    
    methods
        function obj = simulationParameters()
            %SIMULATIONPARAMETERS
            % class constructor that sets default values
            % The class constructor initializes the class and the attached
            % parmeter classes. Geometry and network element related
            % parameters are stored in containers.

            % initialize attached classes
            obj.time = parameters.time;
            obj.roi  = parameters.regionOfInterest.region;
            obj.log  = parameters.log;

            % initialize map containers
            obj.cityParameters       = containers.Map();
            obj.bsParameters         = containers.Map();
            obj.ueParameters         = containers.Map();
            obj.targetParameters     = containers.Map();
            obj.schedulingParameters = containers.Map();
            obj.trafficParameters    = containers.Map();
            obj.pathLossParameters   = containers.Map();
            obj.comChannelParameters = containers.Map();
            obj.senChannelParameters = containers.Map();
        end
    end


end

