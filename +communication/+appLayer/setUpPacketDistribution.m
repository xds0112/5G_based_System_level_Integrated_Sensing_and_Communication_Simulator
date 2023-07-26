function setUpPacketDistribution(simParameters, gNB, UEs, pktObj)
% Setup the UL and DL packet distribution mechanism

%   Copyright 2020-2021 The MathWorks, Inc.

nodeInfo = struct('CarrierFreq',[],'NCellID',[], 'RNTI',[]);
% Configure Tx-Rx interface to exchange packets between UEs and gNB
% Register UEs for transmissions and receptions
    nodeInfo.CarrierFreq = simParameters.dlCarrierFreq;
    nodeInfo.NCellID = simParameters.cellID;
    for ueIdx=1:length(UEs)
        nodeInfo.RNTI = ueIdx;
        uePhyObj = UEs{ueIdx}.PhyEntity;
        ueMACObj = UEs{ueIdx}.MACEntity;
        registerRxFcn(pktObj, nodeInfo, @uePhyObj.storeReception, @ueMACObj.controlRx);
        registerInBandTxFcn(uePhyObj, @pktObj.sendInBandPackets);
        registerOutofBandTxFcn(ueMACObj, @pktObj.sendOutofBandPackets);
    end
    nodeInfo.CarrierFreq = simParameters.ulCarrierFreq;
    nodeInfo.RNTI = [];
    % Register gNB for transmissions and receptions
    gNBPhyObj = gNB.PhyEntity;
    gNBMACObj = gNB.MACEntity;
    registerRxFcn(pktObj, nodeInfo, @gNBPhyObj.storeReception, @gNBMACObj.controlRx);
    registerInBandTxFcn(gNBPhyObj, @pktObj.sendInBandPackets);
    registerOutofBandTxFcn(gNBMACObj, @pktObj.sendOutofBandPackets);
end