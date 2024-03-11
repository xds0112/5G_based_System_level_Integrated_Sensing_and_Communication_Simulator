classdef gNBPassThroughPhy < communication.phyLayer.phyInterface
    %gNBPassThroughPhy Implements a pass-through gNB physical layer without any physical layer processing
    %   The class implements a pass-through Phy at gNB. It implements the
    %   interfaces for information exchange between Phy and higher layers.
    %   Packet reception errors are modeled in a probabilistic manner
    
    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %ULBlkErr Uplink block error information
        % It is an array of size N-by-2 where N is the number of UEs,
        % columns 1 and 2 contains the number of erroneously received
        % packets and total received packets, respectively.
        ULBlkErr
    end

    properties (Access = private)
        
        %UEs RNTIs in the cell
        UEs
        
        %HarqBuffers Buffers to store downlink HARQ transport blocks
        % N-by-16 cell array to buffer transport blocks for 16 HARQ
        % processes, where 'N' is the number of UEs. The physical layer
        % stores the transport blocks for retransmissions
        HARQBuffers
        
        %PDSCHPDU PDSCH information sent by MAC for the current slot
        % It is an array of objects of type hNRPDSCHInfo. An object at
        % index 'i' contains the information required by Phy to transmit a MAC
        % PDU stored at index 'i' of object property 'MacPDU'
        PDSCHPDU = {}
        
        %MacPDU PDUs sent by MAC which are scheduled to be sent in the current slot
        % It is an array of downlink MAC PDUs to be sent in the current
        % slot. Each object in the array corresponds to one object in
        % object property PDSCHPDU
        MacPDU = {}
        
        %RxBuffer Rx buffer to store incoming UL packets
        % N-by-P cell array where 'N' is number of symbols in a 10 ms frame
        % and 'P' is number of UEs served by cell. An element at index (i,
        % j) buffers the packet received from UE with RNTI 'j' and whose
        % reception starts at symbol index 'i' in the frame. Packet is read
        % from here in the symbol after the last symbol in the PUSCH
        % duration
        RxBuffer
        
        %TxPDSCHFcn Function handle to transmit PUSCH
        TxPDSCHFcn
        
        %PacketLogger Contains handle of the packet capture (PCAP) object
        PacketLogger
        
        %PacketMetaData Contains the information required for logging MAC packets into PCAP file
        PacketMetaData
    end
    
    methods
        function obj = gNBPassThroughPhy(param)
            %gNBPassThroughPhy Construct a gNB pass-through Phy object
            % OBJ = hNRGNBPassThroughPhy(param) constructs a gNB Phy object.
            % PARAM is a structure with fields:
            %   NumUEs                     - Number of UEs connected to the gNB
            %   SCS                        - Subcarrier spacing
            %   NumRBs                     - Number of RBs in UL bandwidth
            
            % Validate the number of UEs
            validateattributes(param.numUEs, {'numeric'}, {'nonempty', 'integer', 'scalar', 'finite', '>=', 0}, 'param.numUEs', 'numUEs');
            
            % Validate the subcarrier spacing
            if ~ismember(param.scs, [15 30 60 120 240])
                error('The subcarrier spacing ( %d ) must be one of the set (15, 30, 60, 120, 240).', param.scs);
            end
            
            % Validate number of RBs
            validateattributes(param.numRBs, {'numeric'}, {'real', 'integer', 'scalar', '>=', 1, '<=', 275}, 'param.numRBs', 'numRBs');
            
            obj.UEs = 1:param.numUEs;
            obj.HARQBuffers = cell(length(obj.UEs), 16); % HARQ buffers for all the UEs
            
            % Set the number of erroneous packets and the total number of
            % packets received from each UE to zero
            obj.ULBlkErr = zeros(param.numUEs, 2);
            
            % Initialize Rx buffer
            symbolsPerFrame = 14*10*(param.scs/15);
            obj.RxBuffer = cell(symbolsPerFrame, length(obj.UEs));
        end
        
        function run(obj)
            %run Run the gNB Phy layer operations
            
            % Phy transmission of MAC PDUs without any Phy processing.
            % It is assumed that MAC has already loaded the Phy Tx context for
            % anything scheduled to be transmitted at the current time.
            phyTx(obj);
            
            % Phy reception and sending the PDU to MAC.
            % Reception of MAC PDU is done in the symbol after the last
            % symbol in PUSCH duration (till then the packets are queued in
            % Rx buffer). Phy calculates the last symbol of PUSCH duration
            % based on 'rxDataRequest' call from MAC (which comes at the
            % first symbol of PUSCH Rx time) and the PUSCH duration
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
        end
        
        function txDataRequest(obj, PDSCHInfo, macPDU)
            %txDataRequest Tx request from MAC to Phy for starting PDSCH transmission
            %  txDataRequest(OBJ, PDSCHINFO, MACPDU) sets the Tx context to
            %  indicate PDSCH transmission in the current slot
            %
            %  PDSCHInfo is an object of type hNRPDSCHInfo, sent by MAC. It
            %  contains the information required by the Phy for the transmission.
            %
            %  MACPDU is the downlink MAC PDU sent by MAC for
            %  transmission.
            
            % Update the Tx context. There can be multiple simultaneous
            % PDSCH transmissions for different UEs
            obj.MacPDU{end+1} = macPDU;
            obj.PDSCHPDU{end+1} = PDSCHInfo;
        end
        
        function rxDataRequest(obj, puschInfo)
            %rxDataRequest Rx request from MAC to Phy for starting PUSCH reception
            %   rxDataRequest(OBJ, PUSCHINFO) is a request to start PUSCH
            %   reception. It starts a timer for PUSCH end time (which on
            %   firing receives the PUSCH). The Phy expects the MAC to send
            %   this request at the start of reception time.
            %
            %   PUSCHInfo is an object of type hNRPUSCHInfo sent by MAC. It
            %   contains the information required by the Phy for the
            %   reception.
            
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            
            % PUSCH to be read in the symbol after the last symbol in
            % PUSCH reception
            numPUSCHSym =  puschInfo.PUSCHConfig.SymbolAllocation(2);
            puschRxSymbolFrame = mod(symbolNumFrame + numPUSCHSym, obj.CarrierInformation.SymbolsPerFrame);
            
            % Add the PUSCH Rx information at the index corresponding to
            % the symbol just after PUSCH end time
            obj.DataRxContext{puschRxSymbolFrame+1}{end+1} = puschInfo;
        end
        
        function dlControlRequest(~, ~, ~)
            %dlControlRequest Downlink control request from MAC to Phy
            
            % Not required for gNB pass-through Phy, as currently only data
            %(i.e. PDSCH) is supported. Overriding the abstract method of the
            % base class to do nothing
        end
        
        function ulControlRequest(~, ~, ~)
            %ulControlRequest Uplink control request from MAC to Phy

            % Not required for gNB pass-through Phy. Overriding the
            % abstract method of the base class to do nothing
        end

        function registerMACInterfaceFcn(obj, sendMACPDUFcn, ~)
            %registerMACInterfaceFcn Register MAC interface functions at Phy for sending information to MAC
            %   registerMACInterfaceFcn(OBJ, SENDMACPDUFCN, ~) registers the
            %   function to send PDUs to MAC.
            %
            %   SENDMACPDUFCN Function handle provided by MAC to Phy, for
            %   sending PDUs
            
            obj.RxIndicationFcn = sendMACPDUFcn;
        end
        
        function registerInBandTxFcn(obj, txFcn)
            %registerInBandTxFcn Set function handle for PDSCH transmission
            %
            % TXFCN is the function handle provided by packet
            % distribution object, to be used for
            % PDSCH transmission
            
            obj.TxPDSCHFcn = txFcn;
        end
        
        function phyTx(obj)
            %phyTx Physical layer transmission
            
            for i=1:length(obj.PDSCHPDU) % For each DL MAC PDU scheduled to be sent now
                if isempty(obj.MacPDU{i})
                    % MAC PDU not sent by MAC. Indicates retransmission. Get
                    % the MAC PDU from the HARQ buffers
                    obj.MacPDU{i} = obj.HARQBuffers{obj.PDSCHPDU{i}.PDSCHConfig.RNTI, obj.PDSCHPDU{i}.HARQID+1};
                else
                    % New transmission. Buffer the transport block
                    obj.HARQBuffers{obj.PDSCHPDU{i}.PDSCHConfig.RNTI, obj.PDSCHPDU{i}.HARQID+1} = obj.MacPDU{i};
                end
                % Transmit the transport block
                packetInfo.Packet = obj.MacPDU{i};
                packetInfo.NCellID = obj.CellConfig.NCellID;
                packetInfo.RNTI = obj.PDSCHPDU{i}.PDSCHConfig.RNTI;
                packetInfo.CarrierFreq = obj.CarrierInformation.DLFreq;
                obj.TxPDSCHFcn(packetInfo);
                
                if ~isempty(obj.PacketLogger) % Packet capture enabled
                    logPackets(obj, obj.PDSCHPDU{i}, obj.MacPDU{i}, 0); % Log DL packets
                end
            end
            
            % Transmission done. Clear the Tx contexts
            obj.PDSCHPDU = {};
            obj.MacPDU = {};
        end
        
        function phyRx(obj)
            %phyRx Physical layer reception
            
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            puschInfo = obj.DataRxContext{symbolNumFrame + 1};
            % For all receptions which ended in the last symbol, read the
            % MAC PDU corresponding to PUSCH and send it to MAC
            for i=1:length(puschInfo)
                puschRx(obj, puschInfo{i});
            end
            obj.DataRxContext{symbolNumFrame + 1} = {}; % Clear the context
        end
        
        function storeReception(obj, packetInfo)
            %storeReception Receive the incoming packet and add it to the reception buffer
            
            % Filter out the packets from other cells
            if obj.CellConfig.NCellID == packetInfo.NCellID
                % Current symbol number w.r.t start of 10 ms frame
                symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol;
                % Buffer the packet. It would be read after the reception
                % end time
                obj.RxBuffer{symbolNumFrame+1, packetInfo.RNTI} = packetInfo.Packet;
            end
        end

        function timestamp = getCurrentTime(obj)
            %getCurrentTime Return the current timestamp of node in microseconds

            slotDuration = 15/obj.CarrierInformation.SubcarrierSpacing; % In milliseconds
            % Timestamp in microseconds
            timestamp = (obj.AFN*10 + (obj.CurrSlot*slotDuration) + ....
                (obj.CurrSymbol*slotDuration)/14) * 1000;
        end
    end
    
    methods (Access = private)
        function puschRx(obj, puschInfo)
            %puschRx Receive the MAC PDU corresponding to PUSCH and send it to MAC
            
            symbolNumFrame = obj.CurrSlot*14 + obj.CurrSymbol; % Current symbol number w.r.t start of 10 ms frame
            
            % Calculate Rx start symbol number w.r.t start of the 10 ms frame
            if symbolNumFrame == 0 % Packet was received in the previous frame
                rxStartSymbol = obj.CarrierInformation.SymbolsPerFrame -  puschInfo.PUSCHConfig.SymbolAllocation(2);
            else % Packet was received in the current frame
                rxStartSymbol = symbolNumFrame -  puschInfo.PUSCHConfig.SymbolAllocation(2);
            end
            macPDU = obj.RxBuffer{rxStartSymbol+1, puschInfo.PUSCHConfig.RNTI}; % Read the stored MAC PDU corresponding to PUSCH
            obj.RxBuffer{rxStartSymbol+1, puschInfo.PUSCHConfig.RNTI} = {}; % Clear the buffer
            crcFlag = crcResult(obj);
            
            % Increment the number of erroneous received for UE
            obj.ULBlkErr(puschInfo.PUSCHConfig.RNTI, 1) = obj.ULBlkErr(puschInfo.PUSCHConfig.RNTI, 1) + crcFlag;
            % Increment the number of received packets for UE
            obj.ULBlkErr(puschInfo.PUSCHConfig.RNTI, 2) = obj.ULBlkErr(puschInfo.PUSCHConfig.RNTI, 2) + 1;
            
            % Rx callback to MAC
            macPDUInfo = hNRRxIndicationInfo;
            macPDUInfo.RNTI = puschInfo.PUSCHConfig.RNTI;
            macPDUInfo.TBS = puschInfo.TBS;
            macPDUInfo.HARQID = puschInfo.HARQID;
            obj.RxIndicationFcn(macPDU, crcFlag, macPDUInfo);
            
            if ~isempty(obj.PacketLogger) % Packet capture enabled
                logPackets(obj, puschInfo, macPDU, 1); % Log UL packets
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
                % Get frame number of previous slot i.e the Tx slot. Reception ended at the
                % end of previous slot
                if obj.CurrSlot > 0
                    prevSlotAFN = obj.AFN; % Previous slot was in the current frame
                else
                    % Previous slot was in the previous frame
                    prevSlotAFN = obj.AFN - 1;
                end
                obj.PacketMetaData.SystemFrameNumber = mod(prevSlotAFN, 1024);
                obj.PacketMetaData.LinkDir = obj.PacketLogger.Uplink;
                obj.PacketMetaData.RNTI = info.PUSCHConfig.RNTI;
            else % Downlink
                obj.PacketMetaData.SystemFrameNumber = mod(obj.AFN, 1024);
                obj.PacketMetaData.LinkDir = obj.PacketLogger.Downlink;
                obj.PacketMetaData.RNTI = info.PDSCHConfig.RNTI;
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