classdef gNBParameters
    %GNB This class creates parameters of a 5G NR base station (next generation nodeB, gNB)
    %   see also: networkNodes.gNB
    
    properties (Access = public)
        % physical cell/gNB identity
        %[1x1] integer
        cellID {mustBeInteger, mustBeInRange(cellID, 0, 1007)} = 1

        % gNB position, (x, y, z) coordinates, in m
        %[3x1] double
        position = [0 0 0] 

        % duplex mode, defined as TDD or FDD
        % '0' stands for FDD, '1' stands for TDD
        %[1x1] integer
        duplexMode {mustBeInteger, mustBeInRange(duplexMode, 0, 1)} = 1

        % scheduling type, defined as slot-based or symbol-based
        % '0' stands for 'slot based', '1' stands for 'symbol based'
        %[1x1] integer
        schedulingType {mustBeInteger, mustBeInRange(schedulingType, 0, 1)} = 0

        % antenna transmitting power, in dBm
        %[1x1] double
        txPower

        % antenna receiving gain, in dBi
        %[1x1] double
        rxGain

        % antenna noise figure, in dB
        % normally set to 6
        %[1x1] double
        noiseFigure = 6

        % antenna temperature, in Kelvin
        % normally set to 290
        %[1x1] double
        antTemperature = 290

        % attached UEs
        % see also: parameters.user
        attachedUEs

        % attached targets
        % see also: parameters.target
        attachedTargets

        % downlink carrier frequency, in Hz
        % 3GPP TS 38.104 Section 5.3.2.
        %[1x1] double
        dlCarrierFreq

        % uplink carrier frequency, in Hz
        % 3GPP TS 38.104 Section 5.3.2.
        %[1x1] double
        ulCarrierFreq

        % downlink bandwidth, in Hz
        % 3GPP TS 38.104 Section 5.3.2.
        %[1x1] double
        dlBandwidth

        % uplink bandwidth, in Hz
        % 3GPP TS 38.104 Section 5.3.2.
        %[1x1] double
        ulBandwidth

        % subcarrier spacing, in kHz
        %[1x1] integer
        scs {mustBeInteger} = 30

        % DL-UL pattern in TDD mode
        %[n x 1] string vector
        tddPattern 

        % special slot in TDD mode
        %[3x1] integer
        tddSpecialSlot

        % transmitting antenna
        % see also: parameters.baseStation.antenna
        txAntenna

        % receiving antenna
        % see also: parameters.baseStation.antenna
        rxAntenna

        % sensing parameters
        % used to configure the gNB-based radar
        % see also: parameters.baseStation.sensing
        sensing
    end

    properties (Dependent = true)
        % gNB type, defined as 'Macro' or 'Micro'
        type

        % number of physical RBs
        numRBs

        % the slot duration for the selected subcarrier spacing
        slotDuration

        % the number of slots in a 10 ms frame
        numSlotsFrame

        % TDD configurations
        tddConfig
    end
    
    methods
        function obj = gNBParameters()
            %GNB 
            % Create gNB parameters class
        end

        function type = get.type(obj)
            %DetermineType 
            % Determine the gNB type
            if (obj.dlCarrierFreq > 0.410e9) && (obj.dlCarrierFreq <= 7.625e9)
                type = 'Macro';
            elseif (obj.dlCarrierFreq > 24.250e9) && (obj.dlCarrierFreq <= 52.600e9)
                type = 'Micro';
            else
                type = 'Not defined in the 3GPP standards';
            end
        end
        
        function numRBs = get.numRBs(obj)
            %DETERMINENUMRBS 
            % Determine the number of physical resource blocks
            if (obj.tddPattern == 0) % FDD duplex mode
                numRBs = communication.determinePRB(obj.dlCarrierFreq, obj.dlBandwidth + obj.ulBandwidth, obj.scs);
            else % TDD duplex mode
                numRBs = communication.determinePRB(obj.dlCarrierFreq, obj.dlBandwidth, obj.scs);
            end
        end

        function slotDuration = get.slotDuration(obj)
            %COMPUTENUMSLOTS
            % Compute the slot duration for the selected SCS
            slotDuration  = 1/(obj.scs/15);      % In ms
        end

        function numSlotsFrame = get.numSlotsFrame(obj)
            % Compute the the number of slots in a 10 ms frame
            numSlotsFrame = 10/obj.slotDuration; % Number of slots in a 10 ms frame
        end

        function tddConfig = get.tddConfig(obj)
            %CONFIGTDDPATTERN 
            % Configure the TDD DL-UL pattern.   

            if ~obj.duplexMode % If the current duplex mode is FDD, exist the function 
                return
            end

            tddConfig = struct;
        
            % Number of slots in the DL-UL pattern    
            numSlotsPerPattern = numel(obj.tddPattern);
        
            % Calculate the number of consecutive DL and UL symbols
            dlMatches = regexp(obj.tddPattern, 'D+', 'match');
            ulMatches = regexp(obj.tddPattern, 'U+', 'match');
            numDLOccurrences = cellfun(@length, dlMatches);
            numULOccurrences = cellfun(@length, ulMatches);
        
            % Validate the special slot
            if sum(obj.tddSpecialSlot) ~= 14
                error('The special slot must contain 14 OFDM symbols')
            end

            % update the DL-UL configurations
            tddConfig.numDLSlots      = numDLOccurrences; % number of consecutive full DL slots at the beginning of each DL-UL pattern
            tddConfig.numULSlots      = numULOccurrences; % number of consecutive full UL slots at the end of each DL-UL pattern
            tddConfig.numDLSyms       = obj.tddSpecialSlot(1); % Number of consecutive DL symbols in the flexible slot
            tddConfig.numULSyms       = obj.tddSpecialSlot(3); % Number of consecutive UL symbols in the flexible slot
            tddConfig.dlulPeriodicity = obj.slotDuration*numSlotsPerPattern; % Duration of the DL-UL pattern in ms 
        end
    end

end

