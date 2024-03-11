classdef ula
    %UNIFORMLINEARARRAY 
    %   Uniform linear array (ULA)
    
    properties
        % number of antenna elements (vertical direction)
        % [1x1] integer
        nV = 8

        % element spacing,, divided by wavelength lambda
        % normally set to 0.5
        % [1x1] double
        d = 0.5

        % number of polarizations (1 or 2)
        p = 2

        % sector setting, 'omnidirectional' or 'threeSectors'
        sector = 'omnidirectional'
    end

    properties (Dependent = true)
        % number of array elements
        numElements

        % array geometry for channel transmission
        % M:  no. of rows in each antenna panel
        % N:  no. of columns in each antenna panel
        % P:  no. of polarizations (1 or 2)
        % Mg: no. of rows in the array of panels
        % Ng: no. of columns in the array of panels
        % Row format: [M  N   P   Mg  Ng]
        arrayGeometry
    end
    
    methods
        function obj = ula()
            %UNIFORMPANALARARRAY
            % creates a ULA class
        end

        function nE = get.numElements(obj)
            %NUMELEMENTS
            % compute number of array elements
            nE = obj.nV * obj.p;
        end

        function arrayGeometry = get.arrayGeometry(obj)
            %ArrayGeometry 
            % set the array geometry
            arrayGeometry = [1  obj.nV  obj.p  1  1];
        end
    end
end

