classdef gNB < networkNodes.node
%gNB Create a gNB node object that manages the RLC, MAC and Phy layers
%   The class creates a gNB node containing the RLC, MAC and Phy layers of
%   NR protocol stack. Additionally, it models the interaction between
%   those layers through callbacks.

% Copyright 2019-2021 The MathWorks, Inc.

    methods (Access = public)
        function obj = gNB(param)
            %hNRGNB Create a gNB node
            %
            %   OBJ = hNRGNB(PARAM) creates a gNB node containing RLC and MAC.
            %   PARAM is a structure with following fields:
            %       NumUEs                   - Number of UEs in the cell
            %       SCS                      - Subcarrier spacing used
            %       NumHARQ                  - Number of HARQ processes
            %       MaxLogicalChannels       - Maximum number of logical channels that can be configured
            %       Position                 - Position of gNB in (x,y,z) coordinates
            
            % Validate the number of UEs
            validateattributes(param.numUEs, {'numeric'}, {'nonempty', ...
                'integer', 'scalar', '>', 0, '<=', 65519}, 'param.numUEs', 'numUEs');
            % Validate gNB position
            validateattributes(param.gNBPosition, {'numeric'}, {'numel', 3, ...
                'nonempty', 'finite', 'nonnan'}, 'param.gNBPosition', 'gNBPosition');

            % Create gNB MAC instance
            obj.MACEntity = communication.macLayer.gNBMAC(param);
            % Initialize RLC entities cell array
            obj.RLCEntities = cell(param.numUEs, obj.MaxLogicalChannels);
            % Initialize application layer
            obj.AppLayer = communication.appLayer.application('NodeID', obj.ID, 'MaxApplications', ...
                obj.MaxApplications * param.numUEs);
            % Register the callback to implement the interaction between
            % MAC and RLC. 'sendRLCPDUs' is the callback to RLC by MAC to
            % get RLC PDUs for the downlink transmissions. 'receiveRLCPDUs'
            % is the callback to RLC by MAC to receive RLC PDUs, for the
            % received uplink packets
            registerRLCInterfaceFcn(obj.MACEntity, @obj.sendRLCPDUs, @obj.receiveRLCPDUs);

            obj.Position = param.gNBPosition;
        end

        function configurePhy(obj, configParam)
            %configurePhy Configure the physical layer
            %
            %   configurePhy(OBJ, CONFIGPARAM) sets the physical layer
            %   configuration.
            
            % Validate number of RBs
            validateattributes(configParam.numRBs, {'numeric'}, {'integer', 'scalar', '>=', 1, '<=', 275}, 'configParam.numRBs', 'numRBs');

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

            % Validate the subcarrier spacing
            if ~ismember(configParam.scs, [15 30 60 120 240])
                error('The subcarrier spacing ( %d ) must be one of the set (15, 30, 60, 120, 240).', configParam.scs);
            end

            carrierInformation.SubcarrierSpacing = configParam.scs;
            carrierInformation.NRBsDL = configParam.numRBs;
            carrierInformation.NRBsUL = configParam.numRBs;
            % Validate the uplink and downlink carrier frequencies
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
                error('nr5g:gNB:InsufficientDuplexSpacing', 'DL carrier frequency must be higher than UL carrier frequency by %d MHz for FDD mode', 1e-6*(configParam.dlBandwidth + configParam.ulBandwidth)/2)
            elseif cellConfig.DuplexMode && (configParam.dlCarrierFreq ~= configParam.ulCarrierFreq)
                error('nr5g:gNB:InvalidCarrierFrequency', 'DL and UL carrier frequencies must have the same value for TDD mode')
            end
            % Set carrier configuration on Phy layer instance);
            setCarrierInformation(obj.PhyEntity, carrierInformation)
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
            % (2) Sending the measured UL channel quality to MAC
            registerMACInterfaceFcn(obj.PhyEntity, @macEntity.rxIndication, @macEntity.srsIndication);
            
            % Register node object at Phy
            registerNodeWithPhy(obj.PhyEntity, obj);
        end

        function addScheduler(obj, scheduler)
            %addScheduler Add scheduler object to MAC
            %   addScheduler(OBJ, SCHEDULER) adds scheduler to the MAC
            %
            %   SCHEDULER Scheduler object
            addScheduler(obj.MACEntity, scheduler);
        end
    end
end