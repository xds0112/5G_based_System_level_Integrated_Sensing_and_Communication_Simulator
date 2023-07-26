classdef rlcBufferStatus < handle
%hNRRLCBufferStatus Create a logical channel buffer status report object
%   BUFFERSTATUS = hNRRLCBufferStatus(RNTI, LCID, BUFFERSIZE) creates a
%   logical channel buffer status report object. RLC sends this to MAC for
%   informing the logical channel buffer status.
%
%   hNRRLCBufferStatus properties:
%   RNTI                    - UE's radio network temporary identifier
%   LogicalChannelID        - Logical channel identifier
%   BufferStatus            - Number of bytes required to send the service
%                             data units (SDUs) in the logical channel's Tx
%                             buffer

% Copyright 2019 The MathWorks, Inc.

%#codegen

    properties
        % RNTI Radio network temporary identifier of a UE
        %   Specify the RNTI as an integer scalar within [1 65519]. Refer
        %   table 7.1-1 in 3GPP TS 38.321. The default value is 1.
        RNTI (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(RNTI, 1), mustBeLessThanOrEqual(RNTI, 65519)} = 1;
        % LogicalChannelID Logical channel identifier
        %   Specify the logical channel identifier as an integer scalar
        %   between 1 and 32, inclusive. Refer table 6.2.1-1 in 3GPP TS
        %   38.321. The default value is 1.
        LogicalChannelID (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(LogicalChannelID, 1), mustBeLessThanOrEqual(LogicalChannelID, 32)} = 1;
        % BufferStatus Logical channel's buffer status (bytes)
        %   Specify the buffer status of a logical channel as an integer
        %   scalar in bytes. The default value is 0.
        BufferStatus (1, 1) {mustBeInteger, mustBeFinite} = 0;
    end

    methods
        function obj = rlcBufferStatus(rnti, lcid, bufferStatus)
            %rlcBufferStatus Construct the logical channel's buffer
            % status report object
            %   OBJ = hNRRLCBufferStatus(RNTI, LCID, BUFFERSTATUS)
            %   initializes the logical channel's buffer status report
            %   object.
            %
            %   RNTI is a radio network temporary identifier, specified
            %   within [1, 65519]. Refer table 7.1-1 in 3GPP TS 38.321.
            %
            %   LCID is a logical channel identifier, specified in the
            %   range between 1 and 32, inclusive. Refer Table 6.2.1-1 in
            %   3GPP TS 38.321.
            %
            %   BUFFERSTATUS is the amount of data (in bytes) in the
            %   logical channel's Tx buffer.

            obj.RNTI = rnti;
            obj.LogicalChannelID = lcid;
            obj.BufferStatus = bufferStatus;
        end
    end
end
