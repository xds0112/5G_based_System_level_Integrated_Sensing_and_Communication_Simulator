classdef predefinedPosition < parameters.user.ueParameters
    %PREDEFINEDPOSITIONS 
    %  UE parameters class with pre-defined positions
    
    properties
        % UE positions, (x, y, z) coordinates
        %[n x 3] matrix
        position (:,3) double
    end
    
    methods
        function obj = predefinedPosition()
            %PREDEFINEDPOSITIONS 
            % UEs with pre-defined positions
            obj@parameters.user.ueParameters
        end
    end
end

