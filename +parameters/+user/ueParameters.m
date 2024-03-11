classdef ueParameters
    %UEPARAMETERS This class creates parameters of a user equipment (UE)
    %   see also: networkNodes.ue
    
    properties
        % cellID the specified cell that UEs stay in
        %[1x1]interger
        cellID = 1

        % height of UE's antenna,
        % normally set to 1.5m
        %[1x1] double
        height = 1.5

        % number of UEs in the specified cell
        %[1x1]interger
        numUEs

        % txPower, in dBm
        %[1x1]double
        txPower = 23

        % number of antenna elements
        %[1x1]interger
        numAnts = 2
    end

    properties (Dependent = true)
        % UE antenna array geometry for both Tx and Rx sides
        ueAntenna
    end
    
    methods
        function obj = ueParameters()
            %UEPARAMETERS 
            % creates ueParameters class
        end

        function array = get.ueAntenna(obj)
            %Setup the UE antenna array geometry
            if obj.numAnts == 1
                % In the following settings, the number of rows in antenna array, 
                % columns in antenna array, polarizations, row array panels and the
                % columns array panels are all 1
                array = ones(1,5);
            else
                % In the following settings, the no. of rows in antenna array is
                % nRxAntennas/2, the no. of columns in antenna array is 1, the no.
                % of polarizations is 2, the no. of row array panels is 1 and the
                % no. of column array panels is 1. The values can be changed to
                % create alternative antenna setups
                array = [ceil(obj.numAnts/2), 1, 2, 1, 1];
            end
            
            if prod(array) ~= obj.numAnts
                pwarningstr = ['The number of antenna elements configured '...
                               '(numAnts = %d) is not even. '...
                               'Using NRxAnts = %d instead.'];
                warning(pwarningstr, obj.numAnts, prod(array))
            end
        end
    end
end

