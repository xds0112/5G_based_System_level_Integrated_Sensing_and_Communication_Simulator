function [lcidList, payloadList] = macPDUParser(macPDU, linkDir)
%macPDUParser Parses the NR MAC PDU.
%
%   [LCIDLIST, PAYLOADLIST] = hNRMACPDUParser(MACPDU, LINKDIR) parses the
%   NR medium access control (MAC) protocol data unit (PDU) and returns the
%   subPDUs payloads and logical channel ids (LCIDs).
%
%   MACPDU is a column vector of octets in decimal format.
%
%   LINKDIR represents the transmission direction (uplink/downlink) of MAC PDU.
%   LINKDIR = 0 represents downlink and
%   LINKDIR = 1 represents uplink.
%
%   LCIDLIST is an array of LCIDs of subPDUs.
%
%   PAYLOADLIST is a cell array of MAC SDUs or MAC control elements
%   contained in the MAC PDU.

%   Copyright 2019-2020 The MathWorks, Inc.

    % Validate the inputs
    validateInputs(macPDU, linkDir);

    % MAC PDU length
    numBytes = length(macPDU);
    macPDU = double(macPDU);
    subPDUStartIndex = 1; % Starting byte index of a subPDU

    % Initialize the arrays To support codegen
    maxSubPDUs = floor(numBytes/2); % Maximum packets possible
    lcidList = zeros(maxSubPDUs,1);
    payloads = repmat({0},maxSubPDUs,1);
    numSubPDUs = 0;

    % Read the subPDUs from MAC PDU
    if linkDir
        % For uplink
        getMACSubPDUInfo = @getULMACSubPDU;
    else
        % For downlink
        getMACSubPDUInfo = @getDLMACSubPDU;
    end

    while subPDUStartIndex <= numBytes
        % Determine the information of the subPDU starting at a particular byte index in the MAC PDU
        [lcid, subPDUPayload, subPDULength] = getMACSubPDUInfo(macPDU, subPDUStartIndex);
        subPDUStartIndex = subPDUStartIndex + subPDULength;
        if lcid ~= 63 % if not padding
            numSubPDUs = numSubPDUs + 1;
            lcidList(numSubPDUs,1) = lcid;
            payloads{numSubPDUs,1} = subPDUPayload;
        else
            % Break when padding is detected
            break;
        end
    end
    % Trim the unfilled portion of the output array
    lcidList = lcidList(1:numSubPDUs);
    payloadList = cell(numSubPDUs,1); % To support codegen
    for j = 1:numSubPDUs
        payloadList{j} = payloads{j,1};
    end

end

function validateInputs(macPDU, linkDir)
% Validates the given input arguments

    % MAC PDU must be nonempty, vector of octets in decimal format
    validateattributes(macPDU,{'numeric'},{'nonempty','vector','>=',0,'<=',255,'integer'},'macPDU');

    % linkDir must be either 0 or 1
    validateattributes(linkDir,{'numeric'},{'nonempty','scalar','binary'},'linkDir');

end

function [lcid, subPDUPayload, subPDULength] = getULMACSubPDU(macPDU, byteIndex)
% Determines the information of the subPDU, given its starting byte index in the uplink MAC PDU

    % LCID values from 1 to 32 represents LCIDs of different logical
    % channels.
    % LCID = 59 represents short truncated BSR.
    % LCID = 60 represents long truncated BSR.
    % LCID = 61 represents short BSR.
    % LCID = 62 represents long BSR.
    % LCID = 63 represents padding.

    firstByte = macPDU(byteIndex);
    lcid = bitand(firstByte, bitshift(255, -2)); % Read LCID from bits 3:8 of the first byte

    if lcid == 63 % Padding
        subPDULength = 1;
        subPDUPayload = [];
    else
        if lcid == 59 || lcid == 61 % Short truncated BSR or short BSR
            % R/LCID MAC subheader
            headerLength = 1;
            payloadLength = 1;
        elseif (lcid >= 1 && lcid <= 32) || (lcid == 60 || lcid == 62) % Supports subPDUs with LCIDs from 1 to 32, long truncated BSR and long BSR
            % MAC SDUs and variable size control elements from different logical channels
            % R/F/LCID/L MAC subheader with 1-byte or 2-byte L field
            F = bitand(bitshift(firstByte, -6), 1); % Get 2nd bit of first byte
            if F == 0
                % R/F/LCID/L MAC subheader with 1-byte L field
                % Length of the payload
                payloadLength = macPDU(byteIndex + 1);
                headerLength = 2;
            else
                % R/F/LCID/L MAC subheader with 2-byte L field
                % Read length of the payload from 2nd and 3rd byte
                payloadLength = bitshift(macPDU(byteIndex + 1), 8) +  macPDU(byteIndex + 2);
                headerLength = 3;
            end
        else
            error('MATLAB:LCIDNotSupported', 'LCID ( %d ) is not supported.', lcid);
        end
        subPDULength = headerLength + payloadLength;
        subPDUPayload = macPDU(byteIndex + headerLength : byteIndex + subPDULength - 1);
    end
end

function [lcid, subPDUPayload, subPDULength] = getDLMACSubPDU(macPDU, byteIndex)
% Determines the information of the subPDU, given its starting byte index in the downlink MAC PDU

    % LCID values from 1 to 32 represents LCIDs of different logical
    % channels.
    % LCID = 63 represents padding.

    firstByte = macPDU(byteIndex);
    lcid = bitand(firstByte, bitshift(255, -2)); % Read LCID from bits 3:8 of the first byte

    if lcid == 63 % Padding
        subPDULength = 1;
        subPDUPayload = [];
    elseif lcid >= 1 && lcid <= 32 % Supports subPDUs with LCIDs in between 1 and 32
        % MAC SDUs from different logical channels
        % R/F/LCID/L MAC subheader with 1-byte or 2-byte L field
        F = bitand(bitshift(firstByte, -6), 1); % Get 2nd bit of first byte
        if F == 0
            % R/F/LCID/L MAC subheader with 1-byte L field
            % Length of the payload
            payloadLength = macPDU(byteIndex + 1);
            headerLength = 2;
        else
            % R/F/LCID/L MAC subheader with 2-byte L field
            % Read length of the payload from 2nd and 3rd byte
            payloadLength = bitshift(macPDU(byteIndex + 1), 8) +  macPDU(byteIndex + 2);
            headerLength = 3;
        end
        subPDULength = headerLength + payloadLength;
        subPDUPayload = macPDU(byteIndex + headerLength : byteIndex + subPDULength - 1);
    else
        error('MATLAB:LCIDNotSupported', 'LCID ( %d ) is not supported.', lcid);
    end
end