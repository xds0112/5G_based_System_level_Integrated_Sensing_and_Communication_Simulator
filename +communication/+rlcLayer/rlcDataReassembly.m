classdef rlcDataReassembly < handle
%rlcDataReassembly Create an RLC SDU reassembly information object
%   RLCSDUREASSEMBLEOBJECT = hNRRLCDataReassembly() creates a radio link
%   control (RLC) service data unit (SDU) reassembly information object.
%
%   rlcDataReassembly methods:
%   reassembleSegment      - Reassemble the received SDU segment if it is
%                            not a duplicate segment
%   getReassembledSDU      - Return the reassembled RLC SDU
%   getSDUReassemblyStatus - Return the reassembly status of the SDU
%   removeSNSegments       - Remove the segments associated with that
%                            sequence number and reset the context
%                            information
%   anyLostSegment         - Check if there is any lost segment in the SDU
%   getLostSegmentsInfo    - Return the lost segments information as an
%                            array

% Copyright 2019-2021 The MathWorks, Inc.

    properties (Access = public)
        % MaxSegmentGapsPerSDU Maximum segment gaps that are allowed in the
        % reception of segmented SDUs
        MaxSegmentGapsPerSDU = 16;
    end

    properties (Access = private)
        % SDU Buffer that stores the segmented SDUs for reassembly process
        SDU uint8
        % NumSDUBytesFilled Number of bytes received within the actual SDU
        NumSDUBytesFilled = 0;
        % SDULength Size of the complete SDU in bytes. This will be found
        % on the reception of the last segment of SDU
        SDULength = 0;
        % NumSegmentsRcvd Number of segmented SDUs received. This helps in
        % updating the RLC statistics such as segments discarded on the
        % reassembly failure
        NumSegmentsRcvd = 0;
        % NumPDUBytesRcvd Number of RLC PDU bytes received for the SDU.
        % This helps in updating the RLC statistics such as bytes discarded
        % on the reassembly failure
        NumPDUBytesRcvd = 0;
        % isLastSegmentReceived Flag that indicates whether last segment
        % has been received before the reassembly timer expires
        isLastSegmentReceived = false;
        % MissingSegmentsInfo Missing segments information that helps in
        % tracking of the segment which are yet to be received
        MissingSegmentsInfo
    end

    properties (Access = private, Constant)
        % MaxSDUSize Maximum RLC SDU size
        MaxSDUSize = 9000;
    end

    methods
        function obj = rlcDataReassembly(maxSegmentGapsPerSDU)
            %rlcDataReassembly Construct an RLC SDU reassembly
            % information object
            %   OBJ = hNRRLCDataReassembly() initializes the RLC SDU
            %   reassembly information object.

            obj.SDU = zeros(obj.MaxSDUSize, 1);
            obj.MaxSegmentGapsPerSDU = maxSegmentGapsPerSDU;
            obj.MissingSegmentsInfo = [0 65535; -1 * ones(obj.MaxSegmentGapsPerSDU-1, 2)];
        end

        function [numDupBytes, isReassembled] = reassembleSegment(obj, sduSegment, pduLength, segmentOffset, isLastSegment)
            %reassembleSegment Reassemble the received SDU segment if it is
            % not a duplicate segment
            %   [NUMDUPBYTES, ISREASSEMBLED] = reassembleSegment(OBJ,
            %   SDUSEGMENT, PDULENGTH, SEGMENTOFFSET, ISLASTSEGMENT)
            %   reassembles the received segment to form the complete SDU
            %   if it is not a duplicate segment.
            %
            %   NUMDUPBYTES is the output integer scalar, returned as an
            %   integer. If the value is non-zero, the received segment has
            %   duplicate bytes. Otherwise, it is not a duplicate segment.
            %
            %   ISREASSEMBLED is the output logical scalar, returned as
            %   true or false. If the value is true, the reassembly of full
            %   SDU has been completed. Otherwise, it is not yet
            %   reassembled.
            %
            %   SDUSEGMENT is the received segment, specified as a column
            %   vector of octets in decimal format.
            %
            %   PDULENGTH is the length of the received RLC PDU, specified
            %   as an integer scalar.
            %
            %   SEGMENTOFFSET is the offset of the received segment within
            %   its complete SDU, specified as an integer scalar.
            %
            %   ISLASTSEGMENT is the flag to inform whether the received
            %   segment is last, specified as a logical scalar. If the
            %   value is true, it is the last segment. Otherwise, it is
            %   either a starting segment or a middle segment of the
            %   complete SDU.

            isReassembled = false;
            segmentLength = numel(sduSegment);
            numNewBytes = updateMissingSegmentsContext(obj, segmentOffset, segmentLength, isLastSegment);

            numDupBytes = segmentLength - numNewBytes;
            if numDupBytes == segmentLength
                % Don't do any further processing on the reception of a
                % complete duplicate segment
                return;
            end
            % Reassemble the segment by updating its bytes in the full
            % SDU buffer
            obj.SDU(segmentOffset+1:segmentOffset+segmentLength) = sduSegment;
            % Maintain the sum of the unique segments count and size to
            % provide proper statistics in case of reassembly failure
            obj.NumSegmentsRcvd = obj.NumSegmentsRcvd + 1;
            obj.NumPDUBytesRcvd = obj.NumPDUBytesRcvd + pduLength;
            % Update the actual SDU length on the reception of the last
            % SDU segment. This will help in identifying the end of SDU
            % reassembly
            if isLastSegment
                obj.SDULength = segmentOffset + segmentLength;
                obj.isLastSegmentReceived = true;
            end
            % Update the number of received bytes till now for this SDU
            % reassembly
            obj.NumSDUBytesFilled = obj.NumSDUBytesFilled + segmentLength - numDupBytes;
            % Check whether the SDU is fully reassembled
            if obj.SDULength == obj.NumSDUBytesFilled
                isReassembled = true;
            end
        end

        function [sdu, sduLen] = getReassembledSDU(obj)
            %getReassembledSDU Return the reassembled SDU and its length
            % and reset the reassembly buffer context
            %   [SDU, SDULEN] = getReassembledSDU(OBJ) returns the
            %   reassembled SDU and its length and resets the reassembly
            %   buffer context.
            %
            %   SDU is the output complete SDU, returned as a column vector
            %   of octets in decimal format.
            %
            %   SDULEN is the length of the complete SDU, returned as a
            %   scalar integer.

            sduLen = double(obj.SDULength);
            sdu = obj.SDU;
            resetSDUReassemblyInfo(obj);
        end

        function [NumSegments, NumBytesRcvd] = removeSNSegments(obj)
            %removeSNSegments Remove the SDU from the reassembly procedure
            % by resetting the properties to default
            %   [NUMSEGMENTS, NUMBYTESRCVD] = removeSNSegments(OBJ)
            %   discards all the segments received for the reassembly of
            %   the SDU till now and returns the information that is needed
            %   for the statistics update.
            %
            %   NUMSEGMENTS is the number of segmented PDUs received,
            %   returned as an integer scalar.
            %
            %   NumBytesRcvd is the number of segmented PDU bytes received,
            %   returned as an integer scalar.

            NumSegments = double(obj.NumSegmentsRcvd);
            NumBytesRcvd = double(obj.NumPDUBytesRcvd);
            resetSDUReassemblyInfo(obj);
        end

        function status = anyLostSegment(obj)
            %anyLostSegment Check if there is any lost segment in the SDU

            status = true;
            % Check if no segments are received or the received segment
            % bytes are contiguous without a gap for the SDU. Upon the
            % contiguous reception of the segments, the SDU's missing
            % segment end offset is 65535 since segment length is not known
            % yet
            numMissingSegmentEnds = obj.MissingSegmentsInfo(obj.MissingSegmentsInfo(:, 2) >= 0, 2);
            if (numel(numMissingSegmentEnds) == 0) || ...
                    (numel(numMissingSegmentEnds) == 1) && any(numMissingSegmentEnds == 65535)
                status = false;
            end
        end

        function segmentsInfo = getLostSegmentsInfo(obj)
            %getLostSegmentsInfo Find and return the lost segments
            % information

            segmentStarts = obj.MissingSegmentsInfo(:, 1);
            segmentEnds = obj.MissingSegmentsInfo(:, 2);
            logicalVector = segmentStarts >= 0;
            segmentsInfo = [segmentStarts(logicalVector) segmentEnds(logicalVector)];
        end
    end

    methods (Access = private)
        function resetSDUReassemblyInfo(obj)
            %resetSDUReassemblyInfo Reset the context of the object

            % Reset all the properties of the object since it has to be
            % used for the reassembly of the segmented SDU with same
            % sequence number
            obj.SDULength = 0;
            obj.NumSDUBytesFilled = 0;
            obj.NumSegmentsRcvd = 0;
            obj.NumPDUBytesRcvd = 0;
            obj.MissingSegmentsInfo = [0 65535; -1 * ones(obj.MaxSegmentGapsPerSDU-1, 2)];
        end

        function numBytesForFillingGap = updateMissingSegmentsContext(obj, segmentStart, segmentLength, isLastSegment)
            %updateMissingSegmentsContext Update the missing segments
            % information

            segmentEnd = segmentStart + segmentLength - 1;
            numBytesForFillingGap = 0;
            isHoleSplit = false;
            for idx = 1:size(obj.MissingSegmentsInfo, 1)
                hole = obj.MissingSegmentsInfo(idx, :);
                % No further processing is needed for invalid segment
                % gaps
                if hole(1) == -1
                    continue;
                end
                % If the received segment does not overlap with the
                % selected hole in any way, no further attention is needed
                % to this hole
                if (hole(1) > segmentEnd) || ...
                        (hole(2) < segmentStart)
                    continue;
                end
                % Delete the current hole since it has some overlap with
                % the received segment
                obj.MissingSegmentsInfo(idx, :) = -1;
                filledHolePart = hole;
                % If the first part of the hole is not filled by the
                % received segment, create a new small hole
                if segmentStart > hole(1)
                    obj.MissingSegmentsInfo(idx, 1) = hole(1);
                    obj.MissingSegmentsInfo(idx, 2) = segmentStart - 1;
                    % Keep track of the number bytes of segment used for
                    % filling the hole. This helps in identifying the
                    % duplicate bytes
                    filledHolePart(1) = segmentStart;
                    isHoleSplit = true;
                end
                % Create a new small hole if the second part of the hole is
                % not filled
                if segmentEnd < hole(2)
                    offset = idx;
                    % Find an empty index in the missing segments list to
                    % store the new hole when the current hole splits into
                    % two
                    if isHoleSplit
                        offset = find(obj.MissingSegmentsInfo(:, 1) == -1, 1);
                    end
                    filledHolePart(2) = min(segmentEnd, hole(2));
                    % Do not create a hole that reaches from the last octet
                    % of the SDU to maximum segment size after the
                    % reception of last segment. The above mentioned hole
                    % is only useful when we do not know the size of the
                    % SDU
                    if isLastSegment && (segmentEnd  == (segmentStart + segmentLength - 1))
                        % Calculate the number of bytes used for filling this hole
                        numBytesForFillingGap = numBytesForFillingGap + filledHolePart(2) - filledHolePart(1) + 1;
                        continue;
                    end
                    obj.MissingSegmentsInfo(offset, 1) = segmentEnd + 1;
                    obj.MissingSegmentsInfo(offset, 2) = hole(2);
                end
                % Calculate the number of bytes used for filling this hole
                numBytesForFillingGap = numBytesForFillingGap + filledHolePart(2) - filledHolePart(1) + 1;
            end
        end
    end
end
