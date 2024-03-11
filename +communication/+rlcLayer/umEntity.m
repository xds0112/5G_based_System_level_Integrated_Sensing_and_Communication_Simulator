classdef umEntity < communication.rlcLayer.rlcEntity
%umEntity Implement RLC UM functionality
%   RLCUMOBJ = hNRUMEntity creates an object for the radio link control
%   (RLC) unacknowledged mode (UM) service as specified by the 3GPP TS
%   38.322.
%
%   umEntity methods:
%
%   enqueueSDU           - Queue the received service data unit (SDU) from
%                          higher layers in the Tx buffer
%   sendPDU              - Send RLC protocol data units (PDUs) that fit in
%                          the grant notified by medium access
%                          control (MAC) layer
%   getBufferStatus      - Return current buffer status of the associated
%                          logical channel
%   receivePDU           - Receive and process RLC PDU from the MAC layer
%   handleTimerTrigger   - Process 1 millisecond timer trigger
%   getStatistics        - Return statistics array
%
%   umEntity properties:
%
%   RNTI                 - UE radio network temporary identifier
%   LogicalChannelID     - Logical channel identifier
%   EntityType           - RLC UM entity type
%   SeqNumFieldLength    - Sequence number field length in bits
%   MaxTxBufferSDUs      - Maximum capacity of Tx buffer in terms of number
%                          of SDUs
%   ReassemblyTimer      - Timer to detect reassembly failure of SDUs in
%                          the reception buffer
%   MaxReassemblySDU     - Maximum number of SDUs that can be under
%                          reassembly procedure at any point of time

