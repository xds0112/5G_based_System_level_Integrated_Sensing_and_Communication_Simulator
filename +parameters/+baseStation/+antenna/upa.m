classdef upa
    %UNIFORMPANALARARRAY 
    %   Uniform planar array (UPA) as specified in TS 38.901
    
    properties
        % number of antenna elements per panel (vertical direction)
        % [1x1] integer
        nV = 8

        % number of antenna elements per panel (horizontal direction)
        % [1x1] integer
        nH = 8

        % number of panels (vertical direction)
        % [1x1] integer
        nPV = 1

        % number of panels (horizontal direction)
        % [1x1] integer
        nPH = 1

        % vertical element spacing, divided by wavelength lambda
        % normally set to 0.5
        % [1x1] double
        dV = 0.5

        % horizontal element spacing, divided by wavelength lambda
        % normally set to 0.5
        % [1x1] double
        dH = 0.5

        % vertical panel spacing, divided by wavelength lambda
        % normally set to 3
        % [1x1] double
        dPV = 3

        % horizontal panel spacing, divided by wavelength lambda
        % normally set to 3
        % [1x1] double
        dPH = 3

        % number of polarizations (1 or 2)
        p = 1

        % sector setting, 'three-sector' or 'omni-directional'
        sector = 'three-sector'
    end

    properties (Dependent = true)
        % number of antenna elements
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
        function obj = upa()
            %UNIFORMPANALARARRAY
            % creates a UPA class
        end

        function nE = get.numElements(obj)
            %NUMELEMENTS
            % compute number of antenna elements
            nE = obj.nH * obj.nV * obj.p * obj.nPH * obj.nPV;
        end

        function arrayGeometry = get.arrayGeometry(obj)
            %ArrayGeometry 
            % set the array geometry
            arrayGeometry = [obj.nH  obj.nV  obj.p  obj.nPH  obj.nPV];
        end
    end
end

