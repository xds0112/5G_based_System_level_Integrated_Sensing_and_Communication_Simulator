classdef predefinedPosition < parameters.target.targetParameters
    %PREDEFINEDPOSITIONS 
    %  Target parameters class with pre-defined positions
    
    properties
        % target positions, (x, y, z) coordinates
        %[n x 3] matrix
        position (:,3) double
    end
    
    methods
        function obj = predefinedPosition()
            %PREDEFINEDPOSITIONS 
            % Targets with pre-defined positions
            obj@parameters.target.targetParameters
        end
    end
end