% Copyright 2020 The MathWorks, Inc.

    properties (Access = public)
        % RNTI Radio network temporary identifier of a UE
        %   Specify the RNTI as an integer scalar within the [1, 65519]
        %   range. For more details, refer 3GPP TS 38.321 Table 7.1-1. The
        %   default value is 1.
        RNTI (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(RNTI, 1), mustBeLessThanOrEqual(RNTI, 65519)} = 1;
        % LogicalChannelID Logical channel identifier
        %   Specify the logical channel identifier as an integer scalar
        %   within the [1, 32] range. For more details, refer 3GPP TS
        %   38.321 Table 6.2.1-1. The data radio bearers use the logical
        %   channel IDs from 4. The default is 4.
        LogicalChannelID (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(LogicalChannelID, 1), mustBeLessThanOrEqual(LogicalChannelID, 32)} = 4;
        % EntityType RLC UM entity type
        %   Specify the entity type as an integer scalar within the [0, 2]
        %   range. The values 0, 1, and 2 indicate transmitting RLC UM
        %   entity, receiving RLC UM entity, and transceiving RLC UM
        %   entity, respectively.
        EntityType (1, 1) {mustBeMember(EntityType, 0:2)}= 2;
        % SeqNumFieldLength Number of bits in sequence number field of
        % transmitter and receiver entities
        %   Specify the sequence number field length as 1-by-2 matrix where
        %   each element is one of '6' | '12'. The default is [6 6].
        %   It can also accepts scalar as an input and it will create a
        %   1-by-2 matrix with the specified input. For more details, refer
        %   3GPP TS 38.322 Section 6.2.3.3.
        SeqNumFieldLength (1, 2) {mustBeMember(SeqNumFieldLength, [6 12])} = [6 6];
        % MaxTxBufferSDUs Maximum capacity of the Tx buffer in terms of
        % number of SDUs
        %   Specify the maximum Tx buffer capacity of an RLC entity as a
        %   positive integer scalar. The default is 64.
        MaxTxBufferSDUs (1, 1) {mustBeInteger, mustBeGreaterThan(MaxTxBufferSDUs, 0)} = 64;
        % ReassemblyTimer Timer for SDU reassembly failure detection in ms
        %   Specify the reassembly timer value as one of 0, 5, 10, 15, 20,
        %   25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95,
        %   100, 110, 120, 130, 140, 150, 160, 170, 180, 190, or 200. For
        %   more details, refer 3GPP TS 38.331 information element
        %   RLC-Config. The default is 10.
        ReassemblyTimer (1, 1) {mustBeMember(ReassemblyTimer, [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, ...
                            75, 80, 85, 90, 95, 100, 110, 120, 130, 140, 150, 160, 170, ...
                            180, 190, 200])} = 10;
        % MaxReassemblySDU Maximum capacity of the reassembly buffer in
        % terms of number of SDUs
        %   Specify the maximum capacity of the reassembly buffer as an
        %   integer scalar. The reassembly buffer capacity depends on the
        %   number of HARQ processes present. If the number of SDUs under
        %   reassembly reaches the limit, the oldest SDU in the buffer will
        %   be discarded. The default is 16.
        MaxReassemblySDU (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(MaxReassemblySDU, 1)} = 16;
    end

    properties (Access = private)
        %% Tx configuration
        % TxNext Sequence number to be assigned for the next newly
        % generated UMD PDU with an SDU segment
        TxNext = 0;
        % TxSegmentOffset Position of the segmented SDU in bytes within the
        % original SDU
        TxSegmentOffset = 0;
        % TxBuffer Buffer to store the RLC SDUs received from higher
        % layers. This is a N-by-1 cell array where 'N' is the maximum
        % number of SDUs which can be buffered
        TxBuffer
        % TxHeaderBuffer Buffer to store the associated RLC headers for the
        % received SDUs from higher layers. This is a N-by-1 cell array
        % where 'N' is the maximum number of SDUs which can be buffered
        TxHeaderBuffer
        % RequiredGrantLength Length of the required grant to transmit the
        % data in the Tx buffer
        RequiredGrantLength = 0;
        % TxBufferFront Index from which the SDU can be dequeued in the Tx
        % buffer
        TxBufferFront = 0;
        % NumTxBufferSDUs Number of SDUs in the circular Tx buffer
        NumTxBufferSDUs = 0;

        %% Rx configuration
        % RxNextHighest The sequence number (SN) following the SN of the
        % unacknowledged mode data (UMD) PDU with the highest SN among
        % received UMD PDUs
        RxNextHighest = 0;
        % RxNextReassembly The earliest SN that is still considered for
        % reassembly
        RxNextReassembly = 0;
        % RxTimerTrigger The SN following the SN which triggered reassembly
        % timer
        RxTimerTrigger = 0;
        % ReassemblyTimeLeft Time to expiry of reassembly timer (ms)
        ReassemblyTimeLeft = 0;
        % RxBuffer Buffer to store the segmented SDUs for reassembly. This
        % is a N-by-1 cell array where 'N' is the maximum reassembly buffer
        % length
        RxBuffer
        % ReassemblySNMap Map that shows where the segmented SDUs are
        % stored in the reassembly buffer. This is a N-by-1 column vector
        % where 'N' is the maximum reassembly buffer length. Each element
        % contains the SN of the SDUs which are under reassembly procedure.
        % Each element in the vector can take value in the range between -1
        % and 2^SeqNumFieldLength-1. if an element is set to -1, it
        % indicates that it is not occupied by any SDUs SN
        ReassemblySNMap
        % RcvdSNList List of contiguously received full SDU SNs inside the
        % reassembly window. This is a N-by-2 matrix where 'N' is the
        % maximum reassembly buffer length. Each row has a starting SN and
        % ending SN that indicates a contiguous reception of SNs in the
        % receiving window. Value [-1, -1] in a row indicates unoccupancy
        RcvdSNList
    end

    properties (Access = private)
        %% Properties that won't get modified after their initiaization in the constructor
        % TxSeqNumFieldLength Sequence number field length of the Tx side
        TxSeqNumFieldLength
        % TotalTxSeqNum The number of SNs configured on the RLC UM
        % transmitter entity
        TotalTxSeqNum
        % RxSeqNumFieldLength Sequence number field length for the Rx side
        RxSeqNumFieldLength
        % TotalRxSeqNum The number of SNs configured on the RLC UM receiver
        % entity
        TotalRxSeqNum
        % UMWindowSize Indicates the size of the reassembly window. It is
        % used to define SNs of those UMD SDUs that can be received without
        % causing an advancement of the receiving window
        UMWindowSize = 0;
    end

    properties (Access = private)
        %% Transcient object maintained for optimization
        % DataPDUInfo Data container that holds the decoded data PDU
        % information
        DataPDUInfo
    end

    methods (Access = public)
        function obj = umEntity(config)
            %umEntity Create an RLC UM entity
            %   OBJ = hNRUMEntity(CONFIG) creates an RLC UM entity.
            %
            %   CONFIG is a structure that contains the following fields:
            %
            %   RNTI is a radio network temporary identifier, specified in
            %   the [1, 65519] range. For more details, refer 3GPP TS
            %   38.321 Table 7.1-1.
            %
            %   LogicalChannelID is a logical channel identifier, specified
            %   in the [1, 32] range. For more details, refer 3GPP TS
            %   38.321 Table 6.2.1-1.
            %
            %   SeqNumFieldLength is the length of sequence number in
            %   number of bits for the transmitter and receiver entities,
            %   specified as a 1-by-2 matrix. Each element of the
            %   SeqNumFieldLength is specified as '6' | '12'. For more
            %   details, refer 3GPP TS 38.322 Section 6.2.3.3.
            %
            %   MaxTxBufferSDUs is the maximum Tx buffer SDUs of the
            %   logical channel.
            %
            %   ReassemblyTimer is an integer scalar, specified as one of
            %   0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,
            %   100,110,120,130,140,150,160,170,180,190, or 200 ms. For
            %   more details, refer 3GPP TS 38.331 information element
            %   RLC-Config.
            %
            %   MaxReassemblySDU is an integer scalar, used as the maximum
            %   number of SDUs that can be under reassembly process at any
            %   point of time.
            %
            %   EntityType is an integer scalar, specified as one of 0, 1,
            %   or 2. The values 0, 1, and 2 indicate transmitting RLC UM
            %   entity, receiving RLC UM entity, and transceiving RLC UM
            %   entity, respectively.

            if nargin > 0
                if isfield(config, 'RNTI')
                    obj.RNTI = config.RNTI;
                end
                if isfield(config, 'LogicalChannelID')
                    obj.LogicalChannelID = config.LogicalChannelID;
                end
                if isfield(config, 'EntityType')
                    obj.EntityType = config.EntityType;
                end
                if isfield(config, 'SeqNumFieldLength')
                    obj.SeqNumFieldLength = config.SeqNumFieldLength;
                end
                if isfield(config, 'MaxTxBufferSDUs')
                    obj.MaxTxBufferSDUs = config.MaxTxBufferSDUs;
                end
                if isfield(config, 'ReassemblyTimer')
                    obj.ReassemblyTimer = config.ReassemblyTimer;
                end
                if isfield(config, 'MaxReassemblySDU')
                    obj.MaxReassemblySDU = config.MaxReassemblySDU;
                end
            end

            % Initialize Tx side configuration
            if (obj.EntityType == 0) || (obj.EntityType == 2)
                obj.TxSeqNumFieldLength = obj.SeqNumFieldLength(1);
                obj.TotalTxSeqNum = 2^obj.TxSeqNumFieldLength;
            end

            % Initialize Rx side configuration
            if (obj.EntityType == 1) || (obj.EntityType == 2)
                obj.DataPDUInfo = communication.rlcLayer.rlcDataPDUInfo();
                obj.RxSeqNumFieldLength = obj.SeqNumFieldLength(2);
                obj.UMWindowSize = 2^(obj.RxSeqNumFieldLength - 1);
                obj.TotalRxSeqNum = 2^obj.RxSeqNumFieldLength;
                % Define reassembly buffer and SN map array
                obj.RxBuffer = repmat({communication.rlcLayer.rlcDataReassembly(obj.MaxReassemblySDU)}, obj.MaxReassemblySDU, 1);
                for pktIdx = 1:obj.MaxReassemblySDU
                    obj.RxBuffer{pktIdx} = communication.rlcLayer.rlcDataReassembly(obj.MaxReassemblySDU);
                end
                obj.ReassemblySNMap = -1 * ones(obj.MaxReassemblySDU, 1);
                obj.RcvdSNList = -1 * ones(obj.MaxReassemblySDU, 2);
            end
        end

        function enqueueSDU(obj, rlcSDU)
            %enqueueSDU Queue the received SDU from higher layers in the
            % Tx buffer
            %   enqueueSDU(OBJ, RLCSDU) queues the received SDU in the Tx
            %   buffer. Also, it generates and stores the corresponding RLC
            %   UM header in a Tx header storage buffer.
            %
            %   RLCSDU is a column vector of octets in decimal format,
            %   which represents the RLC SDU.

            rlcSDULength = numel(rlcSDU);
            % The maximum RLC SDU size is 9000 bytes as per 3GPP TS 38.323
            % Section 4.3.1. If the received SDU size is more than the
            % maximum RLC SDU size, throw an error
            if rlcSDULength > obj.MaxSDUSize
                error('nr5g:hNRRLCEntity:InvalidSDUSize', 'RLC SDU size must be <= 9000 bytes');
            end
            % On Tx buffer overflow, discard the received SDU. Update the
            % statistics accordingly
            if obj.NumTxBufferSDUs == obj.MaxTxBufferSDUs
                obj.StatTxPacketsDropped = obj.StatTxPacketsDropped + 1;
                obj.StatTxBytesDropped = obj.StatTxBytesDropped + rlcSDULength;
                return;
            end
            % Store the SDU in the Tx buffer and its associated RLC header
            % in the Tx header buffer. Thereafter, update the Tx buffer
            % occupancy length
            sduEnqueueIdx = mod(obj.TxBufferFront + obj.NumTxBufferSDUs, obj.MaxTxBufferSDUs) + 1;
            obj.TxBuffer{sduEnqueueIdx} = rlcSDU;
            obj.TxHeaderBuffer{sduEnqueueIdx} = generateDataHeader(obj, 0, obj.TxSeqNumFieldLength, 0, 0);
            obj.NumTxBufferSDUs = obj.NumTxBufferSDUs + 1;
            % Increment the required grant size by the sum of expected MAC
            % header length and complete RLC PDU length
            rlcPDULength = rlcSDULength + 1;
            obj.RequiredGrantLength = obj.RequiredGrantLength + ...
                getMACHeaderLength(obj, rlcPDULength) + rlcPDULength;
            % Send the updated RLC buffer status report to MAC layer
            obj.TxBufferStatusFcn(getBufferStatus(obj));
        end

        function rlcPDUSet = sendPDU(obj, bytesGranted, remainingTBS)
            %sendPDU Send the RLC protocol data units (PDUs) that fit in the
            % grant notified by MAC layer
            %   RLCPDUSET = sendPDU(OBJ, BYTESGRANTED, REMAININGTBS) sends
            %   the RLC PDUs that fit in the grant notified by MAC.
            %
            %   RLCPDUSET is a cell array of RLC UMD PDUs to be transmitted
            %   by MAC.
            %
            %   BYTESGRANTED is a positive integer scalar, which represents
            %   the number of granted transmission bytes.
            %
            %   REMAININGTBS is a nonnegative integer scalar, which
            %   represents the remaining number of bytes in the transport
            %   block size (TBS). This helps to avoid the segmentation of
            %   RLC SDUs in round-1 of MAC logical channel prioritization
            %   (LCP) procedure.

            numBytesFilled = 0;
            rlcPDUSet = {};
            % Iterate through the RLC Tx buffer and send RLC PDUs to MAC
            % until it fulfills the granted amount of data for the
            % associated logical channel or RLC Tx buffer becomes empty
            while (numBytesFilled < bytesGranted) && ...
                    (obj.NumTxBufferSDUs > 0)
                % Calculate the current RLC PDU length and its MAC header
                % length
                pduHeaderLength = length(obj.TxHeaderBuffer{obj.TxBufferFront + 1});
                pduLength = pduHeaderLength + length(obj.TxBuffer{obj.TxBufferFront + 1}(obj.TxSegmentOffset + 1:end));
                macHeaderLength = getMACHeaderLength(obj, pduLength);
                % Check if the RLC PDU along with its MAC header does not
                % fit in the assigned grant alone or in combination with
                % the remaining TBS of the associated MAC entity
                if ((numBytesFilled + pduLength + macHeaderLength) > bytesGranted) && ...
                        ((pduLength + macHeaderLength) > remainingTBS)
                    remainingGrant = bytesGranted - numBytesFilled;
                    minGrantLength = pduHeaderLength + macHeaderLength;
                    % Check whether the grant left is not sufficient to
                    % send at least one RLC SDU byte
                    if (remainingGrant <= minGrantLength)
                        % Send the updated RLC buffer status report to MAC
                        % layer
                        obj.TxBufferStatusFcn(getBufferStatus(obj));
                        return;
                    end
                    % Segment the SDU, and modify the header
                    if obj.TxSegmentOffset
                        % Create the RLC header for middle SDU segment
                        updatedHeader = generateDataHeader(obj, 3, ...
                            obj.TxSeqNumFieldLength, obj.TxNext, obj.TxSegmentOffset);
                    else
                        % Create the RLC header for first SDU segment
                        updatedHeader = generateDataHeader(obj, 1, ...
                            obj.TxSeqNumFieldLength, obj.TxNext, obj.TxSegmentOffset);
                    end
                    % Create the RLC UMD PDU by prepending the updated
                    % header to the segmented SDU and put the RLC UMD PDU
                    % in the RLC PDU set
                    segmentedSDULength = remainingGrant - numel(updatedHeader) - macHeaderLength;
                    segmentedPDU = [updatedHeader; ...
                        obj.TxBuffer{obj.TxBufferFront + 1}(obj.TxSegmentOffset + 1:obj.TxSegmentOffset + segmentedSDULength)];
                    rlcPDUSet{end+1} = segmentedPDU;
                    % Update the statistics
                    obj.StatTxDataPDU = obj.StatTxDataPDU + 1;
                    obj.StatTxDataBytes = obj.StatTxDataBytes + numel(segmentedPDU);
                    % Increment the segment offset by segmented SDU length
                    obj.TxSegmentOffset = obj.TxSegmentOffset + segmentedSDULength;
                    % Update the header for the remaining SDU in the Tx
                    % header buffer
                    obj.TxHeaderBuffer{obj.TxBufferFront + 1} = generateDataHeader(obj, 2, ...
                        obj.TxSeqNumFieldLength, obj.TxNext, obj.TxSegmentOffset);
                    % Get the remaining RLC PDU length
                    newPDULength = length(obj.TxHeaderBuffer{obj.TxBufferFront + 1}) + ...
                        length(obj.TxBuffer{obj.TxBufferFront + 1}) - obj.TxSegmentOffset;
                    % Increment the utilized grant by remaining grant size
                    % and update the required grant size as sum of the
                    % updated MAC header length, RLC PDU length
                    numBytesFilled = numBytesFilled + remainingGrant;
                    obj.RequiredGrantLength = obj.RequiredGrantLength - ...
                        (pduLength - newPDULength) + ...
                        (macHeaderLength - getMACHeaderLength(obj, newPDULength));
                else
                    % Create the RLC UMD PDU by prepending the header to
                    % the SDU and put the RLC UMD PDU in the RLC PDUs set
                    normalPDU = [obj.TxHeaderBuffer{obj.TxBufferFront + 1}; ...
                        obj.TxBuffer{obj.TxBufferFront + 1}(obj.TxSegmentOffset + 1:end)];
                    rlcPDUSet{end+1} = normalPDU;
                    % Update the statistics
                    obj.StatTxDataPDU = obj.StatTxDataPDU + 1;
                    obj.StatTxDataBytes = obj.StatTxDataBytes + numel(normalPDU);
                    % Increment the sequence number after the submission of
                    % last segment of the segmented SDU
                    if (obj.TxSegmentOffset)
                        obj.TxNext = mod(obj.TxNext + 1, obj.TotalTxSeqNum);
                        obj.TxSegmentOffset = 0;
                    end
                    % Increment the utilized grant by the sum of RLC PDU
                    % length and MAC header length. Decrement the required
                    % grant length also by the sum of RLC PDU length and
                    % MAC header length
                    numBytesFilled = numBytesFilled + pduLength + macHeaderLength;
                    obj.RequiredGrantLength = obj.RequiredGrantLength - ...
                        (pduLength + macHeaderLength);
                    obj.TxBufferFront = mod(obj.TxBufferFront + 1, obj.MaxTxBufferSDUs);
                    obj.NumTxBufferSDUs = obj.NumTxBufferSDUs - 1;
                    % If Tx buffer is empty, no grant is required
                    if obj.NumTxBufferSDUs == 0
                        obj.RequiredGrantLength = 0;
                    end
                end
            end
            % Send the updated RLC buffer status report to MAC layer
            obj.TxBufferStatusFcn(getBufferStatus(obj));
        end

        function bufferStatusReport = getBufferStatus(obj)
            %getBufferStatus Return the current buffer status of the
            % associated logical channel
            %   BUFFERSTATUSREPORT = getBufferStatus(OBJ) returns the
            %   current buffer status of the associated logical channel.
            %
            %   BUFFERSTATUSREPORT is a handle object, which contains the
            %   following fields:
            %       RNTI                - Radio network temporary
            %                             identifier
            %       LogicalChannelID    - Logical channel identifier
            %       BUFFERSTATUS        - Required grant for transmitting
            %                             the stored RLC SDUs

            % Create a hNRRLCBufferStatus object that holds buffer status
            % of the associated logical channel
            bufferStatusReport = communication.rlcLayer.rlcBufferStatus(obj.RNTI, obj.LogicalChannelID, ...
                obj.RequiredGrantLength);
        end

        function sdu = receivePDU(obj, packet)
            %receivePDU Receive and process RLC PDU from the MAC layer
            %   SDU = receivePDU(OBJ, PACKET) Receives and processes RLC
            %   PDU from the MAC layer. On a complete SDU reception, if a
            %   callback is registered then forward the packet to higher
            %   layer. However, the SDU is also returned as an output argument.
            %
            %   SDU is a column vector of octets in decimal format where
            %   each element is of type uint8.
            %
            %   PACKET is the column vector of octets in decimal format.

            sdu = [];
            % Decode the RLC UMD PDU received from the MAC layer
            decodeDataPDU(obj, packet, obj.RxSeqNumFieldLength);
            decodedPDU = obj.DataPDUInfo;
            % Update the statistics
            obj.StatRxDataPDU = obj.StatRxDataPDU + 1;
            obj.StatRxDataBytes = obj.StatRxDataBytes + decodedPDU.PDULength;
            % On the reception of complete SDU, forward it to upper layer
            if decodedPDU.SegmentationInfo == 0
                sdu = uint8(decodedPDU.Data);
            else
                snModuloValue = getModulusValue(obj, decodedPDU.SequenceNumber);
                % If the received SDU segment is an old segment, discard
                % it. Otherwise, store it in the reception buffer for
                % reassembly
                if(getModulusValue(obj, obj.RxNextHighest - obj.UMWindowSize) <= ...
                        snModuloValue) && (snModuloValue < getModulusValue(obj, obj.RxNextReassembly))
                    obj.StatRxDataPDUDropped = obj.StatRxDataPDUDropped + 1;
                    obj.StatRxDataBytesDropped = obj.StatRxDataBytesDropped + numel(packet);
                else
                    % Put the received SDU segment in the reassembly
                    % buffer. If the reassembly buffer is full, remove the
                    % oldest SDU and place the newly received SDU in the
                    % buffer
                    snBufIdx = assignReassemblyBufIdx(obj, decodedPDU.SequenceNumber);
                    if snBufIdx < 0
                        [~, snBufIdx] = min(getModulusValue(obj, obj.ReassemblySNMap));
                        [numSegments, numBytes] = removeSNSegments(obj.RxBuffer{snBufIdx});
                        obj.StatRxDataPDUDropped = obj.StatRxDataPDUDropped + numSegments;
                        obj.StatRxDataBytesDropped = obj.StatRxDataBytesDropped + numBytes;
                        obj.ReassemblySNMap(snBufIdx) = decodedPDU.SequenceNumber;
                    end
                    isLastSegment = false;
                    if decodedPDU.SegmentationInfo == 2
                        isLastSegment = true;
                    end
                    [numDupBytes, isReassembled] = reassembleSegment(obj.RxBuffer{snBufIdx}, decodedPDU.Data, decodedPDU.PDULength, decodedPDU.SegmentOffset, isLastSegment);
                    if numDupBytes
                        % Update the duplicate segment reception statistics
                        obj.StatRxDataPDUDuplicate = obj.StatRxDataPDUDuplicate + 1;
                        obj.StatRxDataBytesDuplicate = obj.StatRxDataBytesDuplicate + numDupBytes;
                        return;
                    end

                    % On the reception of all SDU segments, reassemble and
                    % deliver it to upper layer
                    if isReassembled
                        [rxSDU, sduLen] = getReassembledSDU(obj.RxBuffer{snBufIdx});
                        sdu = rxSDU(1:sduLen);
                    end
                    % Update the RLC UM receiver state based on the
                    % received segmented SDU sequence number
                    updateRxState(obj, decodedPDU.SequenceNumber, isReassembled);
                end
            end

            % Forward the received SDU to application layer if any callback
            % is registered
            if ~isempty(obj.RxForwardFcn) && ~isempty(sdu)
                obj.RxForwardFcn(sdu, obj.RNTI);
            end
        end

        function handleTimerTrigger(obj)
            %handleTimerTrigger Process 1 millisecond timer trigger

            if obj.ReassemblyTimeLeft > 0
                % Decrement the time left for reassembly timer expiry
                obj.ReassemblyTimeLeft = obj.ReassemblyTimeLeft - 1;
                % Check whether the reassembly timer is expired
                if obj.ReassemblyTimeLeft == 0
                    obj.StatTimerReassemblyTimedOut = obj.StatTimerReassemblyTimedOut + 1;
                    % Handle the reassembly timer expiry
                    reassemblyTimerExpiry(obj);
                end
            end
        end
    end

    methods (Access = private)
        function rlcUMHeader = generateDataHeader(~, segmentationInfo, seqNumFieldLength, segmentSeqNum, segmentOffset)
            %generateDataHeader Generate header for RLC UMD PDU

            % Create an UMD PDU header column vector with the maximum RLC
            % UM header length and initialize it with segmentation
            % information in the first byte
            umdPDUHeader = [segmentationInfo; zeros(3, 1)];
            % Initialize the UMD PDU header length as 1 by considering the
            % minimum RLC UM header length
            umdPDUHeaderLen = 1;

            if segmentationInfo == 0
                % Create an RLC UM header for the complete SDU. The header
                % format is segmentation information (2 bits) | reserved (6
                % bits)
                rlcUMHeader = umdPDUHeader(umdPDUHeaderLen);
            else
                % Update sequence number field in the RLC UM header based
                % on the configured size for sequence number
                if seqNumFieldLength == 6
                    % Header format is segmentation information (2 bits) |
                    % sequence number (6 bits)
                    umdPDUHeader(1:umdPDUHeaderLen) = ...
                        bitor(bitshift(segmentationInfo, 6), segmentSeqNum);
                else
                    % Set the header length to 2 bytes when the number of
                    % bits for a sequence number is 12. The header format
                    % is segmentation information (2 bits) | reserved (2
                    % bits) | sequence number (12 bits)
                    umdPDUHeaderLen = 2;
                    % Update the sequence number value in the RLC UM header
                    % by spanning it over the last 4 bits of the first byte
                    % and 2nd byte of the header
                    umdPDUHeader(1:umdPDUHeaderLen) = ...
                        [bitor(bitshift(segmentationInfo, 6), bitand(bitshift(segmentSeqNum, -8), 15));...
                        bitand(segmentSeqNum, 255)];
                end

                % Append the segment offset to the RLC UM header for middle
                % and last segments
                if (segmentationInfo == 2) || (segmentationInfo == 3)
                    umdPDUHeaderLen = umdPDUHeaderLen + 2;
                    umdPDUHeader(umdPDUHeaderLen-1: umdPDUHeaderLen) = ...
                        [bitshift(segmentOffset, -8); ...
                        bitand(segmentOffset, 255)];
                end
                rlcUMHeader = umdPDUHeader(1:umdPDUHeaderLen);
            end
        end

        function decodeDataPDU(obj, rlcPDU, seqNumFieldLength)
            %decodeDataPDU Decode the RLC UMD PDU

            decodedPDU = obj.DataPDUInfo;
            decodedPDU.PDULength = numel(rlcPDU);
            % Extract the segmentation information present in the first 2
            % bits of the RLC UMD PDU
            decodedPDU.SegmentationInfo = bitshift(rlcPDU(1), -6);
            % Extract RLC SDU or RLC SDU segment based on the segmentation
            % information
            if decodedPDU.SegmentationInfo == 0
                % Extract the whole RLC SDU from the RLC UMD PDU
                decodedPDU.Data = rlcPDU(2:end);
            else
                if seqNumFieldLength == 6
                    % Get the sequence number from the last 6 bits of the
                    % first byte from the received PDU
                    decodedPDU.SequenceNumber = bitand(rlcPDU(1), 63);
                    % Set segment offset index to 2 such that it points to
                    % segment offset field, except in case of first segment
                    % of an SDU
                    segmentOffsetIndex = 2;
                else
                    % Get the sequence number using the last 4 bits of the
                    % first byte and the complete second byte from the
                    % received PDU
                    decodedPDU.SequenceNumber = bitshift(bitand(rlcPDU(1), 15), 8) + rlcPDU(2);
                    % Set segment offset index to 3 such that it points to
                    % segment offset field, except in case of first segment
                    % of an SDU
                    segmentOffsetIndex = 3;
                end

                % Check whether the first segment of the SDU is received
                if decodedPDU.SegmentationInfo == 1
                    % Extract the RLC SDU segment from the first segmented
                    % RLC UMD PDU
                    decodedPDU.SegmentOffset = 0;
                    decodedPDU.Data = rlcPDU(segmentOffsetIndex:end);
                else
                    % Extract the RLC SDU segment offset information from
                    % the middle or last RLC UMD PDUs
                    decodedPDU.SegmentOffset = bitshift(rlcPDU(segmentOffsetIndex), 8) +  rlcPDU(segmentOffsetIndex+1);
                    % Extract the RLC SDU segment from the RLC UMD PDU
                    decodedPDU.Data = rlcPDU(segmentOffsetIndex+2:end);
                end
            end
        end

        function macHeaderLength = getMACHeaderLength(~, pduLength)
            %getMACHeaderLength Return the MAC header length in bytes
            % for the given RLC PDU length

            macHeaderLength = 2;
            if pduLength > 255
                macHeaderLength = 3;
            end
        end

        function updateRxState(obj, currPktSeqNum, isReassembled)
            %updateRxState Process the received UMD PDU that contain RLC SDU
            % segment

            % Check whether all the SDU segments are received for the given
            % sequence number
            if isReassembled
                % When received PDU sequence number and the earliest SN
                % considered for reassembly are equal, update the the SN
                % considered for reassembly to the least SN of received PDU
                % sequence numbers that has not been reassembled and
                % delivered to upper layer
                if currPktSeqNum == obj.RxNextReassembly
                    % Select the next lower edge of the reassembly window
                    minSN = mod(currPktSeqNum + 1, obj.TotalRxSeqNum);
                    % If the selected next lower edge of the reassembly
                    % window is already received as a part of some
                    % contiguous reception, choose the SN after the upper
                    % edge of the contiguous reception as a new next lower
                    % edge of the reassembly window
                    receptionIndex = (obj.RcvdSNList(:, 1) <= minSN) & ...
                        (obj.RcvdSNList(:, 2) >= minSN);
                    if any(receptionIndex)
                        minSN = obj.RcvdSNList(receptionIndex, 2) + 1;
                    end
                    obj.RxNextReassembly = minSN;
                end
                % Update the completely received SNs context between the
                % lower edge and upper edge of the reassembly window
                updateRxGaps(obj, currPktSeqNum);
            elseif ~isInsideReassemblyWindow(obj, currPktSeqNum)
                handleOutOfWindowSN(obj, currPktSeqNum);
            end

            % Update the reassembly timer state as per Section 5.2.2.2.3 of
            % 3GPP TS 38.322
            updateRxStateOnRTRun(obj);
            updateRxStateOnRTStop(obj);
        end

        function isInside = isInsideReassemblyWindow(obj, seqNum)
            %isInsideReassemblyWindow Check if the given sequence number
            % falls within the reassembly window

            isInside = false;
            % If the given sequence number falls inside the reassembly
            % window as per Section 5.2.2.2.1 of 3GPP TS 38.322, then set
            % the flag to true
            if (getModulusValue(obj, obj.RxNextHighest - obj.UMWindowSize) <= ...
                    getModulusValue(obj, seqNum)) && (getModulusValue(obj, seqNum) < getModulusValue(obj, obj.RxNextHighest))
                isInside = true;
            end
        end

        function modValue = getModulusValue(obj, value)
            %getModulusValue Calculate the modulus of the given value

            % Calculate modulus for the given value as per Section 7.1 of
            % 3GPP TS 38.322
            modValue = mod(value - (obj.RxNextHighest - obj.UMWindowSize), obj.TotalRxSeqNum);
        end

        function discardPDUsOutsideReassemblyWindow(obj)
            %discardPDUsOutsideReassemblyWindow Discard the received RLC
            % PDUs which fall outside of the reassembly window

            % Iterate through each SN and remove the segmented PDUs
            % associated with that SN if the SN falls outside of the
            % reassembly window
            for i = 1:obj.MaxReassemblySDU
                % Check whether the current sequence number is active
                if obj.ReassemblySNMap(i) ~= -1
                    if ~isInsideReassemblyWindow(obj, obj.ReassemblySNMap(i))
                        % Discard the SDU segments which are received for
                        % the current SN
                        [numSegments, numBytes] = removeSNSegments(obj.RxBuffer{i});
                        obj.StatRxDataPDUDropped = obj.StatRxDataPDUDropped + numSegments;
                        obj.StatRxDataBytesDropped = obj.StatRxDataBytesDropped + numBytes;
                    end
                end
            end
        end

        function reassemblyTimerExpiry(obj)
            %reassemblyTimerExpiry Perform the actions required after
            % the expiry of reassembly timer

            % Update RxNextReassembly to the SN of the first SN >=
            % RxTimerTrigger that has not been reassembled
            minSN = obj.RxTimerTrigger; % Select the next lower edge of the reassembly window
            % If the selected next lower edge of the reassembly
            % window is already received as a part of some
            % contiguous reception, choose the SN after the upper
            % edge of the contiguous reception as a new next lower
            % edge of the reassembly window
            receptionIndex = (obj.RcvdSNList(:, 1) <= minSN) & ...
                        (obj.RcvdSNList(:, 2) >= minSN);
            if any(receptionIndex)
                minSN = obj.RcvdSNList(receptionIndex, 2) + 1;
            end
            % Set RxNextReassembly to a new sequence number
            obj.RxNextReassembly = minSN;

            % Discard all the segments with SN < updated RxNextReassembly
            for seqNumIdx = 1:obj.MaxReassemblySDU
                seqNum = obj.ReassemblySNMap(seqNumIdx);
                if (getModulusValue(obj, seqNum) < getModulusValue(obj, obj.RxNextReassembly))
                    % Discard the segmented PDUs which are received for the
                    % current SN and update the statistics
                    [numSegments, numBytes] = removeSNSegments(obj.RxBuffer{seqNumIdx});
                    obj.StatRxDataPDUDropped = obj.StatRxDataPDUDropped + numSegments;
                    obj.StatRxDataBytesDropped = obj.StatRxDataBytesDropped + numBytes;
                end
            end

            % If RX_Next_Highest > RX_Next_Reassembly + 1; or
            % If RX_Next_Highest = RX_Next_Reassembly + 1 and there is
            % at least one missing byte segment of the RLC SDU associated
            % with SN = RX_Next_Reassembly before the last byte of all
            % received segments of this RLC SDU:
            %   - start t-Reassembly;
            %   - set RX_Timer_Trigger to RX_Next_Highest.
            rxNextReassembly = mod(obj.RxNextReassembly + 1, obj.TotalRxSeqNum);
            rxNextHighest = getModulusValue(obj, obj.RxNextHighest);
            rnrBufIdx = getSDUReassemblyBufIdx(obj, obj.RxNextReassembly);
            if (rxNextHighest > getModulusValue(obj, rxNextReassembly)) || ...
                    ((rxNextHighest == getModulusValue(obj, rxNextReassembly)) && ...
                    ((rnrBufIdx ~= -1) && anyLostSegment(obj.RxBuffer{rnrBufIdx,1})))
                % Start the reassembly timer
                obj.ReassemblyTimeLeft = obj.ReassemblyTimer;
                obj.RxTimerTrigger = obj.RxNextHighest;
            end
        end

        function snBufIdx = getSDUReassemblyBufIdx(obj, sn)
            %getSDUReassemblyIdx Return the reassembly buffer index in
            % which SDU is stored

            snBufIdx = -1;
            for bufIdx = 1:obj.MaxReassemblySDU
                if obj.ReassemblySNMap(bufIdx) == sn
                    snBufIdx = bufIdx;
                    break;
                end
            end
        end

        function snBufIdx = assignReassemblyBufIdx(obj, sn)
            %assignReassemblyBufIdx Find a place to store the specified
            % SN's SDU in the reassembly buffer

            % Find out an empty RLC reassembly buffer for segmented SDU
            snBufIdx = getSDUReassemblyBufIdx(obj, sn);
            if snBufIdx ~= -1
                % Return if SDU has been allotted a buffer for reassembly
                return;
            end
            % Find an empty buffer to store the SDU
            for bufIdx = 1:obj.MaxReassemblySDU
                if obj.ReassemblySNMap(bufIdx) == -1
                    snBufIdx = bufIdx;
                    obj.ReassemblySNMap(snBufIdx) = sn;
                    break;
                end
            end
        end

        function updateRxStateOnRTRun(obj)
            %updateRxStateOnRTRun Update the reassembly timer state
            % and Rx state variables if reassembly timer is running

            % Stop the reassembly timer if any of the following conditions
            % is met:
            %   - if RX_Timer_Trigger <= RX_Next_Reassembly; or
            %
            %   - if RX_Timer_Trigger falls outside of the reassembly
            %   window and RX_Timer_Trigger is not equal to
            %   RX_Next_Highest; or
            %
            %   - if RX_Next_Highest = RX_Next_Reassembly + 1 and there is
            %   no missing byte segment of the RLC SDU associated with SN =
            %   RX_Next_Reassembly before the last byte of all received
            %   segments of this RLC SDU
            if obj.ReassemblyTimeLeft > 0
                stopRT = false;
                rxNextReassemlby = mod(obj.RxNextReassembly + 1, obj.TotalRxSeqNum);
                rnrBufIdx = getSDUReassemblyBufIdx(obj, obj.RxNextReassembly);
                if getModulusValue(obj, obj.RxTimerTrigger) <= getModulusValue(obj, obj.RxNextReassembly)
                    stopRT = true;
                elseif ~(isInsideReassemblyWindow(obj, obj.RxTimerTrigger)) && (obj.RxTimerTrigger ~= obj.RxNextHighest)
                    stopRT = true;
                elseif ((obj.RxNextHighest == rxNextReassemlby) &&  ...
                    ((rnrBufIdx ~= -1) && ~anyLostSegment(obj.RxBuffer{rnrBufIdx})))
                    stopRT = true;
                end

                if stopRT
                    obj.ReassemblyTimeLeft = 0;
                end
            end
        end

        function updateRxStateOnRTStop(obj)
            %updateRxStateOnRTStop Update the reassembly timer state
            % and Rx state variables if reassembly timer is not running

            if obj.ReassemblyTimeLeft == 0
                rxNextReassembly = mod(obj.RxNextReassembly + 1, obj.TotalRxSeqNum);
                rnrBufIdx = getSDUReassemblyBufIdx(obj, obj.RxNextReassembly);
                startRT = false;
                % Start the reassembly timer if any of the following
                % conditions is met:
                %   - At least one missing SN between lower and upper ends
                %   of the receiving window
                %   - At least one missing segment between lower and upper
                %   ends of the receiving window when upper end = lower
                %   end + 1
                if getModulusValue(obj, obj.RxNextHighest) > getModulusValue(obj, rxNextReassembly)
                    startRT = true;
                elseif (getModulusValue(obj, obj.RxNextHighest) == getModulusValue(obj, rxNextReassembly)) && ...
                        ((rnrBufIdx ~= -1) && anyLostSegment(obj.RxBuffer{rnrBufIdx}))
                    startRT = true;
                end

                if startRT
                    obj.ReassemblyTimeLeft = obj.ReassemblyTimer;
                    obj.RxTimerTrigger = obj.RxNextHighest;
                end
            end
        end

        function handleOutOfWindowSN(obj, currPktSeqNum)
            %handleOutOfWindowSN Update the receiver state on reception
            % of SDU that falls outside of the reassembly window

            % Update the upper end of reassembly window to the received
            % PDU sequence number + 1. This update pulls the reassembly
            % window as the window size is fixed
            obj.RxNextHighest = mod(currPktSeqNum + 1, obj.TotalRxSeqNum);
            % Discard the PDUs that fall outside of the reassembly window
            % due to window movement
            discardPDUsOutsideReassemblyWindow(obj);
            % Check whether the earliest SN considered for reassembly falls
            % outside of the reassembly window
            if ~isInsideReassemblyWindow(obj, obj.RxNextReassembly)
                % Select the next lower edge of the window
                minSN = mod(obj.RxNextHighest - obj.UMWindowSize, obj.TotalRxSeqNum);
                % If the selected next lower edge of the reassembly
                % window is already received as a part of some
                % contiguous reception, choose the SN after the upper
                % edge of the contiguous reception as a new next lower
                % edge of the reassembly window
                receptionIndex = (obj.RcvdSNList(:, 1) <= minSN) & ...
                        (obj.RcvdSNList(:, 2) >= minSN);
                if any(receptionIndex)
                	minSN = obj.RcvdSNList(receptionIndex, 2) + 1;
                end
                obj.RxNextReassembly = minSN;
            end

            % Update the completely received SN's list in the reassembly
            % window when the upper edge of the window is changed
            validIndex = getModulusValue(obj, obj.RcvdSNList(:, 1)) > obj.UMWindowSize;
            if any(validIndex)
                obj.RcvdSNList(validIndex, :) = -1;
            end
        end

        function updateRxGaps(obj, sn)
            %updateRxGaps Update the completely received SDUs context

            % Identify whether this complete SDU reception is an extension
            % of an existing contiguous SDU reception. This can be checked
            % by finding its previous and following SDUs reception status
            prevSNRxStatus = (obj.RcvdSNList(:, 2) == mod(sn - 1, obj.TotalRxSeqNum));
            nextSNRxStatus = (obj.RcvdSNList(:, 1) == mod(sn + 1, obj.TotalRxSeqNum));
            isPrevSNContigious = any(prevSNRxStatus);
            isNextSNContigious = any(nextSNRxStatus);
            if ~isPrevSNContigious && ~isNextSNContigious
                % Create a new contiguous reception since it is not
                % extending any other existing contiguous reception
                indices = find(obj.RcvdSNList == [-1, -1], 1);
                obj.RcvdSNList(indices, 1) = sn;
                obj.RcvdSNList(indices, 2) = sn;
            elseif isPrevSNContigious && ~isNextSNContigious
                obj.RcvdSNList(prevSNRxStatus, 2) = sn;
            elseif ~isPrevSNContigious && isNextSNContigious
                obj.RcvdSNList(nextSNRxStatus, 1) = sn;
            else
                % Merge the two contiguous receptions since the new SDU
                % makes them one contiguous reception
                obj.RcvdSNList(prevSNRxStatus, 2) = obj.RcvdSNList(nextSNRxStatus, 2);
                obj.RcvdSNList(nextSNRxStatus, 1:2) = -1;
            end
        end
    end
end