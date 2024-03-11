classdef uePassThroughPhy < communication.phyLayer.phyInterface
    %uePassThroughPhy Implements a pass-through UE physical layer without any physical layer processing
    %   The class implements a pass-through Phy at UE. It implements the
    %   interfaces for information exchange between Phy and higher layers.
    %   It implements the periodic channel update mechanism by varying the
    %   assumed CQI values. Packet reception errors are modeled in a
    %   probabilistic manner.
    
    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %DLBlkErr Downlink block error information
        % It is an array of two elements containing the number of
        % erroneously received packets and total received packets,
        % respectively
        DLBlkErr
    end
    
    properties (Access = private)
        
        %RNTI RNTI of UE
        RNTI
        
        %HarqBuffers Buffers to store uplink HARQ transport blocks
        % Cell array of 16 elements to buffer transport blocks of different
        % HARQ processes. The physical layer buffers the transport blocks
        % for retransmissions
        HARQBuffers
        
        %PUSCHPDU PUSCH information sent by MAC for the current slot
        % It is an object of type hNRPUSCHInfo. It contains the information
        % required by Phy to transmit a MAC PDU stored object property
        % 'MacPDU'
        PUSCHPDU = {}
        
        %MacPDU PDU sent by MAC which is scheduled to be sent in the current slot
        % The uplink MAC PDU to be sent in the current
        % slot using information in object property PUSCHPDU
        MacPDU = {}
        
        %CSIRSContext Rx context for the CSI-RS
        % Cell array of size 'N' where N is the number of slots in a 10 ms
        % frame. The cell elements are populated with objects of type
        % nrCSIRSConfig. An element at index 'i' contains the CSI-RS
        % configuration which ended in slot 'i-1'. Cell element
        % at 'i' is empty if no CSI-RS reception was scheduled in the slot
        % 'i-1'
        CSIRSContext
        
        %CSIRSIndicationFcn Function handle to send the DL channel quality to MAC
        CSIRSIndicationFcn
        
        %RxBuffer Rx buffer to store incoming DL packets
        % Cell array of length 'N' where 'N' is the number of symbols in a 10
        % ms frame. An element at index 'i' buffers the packet
        % received, whose reception starts at symbol index 'i' in the frame
        RxBuffer
        
        %TxPUSCHFcn Function handle to transmit PUSCH
        TxPUSCHFcn
        
        %ChannelQualityDL Current DL channel quality
        ChannelQualityDL
        
        %CQIvsDistance CQI vs Distance mapping
        % It is matrix with 2 columns. Each row is a mapping between
        % distance from gNB (first column in meters) and maximum achievable
        % DL CQI value (second column)
        CQIvsDistance = [
            200  15;
            500  12;
            800  10;
            1000  8;
            1200  7];
        
        %ChannelUpdatePeriodicity Channel update periodicity in terms of number of slots
        ChannelUpdatePeriodicity = 100;
        
        %CQIDelta Amount by which CQI improves/deteriorates every ChannelUpdatePeriodicity slots
        CQIDelta = 1;
        
        %SlotsSinceChannelUpdate Number of slots elapsed since the last channel update
        % It is incremented every slot and as soon as it reaches the
        % 'ChannelUpdatePeriodicity', it is set to zero and channel
        % conditions are updated
        SlotsSinceChannelUpdate = 0;
        
        %GNBPosition Position of gNB
        % Assumed DL CQI values are based on distance to gNB
        GNBPosition = [0 0 0];
        
        %PacketLogger Contains handle of the PCAP object
        PacketLogger
        
        %PacketMetaData Contains the information required for logging MAC
        %packets into PCAP
        PacketMetaData
    end
    
    methods
        function obj = uePassThroughPhy(param, rnti)
            %uePassThroughPhy Construct a UE pass-through Phy object
            % OBJ = hNRUEPassThroughPhy(RNTI, PARAM) constructs a UE Phy object.
            %
            % PARAM is a structure with SCS and the fields to define the
            % way channel updates happen in the absence of actual channel.
            % It contain these fields:
            %   SCS                        - Subcarrier spacing
            %   CQIvsDistance              - CQI vs Distance mapping
            %   ChannelUpdatePeriodicity   - Periodicity of channel update in seconds
            %   CQIDelta                   - Amount by which CQI value
            %                                improves/deteriorates every time
            %                                channel updates
            %   NumRBs                     - Number of RBs in DL bandwidth
            %   GNBPosition                - Position of gNB
            %   InitialChannelQualityDL    - Initial DL channel quality for the UE
            %
            %   CQIvsDistance is a mapping between distance from gNB (first
            %   column in meters) and maximum achievable CQI value (second
            %   column). For example, if a UE is 700 meters away from the
            %   gNB, it can achieve a maximum CQI value of 10 as the distance
            %   falls within the [501, 800] meters range, as per the below
            %   sample mapping.
            %   CQIvsDistance = [
            %       200  15;
            %       500  12;
            %       800  10;
            %       1000  8;
            %       1200  7];
            %   Channel quality is periodically improved or deteriorated by
            %   CQIDelta every ChannelUpdatePeriodicity seconds for all RBs
            %   of a UE. Whether channel conditions for a particular UE
            %   improve or deteriorate is randomly determined
            %
            % RNTI is the RNTI of UE
            
            % Validate the subcarrier spacing
            if ~ismember(param.scs, [15 30 60 120 240])
                error('nr5g:hNRUEPassThroughPhy:InvalidSCS', 'The subcarrier spacing ( %d ) must be one of the set (15, 30, 60, 120, 240).', param.scs);
            end
            
            % Validate number of RBs
            validateattributes(param.numRBs, {'numeric'}, {'real', 'integer', 'scalar', '>=', 1, '<=', 275}, 'param.numRBs', 'numRBs');
            
            % Validate rnti
            validateattributes(rnti, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 1, '<=', 65519}, 'rnti');
            
            obj.HARQBuffers = cell(1, 16); % HARQ buffers
            obj.RNTI = rnti;
            obj.CSIRSContext = cell((param.scs/15)*10, 1); % Context for total number of slots in the frame
            
            if isfield(param, 'InitialChannelQualityDL')
                % Validate initial channel quality in the downlink
                % direction
                validateattributes(param.InitialChannelQualityDL(rnti, :), {'numeric'}, {'integer', 'nonempty', '>=', 1, '<=', 15}, 'InitialChannelQualityDL');
                obj.ChannelQualityDL = param.InitialChannelQualityDL(rnti, :);
            else
                % Initialize the CQI to 7 for the DL bandwidth for the UE
                initialCQI = 7;
                obj.ChannelQualityDL = initialCQI*ones(param.numRBs, 1);
            end
            
            if isfield(param, 'CQIvsDistance')
                % Validate the mapping between distance and CQI. Distance
                % must be in strictly increasing order
                validateattributes(param.CQIvsDistance, {'numeric'}, {'nonempty', '2d'}, 'param.CQIvsDistance', 'CQIvsDistance');
                % Distance must be in strictly increasing order
                validateattributes(param.CQIvsDistance(:, 1), {'numeric'}, {'finite', '>', 0, 'increasing'}, 'param.CQIvsDistance(:, 1)');
                obj.CQIvsDistance = param.CQIvsDistance;
            end
            
            if isfield(param, 'CQIDelta')
                % Validate the channel improvement or deterioration value
                validateattributes(param.CQIDelta, {'numeric'}, {'nonempty', 'scalar', 'finite', '>=', 0}, 'param.CQIDelta', 'CQIDelta');
                obj.CQIDelta = param.CQIDelta;
            end
            
            if isfield(param, 'channelUpdatePeriodicity')
                % Validate the channel update periodicity
                validateattributes(param.channelUpdatePeriodicity, {'numeric'}, {'nonempty', 'finite', 'scalar', '>', 0}, 'param.channelUpdatePeriodicity', 'channelUpdatePeriodicity');
                slotDuration = 1/(param.scs/15); % Slot duration in ms
                obj.ChannelUpdatePeriodicity = floor((param.ChannelUpdatePeriodicity * 1000)/ slotDuration);
            end
            
            % Set the number of erroneous packets and total number of
            % packets received by the UE to zero
            obj.DLBlkErr = zeros(1, 2);
            
            % Initialize Rx buffer
            symbolsPerFrame = 14*10*(param.scs/15);
            obj.RxBuffer = cell(symbolsPerFrame, 1);
            
            if isfield(param, 'gNBPosition')
                % Validate gNB position
                validateattributes(param.gNBPosition, {'numeric'}, {'numel', 3, 'nonempty', 'finite', 'nonnan', '>=', 0}, 'param.gNBPosition', 'gNBPosition');
                obj.GNBPosition = param.gNBPosition;
            end
        end
        
        function run(obj)
            %run Run the UE Phy layer operations
            
            % Phy transmission of MAC PDUs without any Phy processing.
            % It is assumed that MAC has already loaded the Phy Tx context for
            % anything scheduled to be transmitted at the current time
            phyTx(obj);
            
            % Phy reception and sending the PDU to MAC.
            % Reception of MAC PDU is done in the symbol after the last
            % symbol in PDSCH duration (till then the packets are queued in
            % Rx buffer). Phy calculates the last symbol of PDSCH duration
            % based on 'rxDataRequest' call from MAC (which comes at the
            % first symbol of PDSCH Rx time) and the PDSCH duration
            phyRx(obj);
        end
        function enablePacketLogging(obj, fileName)
            %enablePacketLogging Enable packet logging
            %
            % FILENAME - Name of the PCAP file

            % Create packet logging object
            obj.PacketLogger = nrPCAPWriter(FileName=fileName, FileExtension='pcap');
            % Define the packet informtion structure
            obj.PacketMetaData = struct('RadioType',[],'RNTIType',[],'RNTI',[], ...
                'HARQID',[],'SystemFrameNumber',[],'SlotNumber',[],'LinkDir',[]);
            if obj.CellConfig.DuplexMode % Radio type
                obj.PacketMetaData.RadioType = obj.PacketLogger.RadioTDD;
            else
                obj.PacketMetaData.RadioType = obj.PacketLogger.RadioFDD;
            end
            obj.PacketMetaData.RNTIType = obj.PacketLogger.CellRNTI;
            obj.PacketMetaData.RNTI = obj.RNTI;
        end
        
        function advanceTimer(obj, numSym)
            %advanceTimer Advance the timer ticks by specified number of symbols
            %   advanceTimer(OBJ, NUMSYM) advances the timer by specified
            %   number of symbols. Time is advanced by 1 symbol for
            %   symbol-based scheduling and by 14 symbols for slot based
            %   scheduling.
            %
            %   NUMSYM is the number of symbols to be advanced.
            
            obj.CurrSymbol = mod(obj.CurrSymbol + numSym, 14);
            if obj.CurrSymbol == 0 % Reached slot-boundary
                % Current slot number in 10 ms frame
                obj.CurrSlot = mod(obj.CurrSlot + 1, obj.CarrierInformation.SlotsPerSubframe*10);
                if obj.CurrSlot == 0 % Reached frame boundary
                    obj.AFN = obj.AFN + 1;
                end
                obj.SlotsSinceChannelUpdate = obj.SlotsSinceChannelUpdate+1;
                if obj.SlotsSinceChannelUpdate == obj.ChannelUpdatePeriodicity
                    % Update the channel conditions
                    disToGNB = getNodeDistance(obj.Node, obj.GNBPosition);
                    % Get achievable CQI based on the current distance of
                    % UE from gNB
                    matchingRowIdx = find(obj.CQIvsDistance(:, 1) > disToGNB);
                    if isempty(matchingRowIdx)
                        maxCQI = obj.CQIvsDistance(end, 2);
                    else
                        maxCQI = obj.CQIvsDistance(matchingRowIdx(1), 2);
                    end
                    updateType = [1 -1]; % Update type: Improvement/deterioration
                    channelQualityChange = updateType(randi(length(updateType)));
                    % Update the channel quality
                    currentCQIRBs = obj.ChannelQualityDL;
                    obj.ChannelQualityDL = min(max(currentCQIRBs + obj.CQIDelta*channelQualityChange, 1), maxCQI);
                    obj.SlotsSinceChannelUpdate = 0;
                end
            end
        end
        
        function txDataRequest(obj, PUSCHInfo, macPDU)
            %txDataRequest Data Tx request from MAC to Phy for starting PUSCH transmission
            %  txDataRequest(OBJ, PUSCHINFO, MACPDU) sets the Tx context to
            %  indicate PUSCH transmission in the current slot
            %
            %  PUSCHInfo is an object of type hNRPUSCHInfo sent by MAC. It
            %  contains the information required by the Phy for the
            %  transmission.
            %
            %  MACPDU is the uplink MAC PDU sent by MAC for transmission.
            
            obj.MacPDU = macPDU;
            obj.PUSCHPDU = PUSCHInfo;
        end
        
        function rxDataRequest(obj, pdschInfo)
            %rxDataRequest Rx request from MAC to Phy for starting PDSCH reception
            %   rxDataRequest(OBJ, PDSCHINFO) is a request to start PDSCH
            %   reception. It starts a timer for PDSCH end time (which on
            %   firing receives the PDSCH).
            %
            %   PDSCHInfo is an object of type hNRPDSCHInfo. It
            %   contains the information required by the Phy for the
            %   reception.
            
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            
            % PDSCH to be read in the symbol after the last symbol in
            % PDSCH reception
            numPDSCHSym =  pdschInfo.PDSCHConfig.SymbolAllocation(2);
            pdschRxSymbolFrame = mod(symbolNumFrame + numPDSCHSym, obj.CarrierInformation.SymbolsPerFrame);
            
            % Add the PDSCH Rx information at the index corresponding to
            % the symbol just after PDSCH end time
            obj.DataRxContext{pdschRxSymbolFrame+1} = pdschInfo;
        end
        
        function dlControlRequest(obj, pduType, dlControlPDU)
            %dlControlRequest Downlink control request from MAC to Phy
            %   dlControlRequest(OBJ, PDUTYPES, DLCONTROLPDUS) is a request
            %   to start downlink receptions. MAC sends it at the start
            %   of a DL slot for all the scheduled DL receptions in the
            %   slot (except PDSCH, which is received using rxDataRequest
            %   interface of this class).
            %
            %   PDUTYPE is an array of packet types. Currently, only
            %   packet type 0 (CSI-RS) is supported.
            %
            %   DLCONTROLPDU is an array of DL control PDUs corresponding to packet
            %   types in PDUTYPE. Currently supported CSI-RS PDU is an object
            %   of type nrCSIRSConfig.
            %   Pass-through phy does not send/receive actual CSI-RS. It
            %   is just a request from MAC to report the current
            %   assumed channel quality (as per the installed channel update
            %   mechanism)
            
            % Update the Rx context for DL receptions
            for i=1:length(pduType)
                switch(pduType(i))
                    case obj.CSIRSPDUType
                        % Channel quality would be read at the start of next slot
                        nextSlot = mod(obj.CurrSlot+1, obj.CarrierInformation.SlotsPerSubframe*10);
                        obj.CSIRSContext{nextSlot+1} = dlControlPDU{i};
                end
            end
        end
        
        function ulControlRequest(~, ~, ~)
            %ulControlRequest Uplink control request from MAC to Phy
            
            % Not required for UE pass-through Phy. Overriding the
            % abstract method of the base class to do nothing
        end
        
        function registerMACInterfaceFcn(obj, sendMACPDUFcn, sendDLChanQualityFcn)
            %registerMACInterfaceFcn Register MAC interface functions at Phy for sending information to MAC
            %   registerMACInterfaceFn(OBJ, SENDMACPDUFCN,
            %   SENDDLCHANQUALITYFCN) registers the callback function to
            %   send PDUs and DL channel quality to MAC.
            %
            %   SENDMACPDUFCN Function handle provided by MAC to Phy for
            %   sending PDUs.
            %
            %   SENDDLCHANQUALITYFCN Function handle provided by MAC to Phy for
            %   sending the measured DL channel quality.
            
            obj.RxIndicationFcn = sendMACPDUFcn;
            obj.CSIRSIndicationFcn = sendDLChanQualityFcn;
        end
        
        function registerInBandTxFcn(obj, txFcn)
            %registerInBandTxFcn Set function handle for PUSCH transmission
            %
            % TXFCN is the function handle provided by packet
            % distribution object, to be used for
            % PUSCH transmission
            
            obj.TxPUSCHFcn = txFcn;
        end
        
        function  phyTx(obj)
            %phyTx Physical layer transmission of scheduled PUSCH
            
            if ~isempty(obj.PUSCHPDU) % If any UL MAC PDU is scheduled to be sent now
                if isempty(obj.MacPDU)
                    % MAC PDU not sent by MAC. Indicates retransmission. Get
                    % the MAC PDU from the HARQ buffers
                    obj.MacPDU = obj.HARQBuffers{obj.PUSCHPDU.HARQID+1};
                else
                    % New transmission. Buffer the transport block
                    obj.HARQBuffers{obj.PUSCHPDU.HARQID+1} = obj.MacPDU;
                end
                % Transmit the transport block
                packetInfo.Packet = obj.MacPDU;
                packetInfo.NCellID = obj.CellConfig.NCellID;
                packetInfo.RNTI = obj.RNTI;
                packetInfo.CarrierFreq = obj.CarrierInformation.ULFreq;
                obj.TxPUSCHFcn(packetInfo);
                
                if ~isempty(obj.PacketLogger) % Packet capture enabled
                    logPackets(obj, obj.PUSCHPDU, obj.MacPDU, 1); % Log UL packets
                end
            end
            
            % Transmission done. Clear the Tx contexts
            obj.PUSCHPDU = {};
            obj.MacPDU = {};
        end
        
        function phyRx(obj)
            %phyRx Physical layer reception
            
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            pdschInfo = obj.DataRxContext{symbolNumFrame + 1};
            if ~isempty(pdschInfo) % If a PDSCH ended in the last symbol
                pdschRx(obj, pdschInfo); % Read the MAC PDU corresponding to PDSCH and send it to MAC
                obj.DataRxContext{symbolNumFrame + 1} = {}; % Clear the context
            end
            
            csirsInfo = obj.CSIRSContext{obj.CurrSlot + 1};
            if ~isempty(csirsInfo)
                % Send the DL CQI to MAC
                obj.CSIRSIndicationFcn(1, [], obj.ChannelQualityDL);
                obj.DataRxContext{symbolNumFrame + 1} = {}; % Clear the context
            end
        end
        
        function storeReception(obj, packetInfo)
            %storeReception Receive the incoming packet and add it to the reception buffer
            
            % Filter the other packets which are not directed to this UE
            if obj.CellConfig.NCellID == packetInfo.NCellID && packetInfo.RNTI == obj.RNTI
                symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
                obj.RxBuffer{symbolNumFrame+1} = packetInfo.Packet; % Buffer the packet
            end
        end

        function timestamp = getCurrentTime(obj)
            %getCurrentTime Return the current timestamp of node in microseconds

            slotDuration = 15/obj.CarrierInformation.SubcarrierSpacing; % In milliseconds
            % Timestamp in microseconds
            timestamp = (obj.AFN*10 + (obj.CurrSlot*slotDuration) + ...
                (obj.CurrSymbol*slotDuration)/14) * 1000;
        end
    end

    methods (Access = private)
        function pdschRx(obj, pdschInfo)
            %pdschRx Receive the MAC PDU corresponding to PDSCH and send it to MAC
            
            % Read packet from Rx buffer. It is stored at the symbol index
            % in 10 ms frame where the reception started
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            
            % Calculate Rx start symbol number w.r.t start of the 10 ms frame
            if symbolNumFrame == 0 % Packet was received in the previous frame
                rxStartSymbol = obj.CarrierInformation.SymbolsPerFrame -  pdschInfo.PDSCHConfig.SymbolAllocation(2);
            else % Packet was received in the current frame
                rxStartSymbol = symbolNumFrame - pdschInfo.PDSCHConfig.SymbolAllocation(2);
            end
            
            macPDU = obj.RxBuffer{rxStartSymbol+1}; % Read the stored MAC PDU corresponding to PUSCH
            obj.RxBuffer{rxStartSymbol+1} = {}; % Clear the buffer
            
            crcFlag = crcResult(obj);
            
            % Increment the number of erroneous packets
            obj.DLBlkErr(1) = obj.DLBlkErr(1) + crcFlag;
            % Increment the total number of received packets
            obj.DLBlkErr(2) = obj.DLBlkErr(2) + 1;
            
            % Rx callback to MAC
            macPDUInfo = hNRRxIndicationInfo;
            macPDUInfo.RNTI = pdschInfo.PDSCHConfig.RNTI;
            macPDUInfo.TBS = pdschInfo.TBS;
            macPDUInfo.HARQID = pdschInfo.HARQID;
            obj.RxIndicationFcn(macPDU, crcFlag, macPDUInfo);
            
            if ~isempty(obj.PacketLogger) % Packet capture enabled
                logPackets(obj, pdschInfo, macPDU, 0); % Log DL packets
            end
        end
        
        function crcFlag = crcResult(~)
            %crcFlag Calculate crc success/failure result
            
            successProbability = 0.9; % For 0.1 block error rate (BLER)
            if(rand(1) <= successProbability)
                crcFlag = 0; % No error
            else
                crcFlag = 1; % Error
            end
        end
        
        function logPackets(obj, info, macPDU, linkDir)
            %logPackets Capture the MAC packets to a PCAP file
            %
            % logPackets(OBJ, INFO, MACPDU, LINKDIR)
            %
            % INFO - Contains the PUSCH/PDSCH information
            %
            % MACPDU - MAC PDU
            %
            % LINKDIR - 1 represents UL and 0 represents DL direction
            
            % Timestamp in microseconds
            timestamp = round(getCurrentTime(obj));
            obj.PacketMetaData.HARQID = info.HARQID;
            obj.PacketMetaData.SlotNumber = info.NSlot;
            
            if linkDir % Uplink
                obj.PacketMetaData.SystemFrameNumber = mod(obj.AFN, 1024);
                obj.PacketMetaData.LinkDir = obj.PacketLogger.Uplink;
            else % Downlink
                % Get frame number of previous slot i.e the Tx slot. Reception ended at the
                % end of previous slot
                if obj.CurrSlot == 0 && obj.CurrSymbol == 0
                    rxAFN = obj.AFN - 1; % Reception was in the previous frame
                else
                    rxAFN = obj.AFN; % Reception was in the current frame
                end
                obj.PacketMetaData.SystemFrameNumber = mod(rxAFN, 1024);
                obj.PacketMetaData.LinkDir = obj.PacketLogger.Downlink;
            end
            write(obj.PacketLogger, macPDU, timestamp, 'PacketInfo', obj.PacketMetaData);
        end
    end

    methods (Hidden = true)
        function dlTTIRequest(obj, pduType, dlControlPDU)
            dlControlRequest(obj, pduType, dlControlPDU);
        end
    end
end