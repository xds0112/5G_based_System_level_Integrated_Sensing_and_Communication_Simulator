classdef parameters
    %PARAMETERS scheduling parameters
    %   Specify the scheduling strategy and the maximum limit on the RBs allotted
    % for PDSCH and PUSCH. The transmission limit applies only to new transmissions
    % and not to the retransmissions
    % see also: communication.scheduling
    
    properties
        % scheduler strategy
        % Supported strategies: 'RR' (Round robin), 
        % 'PF' (Proportional fair), and 'BestCQI'
        schedulerStrategy = 'RR'

        % attached BS
        attachedBS

        % mini-slot
        % specified as one of these numbers: 2, 4, 7,
        % only in the symbol based TDD mode,
        %[1x1] integer
        ttiGranularity = 2
    end

    properties (Dependent = true)
        % number of resource blocks under scheduling
        %[1x1] integer
        numRBs

        % resource block allocation limit for PUSCH
        %[1x1] integer
        rbAllocationLimitUL

        % resource block allocation limit for PDSCH
        %[1x1] integer
        rbAllocationLimitDL
    end
    
    methods
        function obj = parameters()
            %PARAMETERS
            % creates scheduling parameters class
        end

        function nRBs = get.numRBs(obj)
            % get number of resource blocks under scheduling
            nRBs = obj.attachedBS.numRBs;
        end

        function ulLimit = get.rbAllocationLimitUL(obj)
            % get resource block allocation limit for PUSCH
            ulLimit = obj.numRBs;
        end

        function dlLimit = get.rbAllocationLimitDL(obj)
            % get resource block allocation limit for PUSCH
            dlLimit = obj.numRBs;
        end
    end
end

