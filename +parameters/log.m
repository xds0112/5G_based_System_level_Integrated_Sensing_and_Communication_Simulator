classdef log
    %LOG creates a simulation log class
    %   simulation logging parameter
    
    properties
        % Set the |enableTraces| parameter to |true| to log the traces. 
        % If the |enableTraces| parameter is set to |false|, 
        % then |cqiVisualization| and |rbVisualization| are disabled
        % automatically and traces are not logged in the simulation. 
        % To speed up the simulation, set the |enableTraces| to |false|.
        enableTraces = false

        % The |cqiVisualization| parameter controls the display
        % of the CQI visualization
        cqiVisualization = false 

        % |rbVisualization| parameters control the display of
        % the RB assignment visualization
        rbVisualization = false
    end
    
    methods
        function obj = log()
            %LOG 
            % creates a simulation log class
        end
    end
end

