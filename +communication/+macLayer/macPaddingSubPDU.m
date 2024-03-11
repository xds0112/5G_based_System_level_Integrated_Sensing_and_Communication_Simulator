function macPaddingSubPDU = macPaddingSubPDU(subPDULength) %#codegen
%macPaddingSubPDU Generates NR MAC padding subPDU
%
%
%   MACPADDINGSUBPDU = macPaddingSubPDU(SUBPDULENGTH) generates a medium
%   access control (MAC) sub protocol data unit (PDU) with padding,
%   with given subPDU length, SUBPDULENGTH.
%
%   SUBPDULENGTH is the required MAC subPDU size in bytes.
%
%   MACPADDINGSUBPDU is the generated MAC subPDU represented as column
%   vector of octets in decimal format.

%   Copyright 2019 The MathWorks, Inc.

    % Input must be nonempty, scalar and value must be finite positive
    % integer greater than 1
    validateattributes(subPDULength, {'numeric'},{'nonempty','scalar','>=',1,'finite','integer'},'subPDULength');

    paddingLCID = 63; % Logical channel id (LCID) for padding
    % R/LCID MAC subheader
    % R1    - Value 0 (1 bit)
    % R2    - Value 0 (1 bit)
    % LCID  - (6 bits)
    header = paddingLCID;
    payload = zeros(subPDULength - 1, 1);
    macPaddingSubPDU = [header; payload];
end
