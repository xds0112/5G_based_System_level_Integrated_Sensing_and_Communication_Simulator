classdef (Abstract) macEntity < handle
%MAC Define an NR MAC base class

%   Copyright 2019-2021 The MathWorks, Inc.

    properties(Access = public)
        %MACType Type of node to which MAC Entity belongs
        % Value 1 means UE MAC and value 0 means gNB MAC
        MACType = 1;

        %NCellID Physical cell ID. Values: 0 to 1007 (TS 38.211, sec 7.4.2.1). The default value is 1
        NCellID (1, 1){mustBeInRange(NCellID, 0, 1007)} = 1;
    end

    properties (Access = protected)
        %RLCTxFcn A function handle to interact with RLC layer to pull the RLC PDUs for transmission
        RLCTxFcn
        %RLCRxFcn A function handle to interact with RLC layer to push the received PDUs up the stack
        RLCRxFcn
        %LogicalChannelsConfig A cell array of logical channel configuration structure
        % If this class is inherited by UE, it is of size
        % 1-by-maxLogicalChannels. When inherited by gNB, it is of size
        % becomes NumUEs-by-maxLogicalChannels. Each row in the matrix
        % corresponds to a different UE and each column corresponds to a
        % different logical channel. Each structure contains these fields:
        %
        % RNTI      - Radio network temporary identifier
        % LCID      - Logical channel identifier
        % LCGID     - Logical channel group identifier
        % Priority  - Priority of the logical channel
        % PBR       - Prioritized bit rate (in kilo bytes per second)
        % BSD       - Bucket size duration (in ms)
        LogicalChannelsConfig
        %LCHBufferStatus An array of logical channel buffer status information
        % This property size depends on the type of device inheriting it.
        % In case of a UE, this property size becomes
        % 1-by-maxLogicalChannels. In case of a gNB, its size is
        % numUEs-by-maxLogicalChannels. Each row in the matrix
        % corresponds to a different UE and each column corresponds to a
        % different logical channel
        LCHBufferStatus
        %LCHBjList An array of Bj values for different logical channels
        % This property size depends on the type of device inheriting it.
        % In case of a UE device, this property size is
        % 1-by-maxLogicalChannels. In case of a gNB, its size is
        % numUEs-by-maxLogicalChannels. Each row in the matrix
        % corresponds to a different UE and each column corresponds to a
        % different logical channel
        LCHBjList
        %ElapsedTimeSinceLastLCP An array of elapsed times (in milliseconds) since the last LCP run for the UE
        % This property size depends on the type of device inheriting it.
        % In case of a UE device, this property size is 1-by-1. In case of
        % a gNB, its size is numUEs-by-1. Each row in the matrix
        % corresponds to a different UE
        ElapsedTimeSinceLastLCP
        %SlotDuration Duration of slot in ms
        SlotDuration
        %NumSlotsFrame Number of slots in a 10 ms frame. Depends on the SCS used
        NumSlotsFrame
        %TxDataRequestFcn Function handle to send data to Phy
        TxDataRequestFcn
        %RxDataRequestFcn Function handle to receive data from Phy
        RxDataRequestFcn
        %DlControlRequestFcn Function handle to send DL control request to Phy
        DlControlRequestFcn
        %UlControlRequestFcn Function handle to send DL control request to Phy
        UlControlRequestFcn
        %TxOutofBandFcn Function handle to transmit out-of-band packets to receiver's MAC
        TxOutofBandFcn
    end

    properties (Constant)
        % MaxLogicalChannels Maximum number of logical channels
        MaxLogicalChannels = 32;
        % MinPriorityForLCH Minimum logical channel priority value
        MinPriorityForLCH = 1;
        % MaxPriorityForLCH Maximum logical channel priority value
        MaxPriorityForLCH = 16;
        % PBR Set of valid PBR (in kBps) values for a logical channel. For
        % more details, refer 3GPP TS 38.331 information element
        % LogicalChannel-Config
        PBR = [0, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, ...
                    65536, Inf];
        % BSD Set of valid BSD (in ms) values for a logical channel. For
        % more details, refer 3GPP TS 38.331 information element
        % LogicalChannel-Config
        BSD = [5, 10, 20, 50, 100, 150, 300, 500, 1000];
        % NominalRBGSizePerBW Nominal RBG size for the specified bandwidth
        % in accordance with 3GPP TS 38.214, Section 5.1.2.2.1
        NominalRBGSizePerBW = [
            36   2   4
            72   4   8
            144  8   16
            275  16  16
            ];

        %BSR Packet type for BSR
        BSR = 1;
        %ULGrant Packet type for uplink grant
        ULGrant = 2;
        %DLGrant Packet type for downlink grant
        DLGrant = 3;
        %PDSCHFeedback Packet type for PDSCH ACK/NACK
        PDSCHFeedback = 4;
        %CSIReport Packet type for channel state information (CSI) report
        CSIReport = 5;

        %DLType Value to specify downlink direction or downlink symbol type
        DLType = 0;

        %ULType Value to specify uplink direction or uplink symbol type
        ULType = 1;

        %GuardType Value to specify guard symbol type
        GuardType = 2;
    end

    methods (Access = public)
        function registerRLCInterfaceFcn(obj, rlcTxFcn, rlcRxFcn)
            %registerRLCInterfaceFcn Register the RLC entity callbacks
            %
            %   registerRLCInterfaceFcn(OBJ, RLCTXFCN, RLCRXFCN)
            %   registers the callback function to interact with the RLC Tx
            %   and Rx entities.
            %
            %   RLCTXFCN Function handle to interact with
            %   RLC Tx entities.
            %
            %   RLCRXFCN Function handle to interact with
            %   RLC Rx entities.

            obj.RLCTxFcn = rlcTxFcn;
            obj.RLCRxFcn = rlcRxFcn;
        end

        function registerPhyInterfaceFcn(obj, txFcn, rxFcn, dlControlReqFcn, ulControlReqFcn)
            %registerPhyInterfaceFcn Register Phy interface functions for Tx and Rx
            %   regiserPhyInterfaceFcn(OBJ, TXFCN, RXFCN, DLCONTROLREQFCN, ULCONTROLREQFCN) registers Phy
            %   interface functions at MAC for (i) Sending packets to Phy
            %   (ii) Sending Rx request to Phy at the Rx start time
            %   (iii) Sending DL control request to Phy
            %   (iv) Sending UL control request to Phy
            %
            %   TXFCN Function handle to send data to Phy.
            %
            %   RXFCN Function handle to indicate Rx start to Phy.
            %
            %   DLCONTROLREQFCN Function handle to send DL control request to Phy.
            %
            %   ULCONTROLREQFCN Function handle to send UL control request to Phy.

            obj.TxDataRequestFcn = txFcn;
            obj.RxDataRequestFcn = rxFcn;
            obj.DlControlRequestFcn = dlControlReqFcn;
            obj.UlControlRequestFcn = ulControlReqFcn;
        end

        function registerOutofBandTxFcn(obj, sendOutofBandPktsFcn)
            %registerOutofBandTxFcn Set the function handle for transmitting out-of-band packets from sender's MAC to receiver's MAC
            %
            % SENDOUTOFBANDPKTSFCN is the function handle provided by
            % packet distribution object, to be used by the MAC for
            % transmitting out-of-band packets

            obj.TxOutofBandFcn = sendOutofBandPktsFcn;
        end

        function addLogicalChannelInfo(obj, logicalChannelConfig, varargin)
            %addLogicalChannelInfo Add the logical channel information
            %
            % addLogicalChannelInfo(OBJ, LOGICALCHANNELCONFIG) adds the
            % logical channel information to the list of active logical
            % channels in the UE.
            %
            % addLogicalChannelInfo(OBJ, LOGICALCHANNELCONFIG, RNTI) adds
            % the logical channel information to the list of active logical
            % channels for the UE in gNB.
            %
            % LOGICALCHANNELCONFIG is a logical channel id, specified in
            % the range between 1 and 32, inclusive.
            %
            % RNTI is a radio network temporary identifier, specified in
            % the range between 1 and 65519, inclusive. Refer table 7.1-1
            % in 3GPP TS 38.321.

            % Based on the MAC type, select the logical channel
            % configuration set for the UE
            ueIdx = 1;
            if ~obj.MACType
                % In case of gNB MAC, RNTI of UE is the cell array index to
                % get its logical channel information in downlink direction
                ueIdx = varargin{1};
            end

            if ~isempty(obj.LogicalChannelsConfig{ueIdx, logicalChannelConfig.LCID})
                error('nr5g:mac:DuplicateLogicalChannel','Duplicate logical channel configuration is present for LCID ( %d ) in UE ( %d ).', logicalChannelConfig.LCID, ueIdx);
            end

            if isfield(logicalChannelConfig, 'LCGID')
                % Validate priority of the logical channel
                validateattributes(logicalChannelConfig.LCGID, {'numeric'}, {'nonempty', 'scalar', '>=', 0, '<=', 7}, 'logicalChannelConfig.LCGID', 'LCGID');
            end

            if isfield(logicalChannelConfig, 'Priority')
                % Validate priority of the logical channel
                validateattributes(logicalChannelConfig.Priority, {'numeric'}, {'nonempty', 'scalar', '>', 0, '<=', 16}, 'logicalChannelConfig.Priority', 'Priority');
            end

            if isfield(logicalChannelConfig, 'PBR')
                % Validate the PBR
                validateattributes(logicalChannelConfig.PBR, {'numeric'}, {'nonempty', 'scalar'}, 'logicalChannelConfig.PBR', 'PBR');
                if ~ismember(logicalChannelConfig.PBR, obj.PBR)
                    error('nr5g:mac:InvalidPBR','PBR ( %d ) must be one of the set (0, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, Inf).', logicalChannelConfig.PBR);
                end
            end

            if isfield(logicalChannelConfig, 'BSD')
                % Validate the BSD
                validateattributes(logicalChannelConfig.BSD, {'numeric'}, {'nonempty', 'scalar'}, 'logicalChannelConfig.BSD', 'BSD');
                if ~ismember(logicalChannelConfig.BSD, obj.BSD)
                    error('nr5g:mac:InvalidBSD','BSD ( %d ) must be one of the set (5, 10, 20, 50, 100, 150, 300, 500, 1000).', logicalChannelConfig.BSD);
                end
            end

            % Store the logical channel information
            obj.LogicalChannelsConfig{ueIdx, logicalChannelConfig.LCID} = logicalChannelConfig;
        end

        function [dataSubPDUList, remainingBytes] = performLCP(obj, tbs, varargin)
            %performLCP Perform the logical channel prioritization (LCP)
            %procedure
            %
            %   [DATASUBPDULIST, REMAININGBYTES] = performLCP(OBJ, TBS)
            %   performs the logical channel prioritization procedure in UE
            %   MAC.
            %
            %   [DATASUBPDULIST, REMAININGBYTES] = performLCP(OBJ, TBS,
            %   RNTI) performs the logical channel prioritization procedure
            %   in gNB MAC for UE identified with RNTI.
            %
            %   DATASUBPDULIST is a cell array of MAC subPDUs where each
            %   MAC subPDU is a column vector of octets in decimal format.
            %
            %   REMAININGBYTES is an integer scalar, which represents the
            %   number of bytes left unused in the TBS.
            %
            %   TBS is an integer scalar, which represents the size of the
            %   MAC PDU to be constructed as per the received grant.
            %
            %   RNTI is a radio network temporary identifier. Specify the
            %   RNTI as an integer scalar between 1 and 65519, inclusive.
            %   Refer table 7.1-1 in 3GPP TS 38.321.

            % Based on the MAC type, select the logical channel
            % configuration set for the UE
            ueIdx = 1;
            if ~obj.MACType
                % In case of gNB MAC, RNTI acts as an index to get the
                % logical channel information, associated to a UE in the
                % downlink direction, from a cell array
                ueIdx = varargin{1};
            end

            % Identify the number of logical channels having data to
            % transmit. If no logical channel has data to transmit, abort
            % the LCP procedure
            activeLCH = sum(obj.LCHBufferStatus(ueIdx, :) ~= 0);
            if activeLCH == 0
                dataSubPDUList = {};
                remainingBytes = tbs;
                return;
            end

            lcpPriorityList = cell(obj.MaxPriorityForLCH, 1);
            % Iterate through the configured logical channels
            for lchIdx = 1:numel(obj.LogicalChannelsConfig(ueIdx, :))
                if isempty(obj.LogicalChannelsConfig{ueIdx, lchIdx})
                    continue;
                end
                % Check if prioritized bit rate is not set to infinity
                if obj.LogicalChannelsConfig{ueIdx, lchIdx}.PBR ~= Inf
                    % Calculate the time elapsed since the last LCP run for
                    % the UE
                    timeElapsed = min(obj.ElapsedTimeSinceLastLCP(ueIdx, 1), obj.LogicalChannelsConfig{ueIdx, lchIdx}.BSD);
                    % Increment the Bj by the product of time elapsed and
                    % PBR
                    obj.LCHBjList(ueIdx, lchIdx) = obj.LCHBjList(ueIdx, lchIdx) + ...
                        ceil(obj.LogicalChannelsConfig{ueIdx, lchIdx}.PBR * timeElapsed);
                else
                    % When the prioritized bit rate is set to infinity,
                    % update the minimum grant Bj required by the logical
                    % channel to the minimum of logical channel buffer
                    % status and remaining grant
                    obj.LCHBjList(ueIdx, lchIdx) = min(obj.LCHBufferStatus(ueIdx, lchIdx), tbs);
                end
                % Store the logical channel id in a cell array where the
                % storing index of the cell array refer its priority
                lchPriority = obj.LogicalChannelsConfig{ueIdx, lchIdx}.Priority;
                lcpPriorityList{lchPriority, 1}{end+1, 1} = lchIdx;
            end

            if activeLCH == 1
                % If only one logical channel has data to transmit, then
                % skip the LCP round-1
                [dataSubPDUList, remainingBytes] = performLCPRound2(obj, tbs, ueIdx, lcpPriorityList);
            else
                % As per Section 5.4.3.1.3 of the 3GPP TS 38.321, perform
                % the LCP procedure and get the MAC SDUs from the RLC
                % entity
                [subPDUlist, remainingBytes] = performLCPRound1(obj, tbs, ueIdx, lcpPriorityList);
                [dataSubPDUList, remainingBytes] = performLCPRound2(obj, remainingBytes, ueIdx, lcpPriorityList);
                dataSubPDUList = [subPDUlist dataSubPDUList];
            end
            
            % Reset the elapsed time since last LCP run
            obj.ElapsedTimeSinceLastLCP(ueIdx, 1) = 0;
        end

        function pdu = constructMACPDU(obj, tbs, varargin)
            %CONSTRUCTMACPDU Construct and return a MAC PDU based on link direction (DL/UL) and transport block size
            %
            %   CONSTRUCTMACPDU(OBJ, TBS) returns a UL MAC PDU.
            %
            %   CONSTRUCTMACPDU(OBJ, TBS, RNTI) returns a DL MAC PDU for
            %   UE identified with specified RNTI.
            %
            %   TBS Transport block size in bytes.
            %
            %   RNTI RNTI of the UE for which DL MAC PDU needs to be
            %   constructed.

            controlPDUList = {};
            paddingSubPDU = [];

            if obj.MACType
                % UE MAC
                linkDir = obj.ULType; % Uplink
            else
                % gNB MAC
                linkDir = obj.DLType; % Downlink
            end

            % Construct MAC PDU
            if obj.MACType
                % UE MAC
                [dataSubPDUList, remainingBytes] = performLCP(obj, tbs);
            else
                % gNB MAC
                [dataSubPDUList, remainingBytes] = performLCP(obj, tbs, varargin{1});
            end
            if remainingBytes > 0
                % Add padding subPDU for remaining bytes
                paddingSubPDU = communication.macLayer.macPaddingSubPDU(remainingBytes);
            end
            % Construct MAC PDU by concatenating subPDUs
            pdu = communication.macLayer.macMultiplex(dataSubPDUList, controlPDUList, paddingSubPDU, linkDir);
        end

        function MCSTable = getMCSTableUL(~)
            %getMCSTableUL Return the MCS table as per TS 38.214 - Table 5.1.3.1-2

            % Modulation CodeRate Efficiency
            MCSTable = [2	120	0.2344
                2	193     0.3770
                2	308     0.6016
                2	449     0.8770
                2	602     1.1758
                4	378     1.4766
                4	434     1.6953
                4	490     1.9141
                4	553     2.1602
                4	616     2.4063
                4	658     2.5703
                6	466     2.7305
                6	517     3.0293
                6	567     3.3223
                6	616     3.6094
                6	666     3.9023
                6	719     4.2129
                6	772     4.5234
                6	822     4.8164
                6	873     5.1152
                8	682.5	5.3320
                8	711     5.5547
                8	754     5.8906
                8	797     6.2266
                8	841     6.5703
                8	885     6.9141
                8	916.5	7.1602
                8	948     7.4063
                2    0       0
                4    0       0
                6    0       0
                8    0       0];
        end

        function MCSTable = getMCSTableDL(~)
            %getMCSTableDL Return the MCS table as per TS 38.214 - Table 5.1.3.1-2

            % Modulation CodeRate Efficiency
            MCSTable = [2	120	0.2344
                2	193     0.3770
                2	308     0.6016
                2	449     0.8770
                2	602     1.1758
                4	378     1.4766
                4	434     1.6953
                4	490     1.9141
                4	553     2.1602
                4	616     2.4063
                4	658     2.5703
                6	466     2.7305
                6	517     3.0293
                6	567     3.3223
                6	616     3.6094
                6	666     3.9023
                6	719     4.2129
                6	772     4.5234
                6	822     4.8164
                6	873     5.1152
                8	682.5	5.3320
                8	711     5.5547
                8	754     5.8906
                8	797     6.2266
                8	841     6.5703
                8	885     6.9141
                8	916.5	7.1602
                8	948     7.4063
                2    0       0
                4    0       0
                6    0       0
                8    0       0];
        end
    end

    methods (Access = private)
        function [dataSubPDUList, remainingBytes] = performLCPRound1(obj, remainingBytes, ueIdx, lcpPriorityList)
            %performLCPRound1 Perform 1st iteration of allocation among
            %logical channels using MAC LCP

            dataSubPDUList = {};
            % Iterate through the logical channel priority cell array,
            % from highest to lowest priority
            for priorityIdx = obj.MinPriorityForLCH:obj.MaxPriorityForLCH
                % Iterate through the logical channels which are having
                % the selected priority value
                for j = 1:numel(lcpPriorityList{priorityIdx, 1})
                    % As per Section 5.4.3.1.3 of the 3GPP TS 38.321,
                    % minimum required grant for a logical channel is 8
                    % bytes
                    if remainingBytes < 8
                        % Reset the elapsed time since last LCP run
                        obj.ElapsedTimeSinceLastLCP(ueIdx, 1) = 0;
                        return;
                    end
                    % Get the stored logical channel id
                    lchIdx = lcpPriorityList{priorityIdx, 1}{j, 1};
                    % Check if the buffer status of the logical channel
                    % is not zero
                    if obj.LCHBufferStatus(ueIdx, lchIdx) == 0
                        continue;
                    end
                    % Don't consider the logical channels whose Bj <= 0
                    if obj.LCHBjList(ueIdx, lchIdx) <= 0
                        continue;
                    end
                    % Set the grant to minimum of the remaining
                    % bytes and Bj in LCP round-1
                    grantSize = min(obj.LCHBjList(ueIdx, lchIdx), remainingBytes);

                    % Get MAC subPDUs for the SDUs received from higher layers
                    [macSubPDUs, utilizedGrant] = getMACSubPDUs(obj, ueIdx, lchIdx, grantSize, remainingBytes - grantSize);
                    dataSubPDUList = [dataSubPDUList macSubPDUs];

                    if obj.LogicalChannelsConfig{ueIdx, lchIdx}.PBR ~= Inf
                        % Decrement the Bj by the total number of bytes
                        % used by the logical channel
                        obj.LCHBjList(ueIdx, lchIdx) = obj.LCHBjList(ueIdx, lchIdx) - utilizedGrant;
                    end
                    % Update number of bytes left in the given grant
                    remainingBytes = remainingBytes - utilizedGrant;
                end
            end
        end

        function [dataSubPDUList, remainingBytes] = performLCPRound2(obj, remainingBytes, ueIdx, lcpPriorityList)
            %performLCPRound2 Perform 2nd iteration of allocation among
            %logical channels using MAC LCP

            dataSubPDUList = {};
            % Iterate through the logical channel priority cell array,
            % from highest to lowest priority
            for priorityIdx = obj.MinPriorityForLCH:obj.MaxPriorityForLCH
                if numel(lcpPriorityList{priorityIdx, 1})
                    % Share the grant equally among all logical
                    % channels with equal priority
                    avgGrant = getEqualShareAmongLCH(obj, lcpPriorityList{priorityIdx, 1}, remainingBytes, ueIdx);
                end
                % Iterate through the logical channels which are having
                % the selected priority value
                for j = 1:numel(lcpPriorityList{priorityIdx, 1})
                    % As per Section 5.4.3.1.3 of the 3GPP TS 38.321,
                    % minimum required grant for a logical channel is 8
                    % bytes
                    if remainingBytes < 8
                        % Reset the elapsed time since last LCP run
                        obj.ElapsedTimeSinceLastLCP(ueIdx, 1) = 0;
                        return;
                    end
                    % Get the stored logical channel id
                    lchIdx = lcpPriorityList{priorityIdx, 1}{j, 1};
                    % Check if the buffer status of the logical channel
                    % is not zero
                    if obj.LCHBufferStatus(ueIdx, lchIdx) == 0
                        continue;
                    end
                    % Set the grant to minimum of the remaining
                    % bytes and Bj in LCP round-2
                    grantSize = min(avgGrant(j, 1), remainingBytes);

                    % Get MAC subPDUs for the SDUs received from higher layers
                    [macSubPDUs, utilizedGrant] = getMACSubPDUs(obj, ueIdx, lchIdx, grantSize, remainingBytes - grantSize);
                    dataSubPDUList = [dataSubPDUList macSubPDUs];

                    % Update number of bytes left in the given grant
                    remainingBytes = remainingBytes - utilizedGrant;
                end
            end
        end

        function [dataSubPDUList, utilizedGrant] = getMACSubPDUs(obj, ueIdx, lchIdx, grantSize, remainingTBS)
            %getMACSubPDUs Return MAC subPDUs, includes MAC header and SDU

            dataSubPDUList = {};
            dataPDUIdx = 1;

            % Get SDUs from higher layers
            macSDUs = obj.RLCTxFcn(ueIdx, lchIdx, grantSize, remainingTBS);
            utilizedGrant = 0;
            % Calculate the number of bytes used by the logical channel
            for sduIdx = 1:numel(macSDUs)
                dataSubPDUList{dataPDUIdx} = communication.macLayer.macSubPDU(lchIdx, macSDUs{sduIdx}, obj.MACType);
                utilizedGrant = utilizedGrant + numel(dataSubPDUList{dataPDUIdx});
                dataPDUIdx = dataPDUIdx + 1;
            end
        end

        function avgGrantSize = getEqualShareAmongLCH(obj, lchList, remainingBytes, ueIdx)
            %getEqualShareAmongLCH Assign the remaining grant among the logical channels with same priority in second round of LCP

            % Number of logical channels with the same priority
            numLCH = numel(lchList);
            % Get the buffer status of those logical channels
            bufStatusList = zeros(numLCH, 1);
            activeLCHCount = 0;
            for lchIdx = 1:numLCH
                bufStatusList(lchIdx) = obj.LCHBufferStatus(ueIdx, lchList{lchIdx});
                % Find the number of logical channels actually has data to
                % send
                if bufStatusList(lchIdx)
                    % Update the count of active logical channels
                    activeLCHCount = activeLCHCount + 1;
                end
            end
            % Initialize the assigned grant to zero for all the logical
            % channels
            avgGrantSize = zeros(numLCH, 1);
            % Check if the sum of logical channels buffer status is less
            % than grant remaining
            if sum(bufStatusList) < remainingBytes
                % Make average grant of each logical channel equal to its
                % buffer status
                avgGrantSize = bufStatusList;
            else
                % Calculate the average grant for each logical channel
                avgBytes = fix(remainingBytes/activeLCHCount);
                numBytesLeft = mod(remainingBytes, activeLCHCount);
                isNumBytesLeftLessthanRemNumLCH = false;
                % Make the resource assignment such that utilization of
                % resources is close to 100 percent
                for iter = 1:activeLCHCount % Helps in utilizing the overflown average grant of some logical channels
                    bytesFilled = 0;
                    for lchIdx = 1:numLCH % Shares the resources equally between logical channels
                        if avgGrantSize(lchIdx) == bufStatusList(lchIdx)
                            continue;
                        end
                        if isNumBytesLeftLessthanRemNumLCH && (numBytesLeft == bytesFilled)
                            % Avoid the resource allocation assignment
                            % overflow in case of number of bytes grant
                            % left is less than the logical channels
                            % requiring grant
                            avgBytes = 0;
                        end
                        bytesFilled = bytesFilled + avgBytes;
                        % Allocate average grant for each logical
                        % channel
                        avgGrantSize(lchIdx) = avgGrantSize(lchIdx) + avgBytes;
                        % Check if bytes allotted to the logical
                        % channel are more than its buffer status. If
                        % so, add the surplus bytes back to the
                        % numBytesLeft
                        if avgGrantSize(lchIdx) > bufStatusList(lchIdx)
                            % Calculate surplus amount of bytes for
                            % this logical channel from the average
                            % grant
                            numBytesLeft = numBytesLeft + (avgGrantSize(lchIdx) - bufStatusList(lchIdx));
                            avgGrantSize(lchIdx) = bufStatusList(lchIdx);
                            % Requirement of logical channel satisfied,
                            % decrement the counter of logical channels
                            % with grant requirement
                            activeLCHCount = activeLCHCount - 1;
                        end
                    end
                    % Stop sharing the grant among equally prioritized
                    % logical channels if the number of bytes remaining is
                    % 0 or isNumBytesLeftLessthanRemNumLCH flag is enabled
                    if (numBytesLeft == 0) || isNumBytesLeftLessthanRemNumLCH
                        break;
                    end
                    % If numBytesLeft is non-zero, calculate the
                    % average grant size for all the logical channels
                    % with grant requirement
                    if numBytesLeft < activeLCHCount
                        avgBytes = 1;
                        isNumBytesLeftLessthanRemNumLCH = true;
                    else
                        avgBytes = fix(numBytesLeft/activeLCHCount);
                        numBytesLeft = mod(numBytesLeft, activeLCHCount);
                    end
                end
            end
        end
    end
end