classdef cdl
    %CDL CDL channel models
    %   
    
    properties
        % CDL delay profile
        % specified as 'CDL-A', 'CDL-B', 'CDL-C', (NLoS)
        % 'CDL-D', 'CDL-E' (LoS)
        delayProfile

        % attached base station
        attachedBS

        % attached UEs
        attachedUEs
    end

    properties (Dependent = true)
        % parameters of attached bs
        bsParameters

        % parameters of attached UEs
        ueParameters

        % the uplink channel model
        channelModelUL 

        % the downlink channel model
        channelModelDL
    end
    
    methods
        function obj = cdl()
            %CDL
            % createCDL channel model
        end

        function ueParams = get.ueParameters(obj)
            % get parameters of attached UEs
            ueParams = obj.attachedUEs;
        end

        function bsParams = get.bsParameters(obj)
            % get parameters of attached base station
            bsParams = obj.attachedBS;
        end

        function channelModelDL = get.channelModelDL(obj)

            % Configure the downlink channel model
            ueParams       = obj.ueParameters;
            bsParams       = obj.bsParameters;
            channelModelDL = cell(1, ueParams.numUEs);
            waveformInfo   = nrOFDMInfo(bsParams.numRBs, bsParams.scs);

            for ueIdx = 1:ueParams.numUEs
                channel = nrCDLChannel;
                channel.DelayProfile              = obj.delayProfile;
                channel.DelaySpread               = 300e-9;
                channel.CarrierFrequency          = bsParams.dlCarrierFreq;
                channel.TransmitAntennaArray.Size = bsParams.txAntenna.arrayGeometry;
                channel.ReceiveAntennaArray.Size  = ueParams.ueAntenna;
                channel.SampleRate                = waveformInfo.SampleRate;
                channelModelDL{ueIdx}             = channel;
            end

        end

        function channelModelUL = get.channelModelUL(obj)

            % Configure the uplink channel model
            ueParams       = obj.ueParameters;
            bsParams       = obj.bsParameters;
            channelModelUL = cell(1, ueParams.numUEs);
            waveformInfo   = nrOFDMInfo(bsParams.numRBs, bsParams.scs);

            for ueIdx = 1:ueParams.numUEs
                channel = nrCDLChannel;
                channel.DelayProfile              = obj.delayProfile;
                channel.DelaySpread               = 300e-9;
                channel.CarrierFrequency          = bsParams.ulCarrierFreq;
                channel.TransmitAntennaArray.Size = ueParams.ueAntenna;
                channel.ReceiveAntennaArray.Size  = bsParams.rxAntenna.arrayGeometry;
                channel.SampleRate                = waveformInfo.SampleRate;
                channelModelUL{ueIdx}             = channel;
            end

        end

    end
end

