classdef (Abstract) rlcEntity < handle
%hNRRLCEntity RLC entity class containing properties and components common
% for AM entity and UM entity

% Copyright 2020-2021 The MathWorks, Inc.

    properties (Access = public)
        % StatTxDataPDU Number of data PDUs sent by RLC to MAC layer
        StatTxDataPDU = 0;
        % StatTxDataBytes Number of data bytes sent by RLC to MAC layer
        StatTxDataBytes = 0;
        % StatReTxDataPDU Number of data PDUs retransmitted by RLC to MAC
        % layer
        StatReTxDataPDU = 0;
        % StatReTxDataBytes Number of data bytes retransmitted by RLC to
        % MAC layer
        StatReTxDataBytes = 0;
        % StatTxControlPDU Number of control PDUs sent by RLC from MAC
        StatTxControlPDU = 0;
        % StatTxControlBytes Number of control bytes sent by RLC from MAC
        StatTxControlBytes = 0;
        % StatTxPacketsDropped Number of packets dropped by RLC layer due
        % to Tx buffer overflow
        StatTxPacketsDropped = 0;
        % StatTxBytesDropped Number of bytes dropped by RLC layer due to
        % Tx buffer overflow
        StatTxBytesDropped = 0;
        % StatTimerPollRetransmitTimedOut Number of times the poll
        % retransmit timer has timed-out
        StatTimerPollRetransmitTimedOut = 0;
        % StatRxDataPDU Number of RLC data PDUs received by RLC from MAC
        StatRxDataPDU = 0;
        % StatRxDataBytes Number of RLC data bytes received by RLC from MAC
        StatRxDataBytes = 0;
        % StatRxDataPDUDropped Number of RLC data PDUs dropped by RLC
        StatRxDataPDUDropped = 0;
        % StatRxDataBytesDropped Number of RLC data bytes dropped by RLC
        StatRxDataBytesDropped = 0;
        % StatRxDataPDUDuplicate Number of duplicate data PDUs received by
        % RLC from MAC
        StatRxDataPDUDuplicate = 0;
        % StatRxDataBytesDuplicate Number of duplicate data bytes received
        % by RLC from MAC
        StatRxDataBytesDuplicate = 0;
        % StatRxControlPDU Number of control PDUs received by RLC from MAC
        StatRxControlPDU = 0;
        % StatRxControlBytes Number of control bytes received by RLC from
        % MAC
        StatRxControlBytes = 0;
        % StatTimerReassemblyTimedOut Number of times the reassembly timer
        % has timed-out
        StatTimerReassemblyTimedOut = 0;
        % StatTimerStatusProhibitTimedOut Number of times the status
        % prohibit timer has timed-out
        StatTimerStatusProhibitTimedOut = 0;
        % TxBufferStatusFcn Function handle to send the RLC buffer status
        % to the associated MAC entity
        TxBufferStatusFcn
        % RxForwardFcn Function handle to forward the received RLC SDUs to
        % the application layer
        RxForwardFcn
    end

    properties (Access = public, Constant, Hidden)
        % MinRequiredGrant Minimum required grant length for sending a RLC
        % PDU to MAC
        MinRequiredGrant = 8; % In bytes
        % MaxSDUSize Maximum possible RLC SDU size in bytes
        MaxSDUSize = 9000;
    end

    methods (Access = public)
        function registerMACInterfaceFcn(obj, txBufferStatusFcn)
            %registerMACInterfaceFcn Register MAC interface function to
            % report the buffer status of the RLC entity
            %   registerMACInterfaceFcn(obj, TXBUFFERSTATUSFCN) registers
            %   the MAC interface function TXBUFFERSTATUSFCN to report the
            %   buffer status of the RLC entity.
            %
            %   TXBUFFERSTATUSFCN Function handle to send the RLC buffer
            %   status report.

            obj.TxBufferStatusFcn = txBufferStatusFcn;
        end

        function registerAppReceiverFcn(obj, rxForwardFcn)
            %registerAppReceiverFcn Register application layer receiver
            % callback to forward the received RLC SDUs
            %   registerAppReceiverFcn(obj, RXFORWARDFCN) registers the
            %   application layer receiver callback RXFORWARDFCN to forward
            %   the received RLC SDU.
            %
            %   RXFORWARDFCN Function handle to forward the received RLC
            %   SDUs to the application layer.

            obj.RxForwardFcn = rxForwardFcn;
        end

        function stats = getStatistics(obj)
            %getStatistics Return the cumulative RLC statistics
            %
            %   STATS = getStatistics(OBJ) returns the cumulative
            %   statistics collected by the RLC entity
            %
            %   STATS is a column vector that holds the cumulative RLC
            %   statistics

            stats = [obj.StatTxDataPDU; obj.StatTxDataBytes; obj.StatReTxDataPDU; ...
                obj.StatReTxDataBytes; obj.StatTxControlPDU; ...
                obj.StatTxControlBytes; obj.StatTxPacketsDropped; ...
                obj.StatTxBytesDropped; obj.StatTimerPollRetransmitTimedOut; obj.StatRxDataPDU; ...
                obj.StatRxDataBytes; obj.StatRxDataPDUDropped; obj.StatRxDataBytesDropped; ...
                obj.StatRxDataPDUDuplicate; obj.StatRxDataBytesDuplicate; ...
                obj.StatRxControlPDU; obj.StatRxControlBytes; ...
                obj.StatTimerReassemblyTimedOut; obj.StatTimerStatusProhibitTimedOut];
        end
    end
end
