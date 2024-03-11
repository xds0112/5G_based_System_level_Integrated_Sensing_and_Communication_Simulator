classdef proportionalFair < communication.scheduling.schedulerEntity
    %proportionalFair Implements proportional fair scheduler

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        % MovingAvgDataRateWeight Moving average parameter to calculate the average data rate
        MovingAvgDataRateWeight (1, 1) {mustBeNumeric, mustBeNonempty,...
                     mustBeGreaterThanOrEqual(MovingAvgDataRateWeight, 0),...
                     mustBeLessThanOrEqual(MovingAvgDataRateWeight, 1)} = 0.5;

        % UEsServedDataRate Stores DL and UL served data rate for each UE 
        % N-by-2 matrix where 'N' is the number of UEs. For each UE, gNB
        % maintains a context which is used in taking scheduling decisions.
        % There is one row for each UE, indexed by their respective RNTI
        % values. Each row has two columns with following information:
        % Served data rate in DL and served data rate in UL direction.
        % Served data rate is the average data rate achieved by UE till now
        % and serves as an important parameter for doing proportional fair
        % scheduling
        UEsServedDataRate
    end

    methods
        function obj = proportionalFair(simParameters)
            %proportionalFair Construct an instance of this class

            % Invoke the super class constructor to initialize the properties
            obj = obj@communication.scheduling.schedulerEntity(simParameters);

            % Moving average parameter to calculate the average data rate
            if isfield(simParameters, 'MovingAvgDataRateWeight')
                obj.MovingAvgDataRateWeight = simParameters.MovingAvgDataRateWeight;
            end

            obj.UEsServedDataRate = ones(length(obj.UEs), 2);
        end

        function [selectedUE, mcsIndex] = runSchedulingStrategy(obj, schedulerInput)
            %runSchedulingStrategy Implements the proportional fair scheduling
            %
            %   [SELECTEDUE, MCSINDEX] = runSchedulingStrategy(OBJ, SCHEDULERINPUT) runs
            %   the proportional fair algorithm and returns the UE (among the eligible
            %   ones) which wins this particular resource block group, along with the
            %   suitable MCS index based on the channel conditions. This function gets
            %   called for selecting a UE for each RBG to be used for new transmission
            %   i.e. once for each of the remaining RBGs after assignment for
            %   retransmissions is completed. According to PF scheduling
            %   strategy, the UE which has maximum value for the PF weightage, i.e. the
            %   ratio: (RBG-Achievable-Data-Rate/Historical-data-rate), gets the RBG.
            %
            %   SCHEDULERINPUT structure contains the following fields which scheduler
            %   would use (not necessarily all the information) for selecting the UE to
            %   which RBG would be assigned.
            %
            %       eligibleUEs    - RNTI of the eligible UEs contending for the RBG
            %       selectedRank   - Selected rank for UEs. It is an array of size eligibleUEs
            %       RBGIndex       - RBG index in the slot which is getting scheduled
            %       slotNum        - Slot number in the frame whose RBG is getting scheduled
            %       RBGSize        - RBG Size in terms of number of RBs
            %       cqiRBG         - Uplink Channel quality on RBG for UEs. This is a
            %                        N-by-P  matrix with uplink CQI values for UEs on
            %                        different RBs of RBG. 'N' is the number of eligible
            %                        UEs and 'P' is the RBG size in RBs
            %       mcsRBG         - MCS for eligible UEs based on the CQI values of the RBs
            %                        of RBG. This is a N-by-2 matrix where 'N' is number of
            %                        eligible UEs. For each eligible UE it contains, MCS
            %                        index (first column) and efficiency (bits/symbol
            %                        considering both Modulation and Coding scheme)
            %       pastDataRate   - Served data rate. Vector of N elements containing
            %                        historical served data rate to eligible UEs. 'N' is
            %                        the number of eligible UEs
            %       bufferStatus   - Buffer-Status of UEs. Vector of N elements where 'N'
            %                        is the number of eligible UEs, containing pending
            %                        buffer status for UEs
            %       linkDir        - Link direction as 0 (DL) or 1 (UL)
            %       ttiDur         - TTI duration in ms
            %       UEs            - RNTI of all the UEs (even the non-eligible ones for
            %                        this RBG)
            %       lastSelectedUE - The RNTI of the UE which was assigned the last
            %                        scheduled RBG
            %
            %   SELECTEDUE The UE (among the eligible ones) which gets assigned
            %   this particular resource block group
            %
            %   MCSINDEX The suitable MCS index based on the channel conditions

            selectedUE = -1;
            maxPFWeightage = 0;
            mcsIndex = -1;
            linkDir = schedulerInput.LinkDir;
            for i = 1:length(schedulerInput.eligibleUEs)
                bufferStatus = schedulerInput.bufferStatus(i);
                pastDataRate = obj.UEsServedDataRate(schedulerInput.eligibleUEs(i), linkDir+1);
                if(bufferStatus > 0) % Check if UE has any data pending
                    bitsPerSym = schedulerInput.mcsRBG(i, 2); % Accounting for both Modulation & Coding scheme
                    numLayers = schedulerInput.selectedRank(i);
                    achievableDataRate = ((numLayers* schedulerInput.RBGSize * bitsPerSym * 14 * 12)*1000)/ ...
                        (schedulerInput.ttiDur); % bits/sec
                    % Calculate UE weightage as per PF strategy
                    pfWeightage = achievableDataRate/pastDataRate;
                    if(pfWeightage > maxPFWeightage)
                        % Update the UE with maximum weightage
                        maxPFWeightage = pfWeightage;
                        selectedUE = schedulerInput.eligibleUEs(i);
                        mcsIndex = schedulerInput.mcsRBG(i, 1);
                    end
                end
            end

        end
    end
    methods(Access = protected)

        function uplinkGrants = scheduleULResourcesSlot(obj, slotNum)
            %scheduleULResourcesSlot Schedule UL resources of a slot
            % Uplink grants are returned as output to convey the way the
            % the uplink scheduler has distributed the resources to
            % different UEs. 'slotNum' is the slot number in the 10 ms
            % frame which is getting scheduled. The output 'uplnkGrants' is
            % a cell array where each cell-element represents an uplink
            % grant and has following fields:
            %
            % RNTI        Uplink grant is for this UE
            %
            % Type        Whether assignment is for new transmission ('newTx'),
            %             retransmission ('reTx')
            %
            % HARQId   Selected uplink UE HARQ process ID
            %
            % RBGAllocationBitmap  Frequency-domain resource assignment. A
            %                      bitmap of resource-block-groups of the PUSCH
            %                      bandwidth. Value 1 indicates RBG is assigned
            %                      to the UE
            %
            % StartSymbol  Start symbol of time-domain resources. Assumed to be
            %              0 as time-domain assignment granularity is kept as
            %              full slot
            %
            % NumSymbols   Number of symbols allotted in time-domain
            %
            % SlotOffset   Slot-offset of PUSCH assignments for upcoming slot
            %              w.r.t the current slot
            %
            % MCS          Selected modulation and coding scheme for UE with
            %              respect to the resource assignment done
            %
            % NDI          New data indicator flag
            %
            % DMRSLength   DM-RS length 
            %
            % MappingType  Mapping type
            %
            % NumLayers    Number of transmission layers
            %
            % NumAntennaPorts     Number of antenna ports
            %
            % TPMI                Transmitted precoding matrix indicator
            %
            % NumCDMGroupsWithoutData    Number of DM-RS code division multiplexing (CDM) groups without data
            

            % Calculate offset of the slot to be scheduled, from the current
            % slot
            if slotNum >= obj.CurrSlot
                slotOffset = slotNum - obj.CurrSlot;
                slotSFN = obj.SFN;
            else
                slotOffset = (obj.NumSlotsFrame + slotNum) - obj.CurrSlot;
                slotSFN = obj.SFN+1;
            end

            % Get start UL symbol and number of UL symbols in the slot
            if obj.DuplexMode == 1 % TDD
                DLULPatternIndex = mod(obj.CurrDLULSlotIndex + slotOffset, obj.NumDLULPatternSlots);
                slotFormat = obj.DLULSlotFormat(DLULPatternIndex + 1, :);
                firstULSym = find(slotFormat == obj.ULType, 1, 'first') - 1; % Index of first UL symbol in the slot
                lastULSym = find(slotFormat == obj.ULType, 1, 'last') - 1; % Index of last UL symbol in the slot
                numULSym = lastULSym - firstULSym + 1;
            else % FDD
                % All symbols are UL symbols
                firstULSym = 0;
                numULSym = 14;
            end
            
            % Check if the current slot has any reserved symbol for SRS
            for i=1:size(obj.ULReservedResource, 1) 
                numSlotFrames = 10*(obj.SCS/15); % Number of slots per 10ms frame
                reservedResourceInfo = obj.ULReservedResource(i, :);
                if (mod(numSlotFrames*slotSFN + slotNum - reservedResourceInfo(3), reservedResourceInfo(2)) == 0) % SRS slot check
                    reservedSymbol = reservedResourceInfo(1);
                    if (reservedSymbol >= firstULSym) && (reservedSymbol <= firstULSym+numULSym-1)
                        numULSym = reservedSymbol - firstULSym; % Allow PUSCH to only span till the symbol before the SRS symbol
                    end
                    break; % Only 1-symbol for SRS per slot
                end
            end
            
            if obj.SchedulingType == 0 % Slot based scheduling
                if(obj.PUSCHMappingType =='A' && (firstULSym~=0 || numULSym<4))
                    % PUSCH Mapping type A transmissions always start at symbol 0 and
                    % number of symbols must be >=4, as per TS 38.214 - Table 6.1.2.1-1
                    uplinkGrants = [];
                    return;
                end
                % Assignments to span all the symbols in the slot
                uplinkGrants = assignULResourceTTI(obj, slotNum, firstULSym, numULSym);
                % Update served data rate for the UEs as per the resource
                % assignments. This affects scheduling decisions for future
                % TTI
                updateUEServedDataRate(obj, obj.ULType, uplinkGrants);
            else % Symbol based scheduling
                numTTIs = floor(numULSym / obj.TTIGranularity); % UL TTIs in the slot

                % UL grant array with maximum size to store grants
                uplinkGrants = cell((ceil(14/obj.TTIGranularity) * length(obj.UEs)), 1);
                numULGrants = 0;

                % Schedule all UL TTIs in the slot one-by-one
                startSym = firstULSym;
                for i = 1 : numTTIs
                    TTIULGrants = assignULResourceTTI(obj, slotNum, startSym, obj.TTIGranularity);
                    uplinkGrants(numULGrants + 1 : numULGrants + length(TTIULGrants)) = TTIULGrants(:);
                    numULGrants = numULGrants + length(TTIULGrants);
                    startSym = startSym + obj.TTIGranularity;

                    % Update served data rate for the UEs as per the resource
                    % assignments. This affects scheduling decisions for future
                    % TTI
                    updateUEServedDataRate(obj, obj.ULType, TTIULGrants);
                end
                
                remULSym = mod(numULSym, obj.TTIGranularity); % Remaining unscheduled UL symbols
                % Schedule the remaining unscheduled UL symbols
                if remULSym >= 1 % Minimum PUSCH granularity is 1 symbol
                    TTIULGrants = assignULResourceTTI(obj, slotNum, startSym, remULSym);
                    uplinkGrants(numULGrants + 1 : numULGrants + length(TTIULGrants)) = TTIULGrants(:);
                    numULGrants = numULGrants + length(TTIULGrants);
                    % Update served data rate for the UEs as per the resource
                    % assignments. This affects scheduling decisions for future
                    % TTI
                    updateUEServedDataRate(obj, obj.ULType, TTIULGrants);
                end
                uplinkGrants = uplinkGrants(1 : numULGrants);
            end
        end
        
        function downlinkGrants = scheduleDLResourcesSlot(obj, slotNum)
            %scheduleDLResourcesSlot Schedule DL resources of a slot
            %   DOWNLINKGRANTS = scheduleDLResourcesSlot(OBJ, SLOTNUM)
            %   assigns DL resources of the slot, SLOTNUM. Based on the DL
            %   assignment done, it also updates the DL HARQ process
            %   context.
            %   
            %   SLOTNUM is the slot number in the 10 ms frame whose DL
            %   resources are getting scheduled. For FDD, all the symbols
            %   can be used for DL. For TDD, the DL resources can stretch
            %   the full slot or might just be limited to few symbols in
            %   the slot.
            %
            %   DOWNLINKGRANTS is a cell array where each cell-element
            %   represents a downlink grant and has following fields:
            %
            %       RNTI                Downlink grant is for this UE
            %
            %       Type                Whether assignment is for new transmission ('newTx'),
            %                           retransmission ('reTx')
            %
            %       HARQID              Selected downlink HARQ process ID
            %
            %       RBGAllocationBitmap Frequency-domain resource assignment. A
            %                           bitmap of resource-block-groups of
            %                           the PDSCH bandwidth. Value 1
            %                           indicates RBG is assigned to the UE
            %
            %       StartSymbol         Start symbol of time-domain resources
            %
            %       NumSymbols          Number of symbols allotted in time-domain
            %
            %       SlotOffset          Slot offset of PDSCH assignment
            %                           w.r.t the current slot
            %
            %       MCS                 Selected modulation and coding scheme for UE with
            %                           respect to the resource assignment done
            %
            %       NDI                 New data indicator flag
            %
            %       FeedbackSlotOffset  Slot offset of PDSCH ACK/NACK from
            %                           PDSCH transmission slot (i.e. k1).
            %                           Currently, only a value >=2 is supported 
            %
            %       DMRSLength          DM-RS length 
            %
            %       MappingType         Mapping type
            %
            %       NumLayers           Number of transmission layers
            %
            %       NumCDMGroupsWithoutData     Number of CDM groups without data (1...3)
            %
            %       PrecodingMatrix     Selected precoding matrix.  
            %                           It is an array of size NumLayers-by-P-by-NPRG, where NPRG is the
            %                           number of PRGs in the carrier and P is the number of CSI-RS
            %                           ports. It defines a different precoding matrix of size
            %                           NumLayers-by-P for each PRG. The effective PRG bundle size
            %                           (precoder granularity) is Pd_BWP = ceil(NRB / NPRG). 
            %                           For SISO, set it to 1
            
            % Calculate offset of the slot to be scheduled, from the current slot
            if slotNum >= obj.CurrSlot  % Slot to be scheduled is in the current frame
                slotOffset = slotNum - obj.CurrSlot;
            else % Slot to be scheduled is in the next frame
                slotOffset = (obj.NumSlotsFrame + slotNum) - obj.CurrSlot;
            end

            % Get start DL symbol and number of DL symbols in the slot
            if obj.DuplexMode == 1 % TDD mode
                DLULPatternIndex = mod(obj.CurrDLULSlotIndex + slotOffset, obj.NumDLULPatternSlots);
                slotFormat = obj.DLULSlotFormat(DLULPatternIndex + 1, :);
                firstDLSym = find(slotFormat == obj.DLType, 1, 'first') - 1; % Location of first DL symbol in the slot
                lastDLSym = find(slotFormat == obj.DLType, 1, 'last') - 1; % Location of last DL symbol in the slot
                numDLSym = lastDLSym - firstDLSym + 1;
            else
                % For FDD, all symbols are DL symbols
                firstDLSym = 0;
                numDLSym = 14;
            end

            if obj.SchedulingType == 0  % Slot based scheduling
                % Assignments to span all the symbols in the slot
                downlinkGrants = assignDLResourceTTI(obj, slotNum, firstDLSym, numDLSym);
                % Update served data rate for the UEs as per the resource
                % assignments. This affects scheduling decisions for future
                % TTI
                updateUEServedDataRate(obj, obj.DLType, downlinkGrants);
            else %Symbol based scheduling
                if numDLSym < 2 % PDSCH requires minimum 2 symbols with mapping type B as per TS 38.214 - Table 5.1.2.1-1
                    downlinkGrants = [];
                    return; % Not enough symbols for minimum TTI granularity
                end
                numTTIs = floor(numDLSym / obj.TTIGranularity); % DL TTIs in the slot

                % DL grant array with maximum size to store grants. Maximum
                % grants possible in a slot is the product of number of
                % TTIs in slot and number of UEs
                downlinkGrants = cell((ceil(14/obj.TTIGranularity) * length(obj.UEs)), 1);
                numDLGrants = 0;

                % Schedule all DL TTIs in the slot one-by-one
                startSym = firstDLSym;
                for i = 1 : numTTIs
                    TTIDLGrants = assignDLResourceTTI(obj, slotNum, startSym, obj.TTIGranularity);
                    downlinkGrants(numDLGrants + 1 : numDLGrants + length(TTIDLGrants)) = TTIDLGrants(:);
                    numDLGrants = numDLGrants + length(TTIDLGrants);
                    startSym = startSym + obj.TTIGranularity;

                    % Update served data rate for the UEs as per the resource
                    % assignments. This affects scheduling decisions for future
                    % TTI
                    updateUEServedDataRate(obj, obj.DLType, TTIDLGrants);
                end
                
                remDLSym = mod(numDLSym, obj.TTIGranularity); % Remaining unscheduled DL symbols
                % Schedule the remaining unscheduled DL symbols with
                % granularity lesser than obj.TTIGranularity
                if remDLSym >= 2 % PDSCH requires minimum 2 symbols with mapping type B as per TS 38.214 - Table 5.1.2.1-1
                    ttiGranularity =  [7 4 2];
                    smallerTTIs = ttiGranularity(ttiGranularity < obj.TTIGranularity); % TTI lengths lesser than obj.TTIGranularity
                    for i = 1:length(smallerTTIs)
                        if(smallerTTIs(i) <= remDLSym)
                            TTIDLGrants = assignDLResourceTTI(obj, slotNum, startSym, smallerTTIs(i));
                            downlinkGrants(numDLGrants + 1 : numDLGrants + length(TTIDLGrants)) = TTIDLGrants(:);
                            numDLGrants = numDLGrants + length(TTIDLGrants);
                            startSym = startSym + smallerTTIs(i);
                            remDLSym = remDLSym - smallerTTIs(i);
                            % Update served data rate for the UEs as per the resource
                            % assignments. This affects scheduling decisions for future
                            % TTI
                            updateUEServedDataRate(obj, obj.DLType, TTIDLGrants);
                        end
                    end
                end
                downlinkGrants = downlinkGrants(1 : numDLGrants);
            end
        end
    end

    methods(Access = private)
        function updateUEServedDataRate(obj, linkType, resourceAssignments)
            %updateUEServedDataRate Update UEs' served data rate based on RB assignments
            
            if linkType % Uplink
                mcsTable = obj.MCSTableUL;
                pusch = obj.PUSCHConfig;
                % UL carrier configuration object
                ulCarrierConfig = obj.CarrierConfigUL;
            else % Downlink
                mcsTable = obj.MCSTableDL;
                pdsch = obj.PDSCHConfig;
                % DL carrier configuration object
                dlCarrierConfig = obj.CarrierConfigDL;
            end
            
            % Store UEs which got grant
            scheduledUEs = zeros(length(obj.UEs), 1);
            % Update served data rate for UEs which got grant
            for i = 1:length(resourceAssignments)
                resourceAssignment = resourceAssignments{i};
                scheduledUEs(i) = resourceAssignment.RNTI;
                averageDataRate = obj.UEsServedDataRate(resourceAssignment.RNTI ,linkType+1);
                mcsInfo = mcsTable(resourceAssignment.MCS + 1, :);
                modSchemeBits = mcsInfo(1); % Bits per symbol for modulation scheme
                codeRate = mcsInfo(2)/1024;
                % Modulation scheme and corresponding bits/symbol
                fullmodlist = ["pi/2-BPSK", "BPSK", "QPSK", "16QAM", "64QAM", "256QAM"]';
                qm = [1 1 2 4 6 8];
                modScheme = fullmodlist((modSchemeBits == qm)); % Get modulation scheme string
               
                if linkType % Uplink
                    pusch.SymbolAllocation = [resourceAssignment.StartSymbol resourceAssignment.NumSymbols];
                    pusch.MappingType = resourceAssignment.MappingType;
                    if pusch.MappingType == 'A'
                        dmrsAdditonalPos = obj.PUSCHDMRSAdditionalPosTypeA;
                    else
                        dmrsAdditonalPos = obj.PUSCHDMRSAdditionalPosTypeB;
                    end
                    pusch.DMRS.DMRSLength = resourceAssignment.DMRSLength;
                    pusch.DMRS.DMRSAdditionalPosition = dmrsAdditonalPos;
                    pusch.PRBSet = convertRBGBitmapToRBs(obj, resourceAssignment.RBGAllocationBitmap, linkType);
                    pusch.Modulation = modScheme(1);
                    [~, puschIndicesInfo] = nrPUSCHIndices(ulCarrierConfig, pusch);
                    nLayers = 1;
                    achievedTxBits = nrTBS(modScheme(1), nLayers, length(pusch.PRBSet), ...
                        puschIndicesInfo.NREPerPRB, codeRate);
                else
                    pdsch.SymbolAllocation = [resourceAssignment.StartSymbol resourceAssignment.NumSymbols];
                    pdsch.MappingType = resourceAssignment.MappingType;
                    if pdsch.MappingType == 'A'
                        dmrsAdditonalPos = obj.PDSCHDMRSAdditionalPosTypeA;
                    else
                        dmrsAdditonalPos = obj.PDSCHDMRSAdditionalPosTypeB;
                    end
                    pdsch.DMRS.DMRSLength = resourceAssignment.DMRSLength;
                    pdsch.DMRS.DMRSAdditionalPosition = dmrsAdditonalPos;
                    pdsch.PRBSet = convertRBGBitmapToRBs(obj, resourceAssignment.RBGAllocationBitmap, linkType);
                    pdsch.Modulation = modScheme(1);
                    [~, pdschIndicesInfo] = nrPDSCHIndices(dlCarrierConfig, pdsch);
                    nLayers = resourceAssignment.NumLayers;
                    achievedTxBits = nrTBS(modScheme(1), nLayers, length(pdsch.PRBSet), ...
                        pdschIndicesInfo.NREPerPRB, codeRate);
                end
                
                ttiDuration = (obj.SlotDuration * resourceAssignment.NumSymbols)/14;
                achievedDataRate = (achievedTxBits*1000)/ttiDuration; % bits/sec
                updatedAverageDataRate = ((1-obj.MovingAvgDataRateWeight) * averageDataRate) + ...
                    (obj.MovingAvgDataRateWeight * achievedDataRate);
                obj.UEsServedDataRate(resourceAssignment.RNTI, linkType+1) = updatedAverageDataRate;
            end
            scheduledUEs = nonzeros(scheduledUEs);
            unScheduledUEs = setdiff(obj.UEs, scheduledUEs);
            
            % Update (decrease) served data rate for each unscheduled UE
            for i=1:length(unScheduledUEs)
                averageDataRate = obj.UEsServedDataRate(unScheduledUEs(i) ,linkType+1);
                updatedAverageDataRate = (1-obj.MovingAvgDataRateWeight) * averageDataRate;
                obj.UEsServedDataRate(unScheduledUEs(i), linkType+1) = updatedAverageDataRate;
            end
        end
    end
end