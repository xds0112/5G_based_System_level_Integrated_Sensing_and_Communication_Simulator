classdef targetParameters
    %TARGETPARAMETERS This class creates parameters of a radar target (UE)
    %
    
    properties
        % cellID the specified cell that targets stay in
        %[1x1]interger
        cellID = 1

        % height of the target,
        %[1x1] double
        height

        % number of targets in the specified cell
        %[1x1]interger
        numTargets

        % radar cross section, in m^2
        %[numTargets x 1]double
        rcs (:, 1) double

        % radial velocity, in m/s
        %[numTargets x 1]double
        velocity (:, 1) double
    end
    
    methods
        function obj = targetParameters()
            %TARGETPARAMETERS
            % creates targetParameters class
        end
    end
end

