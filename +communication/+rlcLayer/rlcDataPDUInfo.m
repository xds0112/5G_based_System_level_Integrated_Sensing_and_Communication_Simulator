classdef rlcDataPDUInfo < handle
%rlcDataPDUInfo Create an RLC data PDU information object
%   RLCPDUINFO = hNRRLCDataPDUInfo() creates a radio link control (RLC)
%   unacknowledged mode (UM) or acknowledged mode (AM) protocol data unit
%   (PDU) information object.
%
%   rlcDataPDUInfo properties:
%
%   Data                - Payload of the data PDU
%   PDULength           - Length of the RLC PDU
%   PollBit             - Flag that indicates whether status report is
%                         requested by the transmitter. This property is
%                         only valid for RLC AM data PDU
%   SegmentationInfo    - Segmentation information of the SDU
%   SequenceNumber      - Sequence number (SN) assigned for the SDU. This
%                         is always 0 for complete SDUs in RLC UM
%   SegmentOffset       - Start position of the segmented SDU in bytes
%                         within the original SDU

% Copyright 2020 The MathWorks, Inc.

%#codegen

    properties (Access = public)
        % Data Payload of the RLC PDU
        %   Specify the data as a column vector of octets in decimal
        %   format.
        Data (:, 1)
        % PDULength Length of the RLC PDU
        %   Specify the PDU length as a positive integer scalar.
        PDULength (:, 1)
        % PollBit Flag that indicates whether status report is requested by
        % the transmitter. This property is only valid for RLC AM data PDU
        %   Specify the poll bit as a boolean value. For more details,
        %   refer 3GPP TS 38.322 Section 6.2.3.7.
        PollBit (1, 1)
        % SegmentationInfo Segmentation information of the SDU
        %   Specify the segmentation information as an integer scalar
        %   between 0 and 3. For more details, refer 3GPP TS 38.322 Section
        %   6.2.3.4.
        SegmentationInfo (1, 1)
        % SequenceNumber Sequence number (SN) assigned for the SDU. This is
        % always 0 for complete SDUs in RLC UM
        %   Specify the sequence number as an integer scalar between 0 to
        %   2^(configured SN field length)-1. For more details, refer
        %   3GPP TS 38.322 Section 6.2.3.3.
        SequenceNumber (1, 1)
        % SegmentOffset Start position of the segmented SDU in bytes within
        % the original SDU
        %   Specify the segment offset as an integer scalar in the range
        %   0 to 2^16-1. For more details, refer 3GPP TS 38.322 Section
        %   6.2.3.5.
        SegmentOffset (1, 1)
    end
end