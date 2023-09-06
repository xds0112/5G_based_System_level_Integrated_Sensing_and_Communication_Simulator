classdef radar
    %RADAR gNB-based radar
    % creates the parameters of a gNB-based OFDM radar
    
    properties
        % radar detection area in range and velocity,
        % specified as [a b; c d] double matrix,
        % ranging from 'a' meters to 'b' meters,
        % 'c' meters per second to 'd' meters per second
        detectionArea = [50 500; -50 50]

        % False alarm rate,
        % used in constant false alarm rate detector,
        % normally set to 1e-9
        Pfa = 1e-9

        % estimation algorithm
        % normally set to 'FFT' (2D-FFT)
        estAlgorithm = 'FFT'
    end
    
    methods
        function obj = radar()
            %RADAR
        end
    end
end

