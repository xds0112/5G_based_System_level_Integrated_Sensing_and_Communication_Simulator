function macPDU = macMultiplex(subPDUList, ceSubPDUList, paddingSubPDU, linkDir) %#codegen
%macMultiplex Generates an NR MAC PDU from subPDUs
%
%   Note: This is a helper function for an example.
%
%   MACPDU = macMultiplex(SUBPDULIST, CESUBPDULIST,
%   PADDINGSUBPDU, LINKDIR) generates a downlink/uplink medium access
%   control (MAC) protocol data unit (PDU) by multiplex the subPDUs in
%   the order as defined by 3GPP TS 38.321 Figure 6.1.2-4 and Figure
%   6.1.2-5.
%
%   SUBPDULIST is the list of subPDUs containing service data units (SDUs)
%   from radio link control (RLC) layer. It is a cell array of subPDUs and each
%   subPDU is represented as vector of octets in decimal format.
%
%   CESUBPDULIST is the list of subPDUs containing different control
%   elements. It is a cell array of subPDUs and each subPDU is represented
%   as a column vector of octets in decimal format.
%
%   PADDINGSUBPDU is a padding MAC subPDU and represented as vector of
%   octets in decimal format. It is empty, in case no padding is required.
%
%   LINKDIR represents the transmission direction (uplink/downlink), for
%   which MAC PDU is constructed.
%   LINKDIR = 0 represents downlink and
%   LINKDIR = 1 represents uplink.
%
%   MACPDU is the generated MAC PDU represented as a column vector of octets
%   in decimal format.

%   Copyright 2019 The MathWorks, Inc.

    if linkDir
        % Uplink MAC PDU constructed as per 3GPP TS 38.321 Figure 6.1.2-5
        macPDU = [vertcat(subPDUList{:}); vertcat(ceSubPDUList{:}); paddingSubPDU];
    else
        % Downlink MAC PDU constructed as per 3GPP TS 38.321 Figure 6.1.2-4
        macPDU = [vertcat(ceSubPDUList{:}); vertcat(subPDUList{:}); paddingSubPDU];
    end
end
