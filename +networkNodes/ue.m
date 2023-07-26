classdef ue < networkNodes.node
%ue Create a UE node object that manages the RLC, MAC and Phy layers
%   The class creates a UE node containing the RLC, MAC and Phy layers of
%   NR protocol stack. Additionally, it models the interaction between
%   those layers through callbacks.

% Copyright 2019-2021 The MathWorks, Inc.

    properties (Access = public)
        % LOS between the BS and UE, specified as one of these options.
        % 1 (true) — Specifies the presence of LOS between the BS and UE
        % 0 (false) — Specifies the lack of LOS between the BS and UE (NLOS)
        losCondition
    end

    methods (Access = public)
        function obj = ue(param, rnti)
            %hNRUE Create a UE node
            %
            % OBJ = hNRUE(PARAM, RNTI) creates a UE node containing
            % RLC and MAC.
            % PARAM is a structure including the following fields:
            %
            % SCS                      - Subcarrier spacing
            % DuplexMode               - Duplexing mode: FDD (value 0) or TDD (value 1)
            % BSRPeriodicity           - Periodicity for the BSR packet generation
            % NumRBs                   - Number of RBs in PUSCH and PDSCH bandwidth
            % NumHARQ                  - Number of HARQ processes on UEs
            % DLULPeriodicity          - Duration of the DL-UL pattern in ms (for TDD mode)
            % NumDLSlots               - Number of full DL slots at the start of DL-UL pattern (for TDD mode)
            % NumDLSyms                - Number of DL symbols after full DL slots of DL-UL pattern (for TDD mode)
            % NumULSyms                - Number of UL symbols before full UL slots of DL-UL pattern (for TDD mode)
            % NumULSlots               - Number of full UL slots at the end of DL-UL pattern (for TDD mode)
            % SchedulingType(optional) - Slot based scheduling (value 0) or symbol based scheduling (value 1). Default value is 0
            % MaxLogicalChannels       - Maximum number of logical channels that can be configured
            % RBGSizeConfig(optional)  - RBG size configuration as 1 (configuration-1 RBG table) or 2 (configuration-2 RBG table)
            %                            as defined in 3GPP TS 38.214 Section 5.1.2.2.1. It defines the
            %                            number of RBs in an RBG. Default value is 1
            % Position                 - Position of UE in (x,y,z) coordinates
            %
            % The second input, RNTI, is the radio network temporary
            % identifier, specified within [1, 65519]. Refer table 7.1-1 in
            % 3GPP TS 38.321.
            
            % Validate UE position
            validateattributes(param.uePosition, {'numeric'}, {'numel', 3, 'nonempty', 'finite', 'nonnan'}, 'param.uePosition', 'uePosition');
            
            % Create UE MAC instance
            obj.MACEntity = communication.macLayer.ueMAC(param, rnti);
            % Initialize RLC entities cell array
            obj.RLCEntities = cell(1, obj.MaxLogicalChannels);
            % Initialize application layer
            obj.AppLayer = communication.appLayer.application('NodeID', obj.ID, 'MaxApplications', ...
                obj.MaxApplications);
            % Register the callback to implement the interaction between
            % MAC and RLC. 'sendRLCPDUs' is the callback to RLC by MAC to
            % get RLC PDUs for the uplink transmissions. 'receiveRLCPDUs'
            % is the callback to RLC by MAC to receive RLC PDUs, for the
            % received downlink packets
            obj.MACEntity.registerRLCInterfaceFcn(@obj.sendRLCPDUs, @obj.receiveRLCPDUs);

            obj.Position = param.uePosition;
        end

        function configurePhy(obj, configParam)
            %configurePhy Configure the physical layer
            %
            %   configurePhy(OBJ, CONFIGPARAM) sets the physical layer
            %   configuration.

            if isfield(configParam , 'cellID')
                % Validate cell ID
                validateattributes(configParam.cellID, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 0, '<=', 1007}, 'configParam.cellID', 'cellID');
                cellConfig.NCellID = configParam.cellID;
            else
                cellConfig.NCellID = 1;
            end
            if isfield(configParam , 'duplexMode')
                % Validate duplex mode
                validateattributes(configParam.duplexMode, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 0, '<', 2}, 'configParam.duplexMode', 'duplexMode');
                cellConfig.DuplexMode = configParam.duplexMode;
            else
                cellConfig.DuplexMode = 0;
            end
            % Set cell configuration on Phy layer instance
            setCellConfig(obj.PhyEntity, cellConfig);

            carrierInformation.SubcarrierSpacing = configParam.scs;
            carrierInformation.NRBsDL = configParam.numRBs;
            carrierInformation.NRBsUL = configParam.numRBs;
            % Validate uplink and downlink carrier frequencies
            if isfield(configParam, 'ulCarrierFreq')
                validateattributes(configParam.ulCarrierFreq, {'numeric'}, {'nonempty', 'scalar', 'finite', '>=', 0}, 'configParam.ulCarrierFreq', 'ulCarrierFreq');
                carrierInformation.ULFreq = configParam.ulCarrierFreq;
            end
            if isfield(configParam, 'dlCarrierFreq')
                validateattributes(configParam.dlCarrierFreq, {'numeric'}, {'nonempty', 'scalar', 'finite', '>=', 0}, 'configParam.dlCarrierFreq', 'dlCarrierFreq');
                carrierInformation.DLFreq = configParam.dlCarrierFreq;              
            end
            % Validate uplink and downlink bandwidth
            if isfield(configParam, 'ulBandwidth')
                validateattributes(configParam.ulBandwidth, {'numeric'}, {'nonempty', 'scalar', 'finite', '>=', 0}, 'configParam.ulBandwidth', 'ulBandwidth');
                carrierInformation.ULBandwidth = configParam.ulBandwidth;
            end
            if isfield(configParam, 'dlBandwidth')
                validateattributes(configParam.dlBandwidth, {'numeric'}, {'nonempty', 'scalar', 'finite', '>=', 0}, 'configParam.dlBandwidth', 'dlBandwidth');
                carrierInformation.DLBandwidth = configParam.dlBandwidth;
            end
            if (cellConfig.DuplexMode == 0) && ((configParam.dlCarrierFreq - configParam.ulCarrierFreq) < (configParam.dlBandwidth + configParam.ulBandwidth)/2)
                error('DL carrier frequency must be higher than UL carrier frequency by %d MHz for FDD mode', 1e-6*(configParam.dlBandwidth + configParam.ulBandwidth)/2)
            elseif cellConfig.DuplexMode && (configParam.dlCarrierFreq ~= configParam.ulCarrierFreq)
                error('DL and UL carrier frequencies must have the same value for TDD mode')
            end
            % Set carrier configuration on Phy layer instance
            setCarrierInformation(obj.PhyEntity, carrierInformation);
        end

        function setPhyInterface(obj)
            %setPhyInterface Set the interface to Phy
            
            phyEntity = obj.PhyEntity;
            macEntity = obj.MACEntity;
            
            % Register Phy interface functions at MAC for:
            % (1) Sending packets to Phy
            % (2) Sending Rx request to Phy
            % (3) Sending DL control request to Phy
            % (4) Sending UL control request to Phy
            registerPhyInterfaceFcn(obj.MACEntity, @phyEntity.txDataRequest, ...
                @phyEntity.rxDataRequest, @phyEntity.dlControlRequest, @phyEntity.ulControlRequest);
            
            % Register MAC callback function at Phy for:
            % (1) Sending the packets to MAC
            % (2) Sending the measured DL channel quality to MAC
            registerMACInterfaceFcn(obj.PhyEntity, @macEntity.rxIndication, @macEntity.csirsIndication);
            
            % Register the node object at Phy
            registerNodeWithPhy(obj.PhyEntity, obj)
        end
    end
end