function macSubPDU = macSubPDU(lcid, payload, linkDir)
%macSubPDU Generates NR MAC subPDU
%
%
%   MACSUBPDU = macSubPDU(LCID, PAYLOAD, LINKDIR) generates a medium
%   access control (MAC) sub protocol data unit (PDU) , as per 3GPP TS
%   38.321 Section 6.1.2.
%
%   LCID is the logical channel id (LCID).
%       - LCID values from 1 to 32 represents LCIDs of different logical
%         channels (in uplink and downlink).
%       - LCID = 59 represents short truncated BSR (only uplink).
%       - LCID = 60 represents long truncated BSR (only uplink).
%       - LCID = 61 represents short BSR (only uplink).
%       - LCID = 62 represents long BSR (only uplink).
%
%   PAYLOAD can be a MAC service data unit (SDU) or MAC control element and
%   it is a column vector of octets in decimal format.
%
%   LINKDIR represents the transmission direction (uplink/downlink) of MAC
%   protocol data unit (PDU).
%   LINKDIR = 0 represents downlink and
%   LINKDIR = 1 represents uplink.
%
%   MACSUBPDU is the generated MAC subPDU represented as column vector of
%   octets in decimal format.

%   Copyright 2019 The MathWorks, Inc.

    % Validate the inputs
    validateInputs(lcid, payload, linkDir);

    % Determine the payload length
    payloadLength = numel(payload);
    if linkDir
        % Determining the uplink subPDU header
        headerLength = getULHeaderLength(lcid, payloadLength);
    else
        % Determining the downlink subPDU header
        headerLength = getDLHeaderLength(lcid, payloadLength);
    end

    switch headerLength % Construct header
        case 1
            % R/LCID MAC subheader
            % R1    - Value 0 (1 bit)
            % R2    - Value 0 (1 bit)
            % LCID  - (6 bits)
            header = lcid;
        case 2
            % R/F/LCID/L MAC subheader with 1-byte L field
            % R     - Value 0 (1 bit)
            % F     - Value 0 (1 bit)
            % LCID  - (6 bits)
            header = [lcid ; payloadLength];
        case 3
            % R/F/LCID/L MAC subheader with 2-byte L field
            % R     - Value 0 (1 bit)
            % F     - Value 1 (1 bit)
            % LCID  - (6 bits)
            F = 1;
            header = [bitor(bitshift(F, 6), lcid );  ...
                bitshift(payloadLength, -8); ...
                bitand(payloadLength, 255)] ;
    end

    % Concatenate header and payload
    macSubPDU = [header; payload];
end

function validateInputs(lcid, payload, linkDir)
% Validates the given input arguments

    % LCID is within the valid range
    validateattributes(lcid,{'numeric'},{'nonempty','scalar','>=', 0,'<=',63,'integer'},'lcid');

    % payload must be nonempty, vector of octets in decimal format
    validateattributes(payload,{'numeric'},{'nonempty','vector','>=',0,'<=',255,'integer'},'payload');

    % linkDir must be either 0 or 1
    validateattributes(linkDir,{'numeric'},{'nonempty','scalar','>=',0,'<=', 1},'linkDir');
end

function headerLength = getULHeaderLength(lcid, payloadLength)
% Returns the header length of the uplink MAC subPDU

    % Header is decided based on lcid and payload length
    if lcid == 59 || lcid == 61 % Short truncated BSR or short BSR
        headerLength = 1;
    elseif (lcid >= 1 && lcid <= 32) || lcid == 60 || lcid == 62
        % MAC SDUs and variable size control elements from different logical
        % channels
        if payloadLength <= 255 % In bytes
            % R/F/LCID/L MAC subheader with 1-byte L field
            headerLength = 2;
        elseif payloadLength <= 65535
            % R/F/LCID/L MAC subheader with 2-byte L field
            headerLength = 3;
        else
            error('MATLAB:InvalidPayloadLength', 'Invalid payload length.');
        end
    else
        error('MATLAB:LCIDNotSupported', 'LCID ( %d ) is not supported.', lcid);
    end
end

function headerLength = getDLHeaderLength(lcid, payloadLength)
% Returns the header length of the downlink MAC subPDU

    % Header length will be decided based on lcid and payload length
    if lcid >= 1 && lcid <= 32
        % MAC SDUs from different logical channels
        if payloadLength <= 255 % In bytes
            % R/F/LCID/L MAC subheader with 1-byte L field
            headerLength = 2;
        elseif payloadLength <= 65535
            % R/F/LCID/L MAC subheader with 2-byte L field
            headerLength = 3;
        else
            error('MATLAB:InvalidPayloadLength', 'Invalid payload length.');
        end
    else
        error('MATLAB:LCIDNotSupported', 'LCID ( %d ) is not supported.', lcid);
    end
end