classdef  packetDistribution < handle
    %packetDistribution Distributes the packets among the nodes
    % This class implements the functionality to distribute the packets
    % among the nodes. It mimics the distributed nature of channel for
    % packet receptions. It also provides out-of-band packet exchange
    % between MAC layer of sender and receiver.

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %ReceiverInfo Information about the receivers
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. Each element is a structure with three fields
        %   CarrierFreq    - Carrier frequency of the receiver
        %   NCellID        - Cell identifier
        %   RNTI           - Radio network temporary identifier
        ReceiverInfo

        %ReceiverPhyFcn Phy reception function handles of the receivers
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. For each receiver, it holds the Phy
        % reception function handle for exchange of in-band information
        % exchange
        ReceiverPhyFcn

        %ReceiverMACFcn MAC reception function handles of the receivers 
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. For each receiver, it holds the MAC
        % reception function handle for out-of-band information exchange
        ReceiverMACFcn
    end

    methods(Access = public)
        function obj = packetDistribution(simParam)
            %packetDistribution Construct an instance of this class
            %
            % SIMPARAM is a structure with following fields
            %    MaxReceivers - Maximum number of nodes that can be 
            %                   registered for reception
            
            obj.ReceiverPhyFcn = cell(simParam.maxReceivers, 1);
            obj.ReceiverMACFcn = cell(simParam.maxReceivers, 1);
            obj.ReceiverInfo   = cell(simParam.maxReceivers, 1);
        end

        function sendInBandPackets(obj, packetInfo)
            %sendWaveform Transmits the packet to all the receivers operating on
            % the same frequency band as transmitter
            %
            % PACKETINFO is the information about the transmitted packet.
            % Based on Phy type packetInfo has two formats.
            %
            % Format - 1 (waveform IQ samples): It is a structure with
            % following fields
            % 
            %     Waveform    - IQ samples of the waveform
            %     SampleRate  - Sample rate of the waveform
            %     CarrierFreq - Carrier frequency (in Hz)
            %     TxPower     - Tx power (in dBm)
            %     Position    - Position of the transmitting node
            %
            % Format - 2 (Unencoded packet): It is a structure with
            % following fields
            %
            %     Packet        - Column vector of octets in decimal format
            %     CarrierFreq   - Carrier frequency (in Hz)
            %     TxPower       - Tx power (in dBm)
            %     Position      - Position of the transmitting node
            %     NCellID       - Cell identifier
            %     RNTI          - Radio network temporary identifier
            
            % Send the waveform to all the receivers operating on same
            % frequency, based on carrier frequency of each receiver
            for idx = 1:length(obj.ReceiverPhyFcn)
                if ~isempty(obj.ReceiverInfo{idx})
                    if obj.ReceiverInfo{idx}.CarrierFreq == packetInfo.CarrierFreq
                        obj.ReceiverPhyFcn{idx}(packetInfo);
                    end
                end
            end
        end

        function sendOutofBandPackets(obj, packetInfo)
            %sendOutofBandPackets Transmits the packet to the receiver
            %
            % PACKETINFO is the information about transmitted packet.
            % It is a structure with following fields
            %   Packet        - Column vector of octets in decimal format
            %   PacketType    - Packet type
            %   NCellID       - Cell identifier
            %   RNTI          - Radio network temporary identifier

            % Send the packet to the receiver based on information in packetInfo
            for idx = 1:length(obj.ReceiverMACFcn)
                if ~isempty(obj.ReceiverInfo{idx})
                    if obj.ReceiverInfo{idx}.NCellID == packetInfo.NCellID
                        obj.ReceiverMACFcn{idx}(packetInfo);
                    end
                end
            end
        end

        function registerRxFcn(obj, receiverInfo, phyReceiverFcn, macReceiverFcn)
            %registerRxFcn Add the given function handle to the
            %list of receivers function handles list
            %
            % RECEIVERINFO is the information about receiver. It is a structure
            % with following fields
            %  CarrierFreq     - Represents carrier frequency of the
            %                    receiver
            %  NCellID         - Cell identifier
            %  RNTI            - Radio network temporary identifier
            %
            % PHYRECEIVERFCN   - Function handle provided by receiver to write
            %                    packets into its Phy reception buffer
            %
            % MACRECEIVERFCN   - Function handle provided by receiver to write
            %                    packets into its MAC reception buffer

            idx = find(cellfun(@isempty, obj.ReceiverInfo), 1);
            obj.ReceiverInfo{idx}   = receiverInfo;
            obj.ReceiverPhyFcn{idx} = phyReceiverFcn;
            obj.ReceiverMACFcn{idx} = macReceiverFcn;
        end
    end
end