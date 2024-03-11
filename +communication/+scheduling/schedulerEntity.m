classdef (Abstract) schedulerEntity < handle
    %schedulerEntity Implements physical uplink shared channel (PUSCH) and physical downlink shared channel (PDSCH) resource scheduling
    %   The class implements uplink (UL) and downlink (DL) scheduling for
    %   both FDD and TDD modes. It supports both slot based and symbol
    %   based scheduling. Scheduling is only done at slot boundary when
    %   start symbol is DL so that output (resource assignments) can be
    %   immediately conveyed to UEs in DL direction, assuming zero run time
    %   for scheduler algorithm. Hence, in frequency division duplex (FDD)
    %   mode the schedulers (DL and UL) run periodically (configurable) as
    %   every slot is DL while for time division duplex (TDD) mode, DL time
    %   is checked. In FDD mode, schedulers run to assign the resources
    %   from the next unscheduled slot onwards and a count of slots equal
    %   to scheduler periodicity in terms of number of slots are scheduled.
    %   In TDD mode, the UL scheduler schedules the resources as close to
    %   the transmission time as possible. The DL scheduler in TDD mode
    %   runs to assign DL resources of the next slot with unscheduled DL
    %   resources. Scheduler does the UL resource allocation while
    %   considering the PUSCH preparation capability of UEs. Scheduling
    %   decisions are based on selected scheduling strategy, scheduler
    %   configuration and the context (buffer status, served data rate,
    %   channel conditions and pending retransmissions) maintained for each
    %   UE. The information available to scheduler for making scheduling
    %   decisions is present as various properties of this class. The class
    %   also implements the MAC portion of the HARQ functionality for
    %   retransmissions.

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties (SetAccess = protected, GetAccess = public)
        %UEs RNTIs of the UEs connected to the gNB
        UEs {mustBeInteger, mustBeInRange(UEs, 1, 65519)};

        %SCS Subcarrier spacing used. The default value is 15 kHz
        SCS (1, 1) {mustBeMember(SCS, [15, 30, 60, 120, 240])} = 15;

        %Slot duration in ms
        SlotDuration

        %NumSlotsFrame Number of slots in a 10 ms frame. Depends on the SCS used
        NumSlotsFrame

        %ULReservedResource Reserved resources information for UL direction
        % Array of three elements: [symNum slotPeriodicity slotOffset].
        % These symbols are not available for PUSCH scheduling as per the
        % slot offset and periodicity. Currently, it is used for SRS
        % resources reservation
        ULReservedResource

        %SchedulingType Type of scheduling (slot based or symbol based)
        % Value 0 means slot based and value 1 means symbol based. The
        % default value is 0
        SchedulingType (1, 1) {mustBeInteger, mustBeInRange(SchedulingType, 0, 1)} = 0;

        %DuplexMode Duplexing mode (FDD or TDD)
        % Value 0 means FDD and 1 means TDD. The default value is 0
        DuplexMode (1, 1) {mustBeInteger, mustBeInRange(DuplexMode, 0, 1)} = 0;

        %NumDLULPatternSlots Number of slots in DL-UL pattern (for TDD mode)
        % The default value is 5 slots
        NumDLULPatternSlots (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(NumDLULPatternSlots, 0), mustBeFinite} = 5;

        %NumDLSlots Number of full DL slots at the start of DL-UL pattern (for TDD mode)
        % The default value is 2 slots
        NumDLSlots (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(NumDLSlots, 0), mustBeFinite} = 2;

        %NumDLSyms Number of DL symbols after full DL slots in the DL-UL pattern (for TDD mode)
        % The default value is 8 symbols
        NumDLSyms (1, 1) {mustBeInteger, mustBeInRange(NumDLSyms, 0, 13)} = 8;

        %NumULSyms Number of UL symbols before full UL slots in the DL-UL pattern (for TDD mode)
        % The default value is 4 symbols
        NumULSyms (1, 1) {mustBeInteger, mustBeInRange(NumULSyms, 0, 13)} = 4;

        %NumULSlots Number of full UL slots at the end of DL-UL pattern (for TDD mode)
        % The default value is 2 slots
        NumULSlots (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(NumULSlots, 0), mustBeFinite} = 2;

        %DLULSlotFormat Format of the slots in DL-UL pattern (for TDD mode)
        % N-by-14 matrix where 'N' is number of slots in DL-UL pattern.
        % Each row contains the symbol type of the 14 symbols in the slot.
        % Value 0, 1 and 2 represent DL symbol, UL symbol, guard symbol,
        % respectively
        DLULSlotFormat

        %NextULSchedulingSlot Slot to be scheduled next by UL scheduler
        % Slot number in the 10 ms frame whose resources will be scheduled
        % when UL scheduler runs next (for TDD mode)
        NextULSchedulingSlot

        %NumPUSCHRBs Number of resource blocks (RB) in the uplink bandwidth
        % The default value is 52 RBs
        NumPUSCHRBs (1, 1){mustBeNonempty, mustBeInteger, mustBeInRange(NumPUSCHRBs, 1, 275)} = 52;

        %NumPDSCHRBs Number of RBs in the downlink bandwidth
        % The default value is 52 RBs
        NumPDSCHRBs (1, 1){mustBeNonempty, mustBeInteger, mustBeInRange(NumPDSCHRBs, 1, 275)} = 52;

        %XOverheadPDSCH Additional overheads in PDSCH transmission
        XOverheadPDSCH = 6;

        %RBGSizeUL Size of an uplink resource block group (RBG) in terms of number of RBs
        RBGSizeUL

        %RBGSizeDL Size of a downlink RBG in terms of number of RBs
        RBGSizeDL

        %NumRBGsUL Number of RBGs in uplink bandwidth
        NumRBGsUL

        %NumRBGsDL Number of RBGs in downlink bandwidth
        NumRBGsDL

        %RBAllocationLimitUL Maximum limit on number of RBs that can be allotted for a PUSCH
        % The limit is applicable for new PUSCH transmissions and not for
        % retransmissions
        RBAllocationLimitUL {mustBeInteger, mustBeInRange(RBAllocationLimitUL, 1, 275)};

        %RBAllocationLimitDL Maximum limit on number of RBs that can be allotted for a PDSCH
        % The limit is applicable for new PDSCH transmissions and not for
        % retransmissions
        RBAllocationLimitDL {mustBeInteger, mustBeInRange(RBAllocationLimitDL, 1, 275)};

        %SchedulerPeriodicity Periodicity at which the schedulers (DL and UL) run in terms of number of slots (for FDD mode)
        % Default value is 1 slot
        SchedulerPeriodicity {mustBeInteger, mustBeInRange(SchedulerPeriodicity, 1, 160)} = 1;

        %PUSCHPrepSymDur PUSCH preparation time in terms of number of symbols
        % Scheduler ensures that PUSCH grant arrives at UEs at least these
        % many symbols before the transmission time
        PUSCHPrepSymDur

        %BufferStatusDL Stores pending buffer amount in DL direction for logical channels of UEs
        % N-by-32 matrix where 'N' is the number of UEs. Each row represents a
        % UE and has 32 columns to store the pending DL buffer (in bytes)
        % for logical channel IDs 1 to 32
        BufferStatusDL

        %BufferStatusUL Stores pending buffer amount in UL direction for logical channel groups of UEs
        % N-by-8 matrix where 'N' is the number of UEs. Each row represents a
        % UE and has 8 columns to store the pending UL buffer amount (in
        % bytes) for each logical channel group.
        BufferStatusUL

        %CQITableUL CQI table used for uplink
        % It contains the mapping of CQI indices with Modulation and Coding
        % schemes
        CQITableUL

        %MCSTableUL MCS table used for uplink
        % It contains the mapping of MCS indices with Modulation and Coding
        % schemes
        MCSTableUL

        %CQITableDL CQI table used for downlink
        % It contains the mapping of CQI indices with Modulation and Coding
        % schemes
        CQITableDL

        %MCSTableDL MCS table used for downlink
        % It contains the mapping of MCS indices with Modulation and Coding
        % schemes
        MCSTableDL

        %TTIGranularity Minimum time-domain assignment in terms of number of symbols (for symbol based scheduling).
        % The default value is 4 symbols
        TTIGranularity {mustBeMember(TTIGranularity, [2, 4, 7])} = 4;

        %DMRSTypeAPosition Position of DM-RS in type A transmission
        DMRSTypeAPosition (1, 1) {mustBeMember(DMRSTypeAPosition, [2, 3])} = 2;

        %PUSCHMappingType PUSCH mapping type
        PUSCHMappingType (1,1) {mustBeMember(PUSCHMappingType, ['A', 'B'])} = 'A';

        %PUSCHDMRSConfigurationType PUSCH DM-RS configuration type (1 or 2)
        PUSCHDMRSConfigurationType (1,1) {mustBeMember(PUSCHDMRSConfigurationType, [1, 2])} = 1;

        %PUSCHDMRSLength PUSCH demodulation reference signal (DM-RS) length
        PUSCHDMRSLength (1, 1) {mustBeMember(PUSCHDMRSLength, [1, 2])} = 1;

        %PUSCHDMRSAdditionalPosTypeA Additional PUSCH DM-RS positions for type A (0..3)
        PUSCHDMRSAdditionalPosTypeA (1, 1) {mustBeMember(PUSCHDMRSAdditionalPosTypeA, [0, 1, 2, 3])} = 0;

        %PUSCHDMRSAdditionalPosTypeB Additional PUSCH DM-RS positions for type B (0..3)
        PUSCHDMRSAdditionalPosTypeB (1, 1) {mustBeMember(PUSCHDMRSAdditionalPosTypeB, [0, 1, 2, 3])} = 0;

        %PDSCHMappingType PDSCH mapping type
        PDSCHMappingType (1, 1) {mustBeMember(PDSCHMappingType, ['A', 'B'])} = 'A';

        %PDSCHDMRSConfigurationType PDSCH DM-RS configuration type (1 or 2)
        PDSCHDMRSConfigurationType (1,1) {mustBeMember(PDSCHDMRSConfigurationType, [1, 2])} = 1;

        %PDSCHDMRSLength PDSCH demodulation reference signal (DM-RS) length
        PDSCHDMRSLength (1, 1) {mustBeMember(PDSCHDMRSLength, [1, 2])} = 1;

        %PDSCHDMRSAdditionalPosTypeA Additional PDSCH DM-RS positions for type A (0..3)
        PDSCHDMRSAdditionalPosTypeA (1, 1) {mustBeMember(PDSCHDMRSAdditionalPosTypeA, [0, 1, 2, 3])} = 0;

        %PDSCHDMRSAdditionalPosTypeB Additional PDSCH DM-RS positions for type B (0 or 1)
        PDSCHDMRSAdditionalPosTypeB (1, 1) {mustBeMember(PDSCHDMRSAdditionalPosTypeB, [0, 1])} = 0;

        %CSIMeasurementDL Reported DL CSI measurements
        % Array of size 'N', where 'N' is the number of UEs. Each element is a structure with the fields: 'RankIndicator', 'PMISet', 'CQI'
        % RankIndicator is a scalar value to representing the rank reported by a UE.
        % PMISet has the following fields:
        %   i1 - Indicates wideband PMI (1-based). It a three-element vector in the
        %        form of [i11 i12 i13].
        %   i2 - Indicates subband PMI (1-based). It is a vector of length equal to
        %        the number of subbands or number of PRGs.
        % CQI - Array of size equal to number of RBs in the bandwidth. Each index
        % contains the CQI value corresponding to the RB index.
        CSIMeasurementDL

        %CSIMeasurementUL Reported UL CSI measurements
        % Array of size 'N', where 'N' is the number of UEs. Each element is a structure with the fields: 'RankIndicator', 'TPMI', 'CQI'
        % RankIndicator is a scalar value to representing the rank estimated for a UE.
        % TPMI - Transmission precoding matrix indicator
        % CQI - Array of size equal to number of RBs in the bandwidth. Each index
        % contains the CQI value corresponding to the RB index.
        CSIMeasurementUL

        %GNBTxAntPanel gNB Tx antenna panel geometry
        % It is an array of the form [M, N, P, Mg, Ng] where M and N are
        % the number of rows and columns in the antenna array, P is the
        % number of polarizations (1 or 2), Mg and Ng are the number of row
        % and column array panels, respectively
        GNBTxAntPanel

        %GNBRxAntPanel gNB Rx antenna panel geometry
        % It is an array of the form [M, N, P, Mg, Ng] where M and N are
        % the number of rows and columns in the antenna array, P is the
        % number of polarizations (1 or 2), Mg and Ng are the number of row
        % and column array panels, respectively
        GNBRxAntPanel

        %UEsTxAntPanel UEs' Tx antenna panel geometry
        % It is an array of the form [M, N, P, Mg, Ng] for each UE, where M
        % and N are the number of rows and columns in the antenna array, P
        % is the number of polarizations (1 or 2), Mg and Ng are the number
        % of row and column array panels, respectively
        UEsTxAntPanel

        %UEsRxAntPanel UEs' Rx antenna panel geometry
        % It is an array of the form [M, N, P, Mg, Ng] for each UE where M
        % and N are the number of rows and columns in the antenna array, P
        % is the number of polarizations (1 or 2), Mg and Ng are the number
        % of row and column array panels, respectively
        UEsRxAntPanel

        %NumCSIRSPorts Number of CSI-RS antenna ports for the UEs
        % Vector of length 'N' where 'N' is the number of UEs. Value at
        % index 'i' contains the number of CSI-RS ports for UE with RNTI
        % 'i'
        NumCSIRSPorts

        %NumSRSPorts Number of SRS antenna ports for the UEs
        % Vector of length 'N' where 'N' is the number of UEs. Value at
        % index 'i' contains ths number of SRS ports for UE with RNTI 'i'
        NumSRSPorts

        %NumHARQ Number of HARQ processes
        % The default value is 16 HARQ processes
        NumHARQ (1, 1) {mustBeInteger, mustBeInRange(NumHARQ, 1, 16)} = 16;

        %HarqProcessesUL Uplink HARQ processes context
        % N-by-P structure array where 'N' is the number of UEs and 'P' is
        % the number of HARQ processes. Each row in this matrix stores the
        % context of all the uplink HARQ processes of a particular UE.
        HarqProcessesUL

        %HarqProcessesDL Downlink HARQ processes context
        % N-by-P structure array where 'N' is the number of UEs and 'P' is
        % the number of HARQ processes. Each row in this matrix stores the
        % context of all the downlink HARQ processes of a particular UE.
        HarqProcessesDL

        %HarqStatusUL Status (free or busy) of each uplink HARQ process of the UEs
        % N-by-P cell array where 'N' is the number of UEs and 'P' is the number
        % of HARQ processes. A non-empty value at index (i,j) indicates
        % that HARQ process is busy with value being the uplink grant for
        % the UE with RNTI 'i' and HARQ index 'j'. Empty value indicates
        % that the HARQ process is free.
        HarqStatusUL

        %HarqStatusDL Status (free or busy) of each downlink HARQ process of the UEs
        % N-by-P cell array where 'N' is the number of UEs and 'P' is the number
        % of HARQ processes. A non-empty value at index (i,j) indicates
        % that HARQ process is busy with value being the downlink grant for
        % the UE with RNTI 'i' and HARQ index 'j'. Empty value indicates
        % that the HARQ process is free.
        HarqStatusDL

        %HarqNDIDL Last sent NDI value for the DL HARQ processes of the UEs
        % N-by-P logical array where 'N' is the number of UEs and 'P' is the number
        % of HARQ processes. Values at index (i,j) stores the last sent NDI
        % for the UE with RNTI 'i' and DL HARQ process index 'j'
        HarqNDIDL

        %HarqNDIUL Last sent NDI value for the UL HARQ processes of the UEs
        % N-by-P logical array where 'N' is the number of UEs and 'P' is the number
        % of HARQ processes. Values at index (i,j) stores the last sent NDI
        % for the UE with RNTI 'i' and UL HARQ process index 'j'
        HarqNDIUL

        %RetransmissionContextUL Information about uplink retransmission requirements of the UEs
        % N-by-P cell array where 'N' is the number of UEs and 'P' is the
        % number of HARQ processes. It stores the information of HARQ
        % processes for which the reception failed at gNB. This information
        % is used for assigning uplink grants for retransmissions. Each row
        % corresponds to a UE and a non-empty value in one of its columns
        % indicates that the reception has failed for this particular HARQ
        % process governed by the column index. The value in the cell
        % element would be uplink grant information used by the UE for the
        % previous failed transmission
        RetransmissionContextUL

        %RetransmissionContextDL Information about downlink retransmission requirements of the UEs
        % N-by-P cell array where 'N' is the number of UEs and 'P' is the
        % number of HARQ processes. It stores the information of HARQ
        % processes for which the reception failed at UE. This information
        % is used for assigning downlink grants for retransmissions. Each
        % row corresponds to a UE and a non-empty value in one of its
        % columns indicates that the reception has failed for this
        % particular HARQ process governed by the column index. The value
        % in the cell element would be downlink grant information used by
        % the gNB for the previous failed transmission
        RetransmissionContextDL

        %TBSizeDL Stores the size of transport block sent for DL HARQ processes
        % N-by-P matrix where 'N' is the number of UEs and P is number of
        % HARQ process. Value at index (i,j) stores size of transport block
        % sent for UE with RNTI 'i' for HARQ process index 'j'.
        % Value is 0 if DL HARQ process is free
        TBSizeDL

        %TBSizeUL Stores the size of transport block to be received for UL HARQ processes
        % N-by-P matrix where 'N' is the number of UEs and P is number of
        % HARQ process. Value at index (i,j) stores size of transport block
        % to be received from UE with RNTI 'i' for HARQ process index 'j'.
        % Value is 0, if no UL packet expected for HARQ process of the UE
        TBSizeUL
    end

    properties (Access = protected)
        %CurrSlot Current running slot number in the 10 ms frame at the time of scheduler invocation
        CurrSlot = 0;

        %CurrSymbol Current running symbol of the current slot at the time of scheduler invocation
        CurrSymbol = 0;

        %SFN System frame number (0 ... 1023) at the time of scheduler invocation
        SFN = 0;

        %CurrDLULSlotIndex Slot index of the current running slot in the DL-UL pattern at the time of scheduler invocation (for TDD mode)
        CurrDLULSlotIndex = 0;

        %SlotsSinceSchedulerRunDL Number of slots elapsed since last DL scheduler run (for FDD mode)
        % It is incremented every slot and when it reaches the
        % 'SchedulerPeriodicity', it is reset to zero and DL scheduler runs
        SlotsSinceSchedulerRunDL

        %SlotsSinceSchedulerRunUL Number of slots elapsed since last UL scheduler run (for FDD mode)
        % It is incremented every slot and when it reaches the
        % 'SchedulerPeriodicity', it is reset to zero and UL scheduler runs
        SlotsSinceSchedulerRunUL

        %LastSelectedUEUL The RNTI of UE which was assigned the last scheduled uplink RBG
        LastSelectedUEUL = 0;

        %LastSelectedUEDL The RNTI of UE which was assigned the last scheduled downlink RBG
        LastSelectedUEDL = 0;

        %GuardDuration Guard period in the DL-UL pattern in terms of number of symbols (for TDD mode)
        GuardDuration

        %Type1SinglePanelCodebook Type-1 single panel precoding matrix codebook
        Type1SinglePanelCodebook = []

        %PrecodingGranularity PDSCH precoding granularity in terms of physical resource blocks (PRBs)
        PrecodingGranularity = 2
    end

    properties (Constant)
        %NominalRBGSizePerBW Nominal RBG size for the specified bandwidth in accordance with 3GPP TS 38.214, Section 5.1.2.2.1
        NominalRBGSizePerBW = [
            36   2   4
            72   4   8
            144  8   16
            275  16  16 ];

        %DLType Value to specify downlink direction or downlink symbol type
        DLType = 0;

        %ULType Value to specify uplink direction or uplink symbol type
        ULType = 1;

        %GuardType Value to specify guard symbol type
        GuardType = 2;

        %SchedulerInput Format of the context that will be sent to the scheduling strategy
        SchedulerInput = struct('LinkDir', 0, 'eligibleUEs', 1, 'slotNum', 0, 'startSym', 0, ...
            'numSym', 0, 'RBGIndex', 0, 'RBGSize', 0, 'bufferStatus', 0, 'cqiRBG', 1, ...
            'mcsRBG', 1, 'ttiDur', 1, 'UEs', 1, 'selectedRank', 1, 'lastSelectedUE', 1);
    end

    properties (Access = protected)
        %% Transient object maintained for optimization
        %PUSCHConfig nrPUSCHConfig object
        PUSCHConfig
        %PDSCHConfig nrPDSCHConfig object
        PDSCHConfig
        %CarrierConfigUL nrCarrierConfig object for UL
        CarrierConfigUL
        %CarrierConfigDL nrCarrierConfig object for DL
        CarrierConfigDL
    end

    methods
        function obj = schedulerEntity(param)
            %schedulerEntity Construct gNB MAC scheduler object
            %
            % param is a structure including the following fields:
            % NumUEs           - Number of UEs in the cell
            % DuplexMode       - Duplexing mode: FDD (value 0) or TDD (value 1)
            % SchedulingType   - Slot based scheduling (value 0) or symbol based scheduling (value 1)
            % TTIGranularity   - Smallest TTI size in terms of number of symbols (for symbol based scheduling)
            % NumRBs           - Number of resource blocks in PUSCH and PDSCH bandwidth
            % SCS              - Subcarrier spacing
            % SchedulerPeriodicity   - Scheduler run periodicity in slots (for FDD mode)
            % RBAllocationLimitUL    - Maximum limit on the number of RBs allotted to a UE for a PUSCH
            % RBAllocationLimitDL    - Maximum limit on the number of RBs allotted to a UE for a PDSCH
            % NumHARQ                - Number of HARQ processes
            % EnableHARQ       - Flag to enable/disable retransmissions
            % DLULPeriodicity  - Duration of the DL-UL pattern in ms (for TDD mode)
            % NumDLSlots       - Number of full DL slots at the start of DL-UL pattern (for TDD mode)
            % NumDLSyms        - Number of DL symbols after full DL slots of DL-UL pattern (for TDD mode)
            % NumULSyms        - Number of UL symbols before full UL slots of DL-UL pattern (for TDD mode)
            % NumULSlots       - Number of full UL slots at the end of DL-UL pattern (for TDD mode)
            % PUSCHPrepTime    - PUSCH preparation time required by UEs (in microseconds)
            % RBGSizeConfig    - RBG size configuration as 1 (configuration-1 RBG table) or 2 
            %                    (configuration-2 RBG table) as defined in 3GPP TS 38.214 Section 5.1.2.2.1. It 
            %                    defines the number of RBs in an RBG. Default value is 1
            % DMRSTypeAPosition            - DM-RS type A position (2 or 3)
            % PUSCHMappingType             - PUSCH mapping type ('A' or 'B')
            % PUSCHDMRSConfigurationType   - PUSCH DM-RS configuration type (1 or 2)
            % PUSCHDMRSLength              - PUSCH DM-RS length (1 or 2)
            % PUSCHDMRSAdditionalPosTypeA  - Additional PUSCH DM-RS positions for Type A (0..3)
            % PUSCHDMRSAdditionalPosTypeB  - Additional PUSCH DM-RS positions for Type B (0..3)
            % PDSCHMappingType             - PDSCH mapping type ('A' or 'B')
            % PDSCHDMRSConfigurationType   - PDSCH DM-RS configuration type (1 or 2)
            % PDSCHDMRSLength              - PDSCH DM-RS length (1 or 2)
            % PDSCHDMRSAdditionalPosTypeA  - Additional PDSCH DM-RS positions for Type A (0..3)
            % PDSCHDMRSAdditionalPosTypeB  - Additional PDSCH DM-RS positions for Type B (0 or 1)
            % GNBTxAnts       - Number of GNB Tx antennas
            % GNBRxAnts       - Number of GNB Rx antennas
            % UETxAnts        - Number of Tx antennas on UEs. Vector of length 'N' where N is number of UEs.
            %                   Value at index 'i' contains Tx antennas at UE with RNTI 'i'
            % UERxAnts        - Number of Rx antennas on UEs. Vector of length 'N' where N is number of UEs.
            %                   Value at index 'i' contains Rx antennas at UE with RNTI 'i'
            % SRSConfig       - Cell array of size equal to number of UEs. An element at index 'i' is an
            %                   object of type nrSRSConfig and stores the SRS configuration of UE with RNTI 'i'
            % CSIRSConfig     - Cell array containing the CSI-RS configuration information as an object of 
            %                   type nrCSIRSConfig. The element at index 'i' corresponds to the CSI-RS 
            %                   configured for a UE with RNTI 'i'. If only one configuration is specified,
            %                   it is assumed to be applicable for all the UEs in the cell.
            % CSIReportConfig       - Cell array containing the CSI-RS report configuration information as a
            %                         structure. The element at index 'i' corresponds to the CSI-RS report 
            %                         configured for a UE with RNTI 'i'. If only one CSI-RS report configuration 
            %                         is specified, it is assumed to be applicable for all the UEs in the cell. 
            %                         Each element is a structure with the following fields:
            %                             CQIMode         - CQI reporting mode. Value as 'Subband' or 'Wideband'
            %                             SubbandSize     - Subband size for CQI or PMI reporting as per TS 
            %                                               38.214 Table 5.2.1.4-2
            %                             Additional fields for MIMO systems:                       
            %                             PanelDimensions - Antenna panel configuration as a two-element vector 
            %                                               in the form of [N1 N2].
            %                                               N1 represents the number of antenna elements in 
            %                                               horizontal direction and N2 represents the number 
            %                                               of antenna elements in vertical direction. 
            %                                               Valid combinations of [N1 N2] are defined in 3GPP 
            %                                               TS 38.214 Table 5.2.2.2.1-2
            %                             PMIMode         - PMI reporting mode. Value as 'Subband' or 'Wideband'
            %                             CodebookMode    - Codebook mode. Value as 1 or 2
            % SRSSubbandSize   - SRS subband size (in RBs)

            % Initialize the class properties
            % Validate the number of UEs
            validateattributes(param.numUEs, {'numeric'}, {'nonempty', ...
                'integer', 'scalar', '>', 0, '<=', 65519}, 'param.numUEs', 'numUEs');
            % UEs are assumed to have sequential radio network temporary
            % identifiers (RNTIs) from 1 to NumUEs
            obj.UEs = 1:param.numUEs;
            if isfield(param, 'scs')
                obj.SCS = param.scs;
            end
            obj.SlotDuration = 1/(obj.SCS/15); % In ms
            obj.NumSlotsFrame = 10/obj.SlotDuration; % Number of slots in a 10 ms frame

            if isfield(param, 'PUSCHPrepTime')
                validateattributes(param.PUSCHPrepTime, {'numeric'}, ...
                    {'nonempty', 'integer', 'scalar', 'finite', '>=', 0}, ...
                    'param.PUSCHPrepTime', 'PUSCHPrepTime');
                obj.PUSCHPrepSymDur = ceil(param.PUSCHPrepTime/((obj.SlotDuration*1000)/14));
            else
                % Default value is 200 microseconds
                obj.PUSCHPrepSymDur = ceil(200/((obj.SlotDuration*1000)/14));
            end

            if isfield(param, 'schedulingType')
                obj.SchedulingType = param.schedulingType;
            end
            if obj.SchedulingType % Symbol based scheduling
                % Set TTI granularity
                if isfield(param, 'ttiGranularity')
                    obj.TTIGranularity = param.ttiGranularity;
                end
            end

            populateDuplexModeProperties(obj, param);

            if isfield(param, 'rbAllocationLimitUL')
                validateattributes(param.rbAllocationLimitUL, {'numeric'}, ...
                    {'nonempty', 'integer', 'scalar', '>=', 1, '<=',obj.NumPUSCHRBs},...
                    'param.rbAllocationLimitUL', 'rbAllocationLimitUL');
                obj.RBAllocationLimitUL = param.rbAllocationLimitUL;
            else
                % Set RB limit to half of the total number of RBs
                obj.RBAllocationLimitUL = floor(obj.NumPUSCHRBs * 0.5);
            end

            if isfield(param, 'rbAllocationLimitDL')
                validateattributes(param.rbAllocationLimitDL, {'numeric'}, ...
                    {'nonempty', 'integer', 'scalar', '>=', 1, '<=',obj.NumPDSCHRBs},...
                    'param.rbAllocationLimitDL', 'rbAllocationLimitDL');
                obj.RBAllocationLimitDL = param.rbAllocationLimitDL;
            else
                % Set RB limit to half of the total number of RBs
                obj.RBAllocationLimitDL = floor(obj.NumPDSCHRBs * 0.5);
            end

            numUEs = length(obj.UEs);
            if ~isfield(param, 'gNBTxAnts')
                param.gNBTxAnts = 1;
            % Validate the number of transmitter antennas on gNB
            elseif ~ismember(param.gNBTxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:scheduler:InvalidAntennaSize',...
                    'Number of gNB Tx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', param.gNBTxAnts);
            end
            if ~isfield(param, 'gNBRxAnts')
                param.gNBRxAnts = 1;
            % Validate the number of receiver antennas on gNB
            elseif ~ismember(param.gNBRxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:scheduler:InvalidAntennaSize',...
                    'Number of gNB Rx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', param.gNBRxAnts);
            end
            if ~isfield(param, 'ueTxAnts')
                param.ueTxAnts = ones(param.numUEs, 1);
            % Validate the number of transmitter antennas on UEs
            else
                validateattributes(param.ueTxAnts, {'numeric'}, {'nonempty', 'integer', 'nrows', param.numUEs, 'ncols', 1, 'finite'}, 'param.ueTxAnts', 'ueTxAnts')
                if any(~ismember(param.ueTxAnts, [1,2,4,8,16]))
                    error('nr5g:scheduler:InvalidAntennaSize',...
                        'Number of UE Tx antennas must be a member of [1,2,4,8,16].');
                end
            end
            if ~isfield(param, 'ueRxAnts')
                param.ueRxAnts = ones(param.numUEs, 1);
            % Validate the number of receiver antennas on UEs
            else
                validateattributes(param.ueRxAnts, {'numeric'}, {'nonempty', 'integer', 'nrows', param.numUEs, 'ncols', 1, 'finite'}, 'param.ueRxAnts', 'ueRxAnts')
                if any(~ismember(param.ueRxAnts, [1,2,4,8,16]))
                error('nr5g:scheduler:InvalidAntennaSize',...
                    'Number of UE Rx antennas must be a member of [1,2,4,8,16].');
                end
            end

            % Turn the overall number of antennas into a specific antenna panel
            % array geometry
            for i=1:numUEs
                % Downlink direction i.e. gNB's Tx antenna panel
                % configuration and UE's Rx panel configuration
                [obj.GNBTxAntPanel, obj.UEsRxAntPanel(i, :)] = deal(param.gNBTxPanel, param.ueAntPanel);

                % Uplink direction i.e. UE's Tx antenna panel
                % configuration and gNB's Rx panel configuration
                [obj.UEsTxAntPanel(i, :), obj.GNBRxAntPanel] = deal(param.ueAntPanel, param.gNBRxPanel);
            end

            obj.BufferStatusDL = zeros(numUEs, 32); % 32 logical channels
            obj.BufferStatusUL = zeros(numUEs, 8); % 8 logical channel groups

            % Store the CQI tables as matrices
            obj.CQITableUL = getCQITableUL(obj);
            obj.CQITableDL = getCQITableDL(obj);

            % Context initialization for HARQ processes
            if isfield(param, 'NumHARQ')
                obj.NumHARQ = param.NumHARQ;
            end
            harqProcess.RVSequence = [0 3 2 1]; % Set RV sequence

            % Validate the flag to enable/disable HARQ
            if isfield(param, 'EnableHARQ')
                % To support true/false
                validateattributes(param.EnableHARQ, {'logical', 'numeric'}, {'nonempty', 'integer', 'scalar'}, 'param.EnableHARQ', 'EnableHARQ');
                if isnumeric(param.EnableHARQ)
                    % To support 0/1
                    validateattributes(param.EnableHARQ, {'numeric'}, {'>=', 0, '<=', 1}, 'param.EnableHARQ', 'EnableHARQ');
                end
                if ~param.EnableHARQ
                    % No retransmissions
                    harqProcess.RVSequence = 0; % Set RV sequence
                end
            end
            ncw = 1; % Only single codeword
            harqProcess.ncw = ncw; % Set number of codewords
            harqProcess.blkerr = zeros(1, ncw); % Initialize block errors
            harqProcess.RVIdx = ones(1, ncw);  % Add RVIdx to process
            harqProcess.RV = harqProcess.RVSequence(ones(1,ncw));
            % Create HARQ processes context array for each UE
            obj.HarqProcessesUL = repmat(harqProcess, numUEs, obj.NumHARQ);
            obj.HarqProcessesDL = repmat(harqProcess, numUEs, obj.NumHARQ);
            for i=1:numUEs
                obj.HarqProcessesUL(i,:) = communication.harq.newHARQProcesses(obj.NumHARQ, harqProcess.RVSequence, ncw);
                obj.HarqProcessesDL(i,:) = communication.harq.newHARQProcesses(obj.NumHARQ, harqProcess.RVSequence, ncw);
            end

            % Initialize HARQ status and NDI
            obj.HarqStatusUL = cell(numUEs, obj.NumHARQ);
            obj.HarqStatusDL = cell(numUEs, obj.NumHARQ);
            obj.HarqNDIUL = false(numUEs, obj.NumHARQ);
            obj.HarqNDIDL = false(numUEs, obj.NumHARQ);

            % Create retransmission context
            obj.RetransmissionContextUL = cell(numUEs, obj.NumHARQ);
            obj.RetransmissionContextDL = cell(numUEs, obj.NumHARQ);

            obj.TBSizeDL = zeros(numUEs, obj.NumHARQ);
            obj.TBSizeUL = zeros(numUEs, obj.NumHARQ);

            if isfield(param, 'DMRSTypeAPosition')
                obj.DMRSTypeAPosition = param.DMRSTypeAPosition;
            end

            % PUSCH DM-RS configuration
            if isfield(param, 'PUSCHDMRSConfigurationType')
                obj.PUSCHDMRSConfigurationType = param.PUSCHDMRSConfigurationType;
            end
            if isfield(param, 'PUSCHMappingType')
                obj.PUSCHMappingType = param.PUSCHMappingType;
            end
            if isfield(param, 'PUSCHDMRSLength')
                obj.PUSCHDMRSLength = param.PUSCHDMRSLength;
            end
            if isfield(param, 'PUSCHDMRSAdditionalPosTypeA')
                obj.PUSCHDMRSAdditionalPosTypeA = param.PUSCHDMRSAdditionalPosTypeA;
            end
            if isfield(param, 'PUSCHDMRSAdditionalPosTypeB')
                obj.PUSCHDMRSAdditionalPosTypeB = param.PUSCHDMRSAdditionalPosTypeB;
            end

            % PDSCH DM-RS configuration
             if isfield(param, 'PDSCHDMRSConfigurationType')
                obj.PDSCHDMRSConfigurationType = param.PDSCHDMRSConfigurationType;
            end
            if isfield(param, 'PDSCHMappingType')
                obj.PDSCHMappingType = param.PDSCHMappingType;
            end
            if isfield(param, 'PDSCHDMRSLength')
                obj.PDSCHDMRSLength = param.PDSCHDMRSLength;
            end
            if isfield(param, 'PDSCHDMRSAdditionalPosTypeA')
                obj.PDSCHDMRSAdditionalPosTypeA = param.PDSCHDMRSAdditionalPosTypeA;
            end
            if isfield(param, 'PDSCHDMRSAdditionalPosTypeB')
                obj.PDSCHDMRSAdditionalPosTypeB = param.PDSCHDMRSAdditionalPosTypeB;
            end

            obj.NumSRSPorts = ones(numUEs, 1);
            if isfield(param, 'srsConfig')
                for srsIdx = 1:length(param.srsConfig)
                    if ~isa(param.srsConfig{srsIdx}, 'nrSRSConfig')
                        error('nr5g:scheduler:InvalidObjectType', "Each element of 'SRSConfig' must be specified as an object of type nrSRSConfig")
                    end
                    if param.srsConfig{srsIdx}.NumSRSPorts > param.ueTxAnts(srsIdx)
                        error('nr5g:scheduler:InvalidNumSRSPorts', 'Number of SRS antenna ports (%d) must be less than or equal to the number of UE Tx antennas.(%d)',...
                            param.srsConfig{srsIdx}.NumSRSPorts, param.ueTxAnts(srsIdx))
                    end
                end
                % Mark UL reserved resources for SRS
                obj.ULReservedResource = [param.srsConfig{1}.SymbolStart param.srsConfig{1}.SRSPeriod(1) param.srsConfig{1}.SRSPeriod(2)];
                idx = 1;
                obj.NumSRSPorts(1) = param.srsConfig{1}.NumSRSPorts;
                for srsIdx = 2:length(param.srsConfig)
                    ulReservedResource = [param.srsConfig{srsIdx}.SymbolStart param.srsConfig{srsIdx}.SRSPeriod(1) param.srsConfig{srsIdx}.SRSPeriod(2)];
                    % Check if UL resource is already reserved
                    if ~ismember(ulReservedResource, obj.ULReservedResource, 'rows')
                        idx = idx + 1;
                        obj.ULReservedResource(idx, :) = ulReservedResource;
                    end
                    obj.NumSRSPorts(srsIdx) = param.srsConfig{srsIdx}.NumSRSPorts;
                end
            end

            % Pre-calculate type-1 single panel precoding matrix codebook based on the CSI report configuration
            if isfield(param, 'csirsConfig')
                for idx = 1:length(param.csirsConfig)
                    if ~isa(param.csirsConfig{idx}, 'nrCSIRSConfig')
                        error('nr5g:scheduler:InvalidObjectType', "Each element of 'CSIRSConfig' must be specified as an object of type nrCSIRSConfig")
                    end
                end
                csirsConfig = param.csirsConfig;
                obj.NumCSIRSPorts = csirsConfig{1}.NumCSIRSPorts*ones(numUEs,1);
                % Validate the number of CSI-RS ports for the given gNB antenna
                % configuration
                for csirsIdx = 1:length(csirsConfig)
                    if csirsConfig{csirsIdx}.NumCSIRSPorts > param.gNBTxAnts
                        error('nr5g:scheduler:InvalidCSIRSRowNumber',...
                            'Number of CSI-RS ports (%d) corresponding to CSI-RS row number (%d) must be less than or equal to GNBTxAnts (%d)',...
                            csirsConfig{csirsIdx}.NumCSIRSPorts, csirsConfig{csirsIdx}.RowNumber, param.gNBTxAnts);
                    else
                        obj.NumCSIRSPorts(csirsIdx) = csirsConfig{csirsIdx}.NumCSIRSPorts;
                    end
                end
            else
                csirsConfig = {nrCSIRSConfig};
                csirsConfig{1}.RowNumber = 2; % SISO case
                obj.NumCSIRSPorts = ones(numUEs,1);
            end
            if isfield(param, 'csiReportConfig')
                if length(param.csiReportConfig) == 1
                    % If 'param.CSIReportConfig' is of length 1 then assume
                    % that report config is common for all the UEs
                    param.csiReportConfig(1:numUEs) = param.csiReportConfig(1);
                end
                maxRank = 8;
                obj.Type1SinglePanelCodebook = cell(numUEs, maxRank);
                for idx=1:length(param.csiReportConfig)
                    if isfield(param.csiReportConfig{idx}, 'PanelDimensions') && obj.NumCSIRSPorts(idx) ~= 2*prod(param.csiReportConfig{idx}.PanelDimensions)
                        error('nr5g:scheduler:InvalidPanelDimension',...
                            'Number of CSI-RS ports (%d) as per the CSI-RS row number must match to the number of CSI-RS ports (%d) as per the panel dimensions.',...
                            obj.NumCSIRSPorts(idx), 2*prod(param.csiReportConfig{idx}.PanelDimensions));
                    end
                    if ~isfield(param.csiReportConfig{idx}, 'CodebookSubsetRestriction')
                        param.csiReportConfig{idx}.CodebookSubsetRestriction = [];
                    end
                    if ~isfield(param.csiReportConfig{idx}, 'i2Restriction')
                        param.csiReportConfig{idx}.i2Restriction = [];
                    end
                    param.csiReportConfig{idx}.NStartBWP = 0;
                    param.csiReportConfig{idx}.NSizeBWP = param.numRBs;

                    % Set oversampling factors
                    O1 = 1;
                    O2 = 1;
                    if(obj.NumCSIRSPorts(idx) > 2)
                        % Supported panel configurations and oversampling factors as per
                        % TS 38.214 Table 5.2.2.2.1-2
                        panelConfigs = [2     2     4     3     6     4     8     4     6    12     4     8    16   % N1
                            1     2     1     2     1     2     1     3     2     1     4     2     1   % N2
                            4     4     4     4     4     4     4     4     4     4     4     4     4   % O1
                            1     4     1     4     1     4     1     4     4     1     4     4     1]; % O2
                        configIdx = find(panelConfigs(1,:) == param.csiReportConfig{idx}.PanelDimensions(1) & panelConfigs(2,:) == param.csiReportConfig{idx}.PanelDimensions(2),1);
                        if isempty(configIdx)
                            error('nr5g:scheduler:InvalidPanelDimension',['The given panel configuration ['...
                                num2str(param.csiReportConfig{idx}.PanelDimensions(1)) ' ' num2str(param.csiReportConfig{idx}.PanelDimensions(2)) '] is not valid. '...
                                'For a number of CSI-RS ports, the panel configuration should be one of the possibilities from TS 38.214 Table 5.2.2.2.1-2.']);
                        end
                        % Extract the oversampling factors
                        O1 = panelConfigs(3,configIdx);
                        O2 = panelConfigs(4,configIdx);
                    end
                    param.csiReportConfig{idx}.OverSamplingFactors = [O1 O2];
                    % Get Type-1 single panel codebook
                    if obj.NumCSIRSPorts(idx) > 1
                        % Codebooks for all possible ranks (1-8)
                        for rank = 1:maxRank % For all ranks limited by the CSI-RS port count
                            obj.Type1SinglePanelCodebook{idx, rank}= communication.pmiType1SinglePanelCodebook(param.csiReportConfig{idx}, rank); % Get precoding codebook
                        end
                    end
                end
            end

            % CSI measurements initialization
            obj.CSIMeasurementDL = repmat(struct('RankIndicator', [], 'PMISet', [], 'CQI', []), numUEs, 1);
            obj.CSIMeasurementUL = repmat(struct('RankIndicator', [], 'TPMI', [], 'CQI', []), numUEs, 1);
            initialRank = 1; % Initial ranks for UEs
            for i=1:numUEs
                obj.CSIMeasurementDL(i).RankIndicator = initialRank;
                obj.CSIMeasurementUL(i).RankIndicator = initialRank;
                % Initialize the PMI fields (i11, i12, i13, i2). They get
                % overwritten with reception of CSI report
                if isfield(param, 'csiReportConfig') && isfield(param.csiReportConfig{i}, 'SubbandSize') 
                    numSubbands = ceil(obj.NumPDSCHRBs/param.csiReportConfig{i}.SubbandSize);
                    % Initialize i11, i12, i13, i2 for each UE
                    obj.CSIMeasurementDL(i).PMISet = struct('i1', [1 1 1], 'i2', ones(numSubbands,1));
                else % Wideband PMI
                    obj.CSIMeasurementDL(i).PMISet = struct('i1', [1 1 1], 'i2', 1);
                end
                if ~isfield(param, 'srsSubbandSize')
                    param.srsSubbandSize = 4;
                else
                    validateattributes(param.srsSubbandSize, {'numeric'},...
                        {'scalar', 'integer', '>', 0, '<=', param.numRBs}, 'param.srsSubbandSize', 'srsSubbandSize')
                end
                numSRSSubbands = ceil(obj.NumPUSCHRBs/param.srsSubbandSize);
                obj.CSIMeasurementUL(i).TPMI = zeros(numSRSSubbands,1);
                % Initialize DL and UL channel quality as CQI index 7
                obj.CSIMeasurementDL(i).CQI = 7*ones(1, obj.NumPDSCHRBs);
                obj.CSIMeasurementUL(i).CQI = 7*ones(1, obj.NumPUSCHRBs);
            end
            % Set the MCS tables as matrices
            obj.MCSTableUL = getMCSTableUL(obj);
            obj.MCSTableDL = getMCSTableDL(obj);

            % Create carrier configuration object for UL
            obj.CarrierConfigUL = nrCarrierConfig;
            obj.CarrierConfigUL.SubcarrierSpacing = obj.SCS;
            obj.CarrierConfigUL.NSizeGrid = obj.NumPUSCHRBs;
            % Create carrier configuration object for DL
            obj.CarrierConfigDL = obj.CarrierConfigUL;
            obj.CarrierConfigDL.NSizeGrid = obj.NumPDSCHRBs;

            % Create PUSCH and PDSCH configuration objects and use them to
            % optimize performance
            obj.PUSCHConfig = nrPUSCHConfig;
            obj.PUSCHConfig.DMRS = nrPUSCHDMRSConfig('DMRSConfigurationType', obj.PUSCHDMRSConfigurationType, ...
                        'DMRSTypeAPosition', obj.DMRSTypeAPosition, 'DMRSLength', obj.PUSCHDMRSLength);
            obj.PDSCHConfig = nrPDSCHConfig;
            obj.PDSCHConfig.DMRS = nrPDSCHDMRSConfig('DMRSConfigurationType', obj.PDSCHDMRSConfigurationType, ...
                        'DMRSTypeAPosition', obj.DMRSTypeAPosition, 'DMRSLength', obj.PDSCHDMRSLength);
        end

        function resourceAssignments = runDLScheduler(obj, currentTimeInfo)
            %runDLScheduler Run the DL scheduler
            %
            %   RESOURCEASSIGNMENTS = runDLScheduler(OBJ) runs the DL scheduler
            %   and returns the resource assignments structure array.
            %
            %   CURRENTTIMEINFO is the information passed to scheduler for
            %   scheduling. It is a structure with following fields:
            %       SFN - Current system frame number
            %       CurrSlot - Current slot number
            %       CurrSymbol - Current symbol number
            %
            %   RESOURCEASSIGNMENTS is a structure that contains the
            %   DL resource assignments information.

            % Set current time information before doing the scheduling
            obj.CurrSlot = currentTimeInfo.CurrSlot;
            obj.CurrSymbol = currentTimeInfo.CurrSymbol;
            obj.SFN = currentTimeInfo.SFN;
            if obj.DuplexMode == 1 % TDD
                % Calculate DL-UL slot index in the DL-UL pattern
                obj.CurrDLULSlotIndex = mod(obj.SFN*obj.NumSlotsFrame + obj.CurrSlot, obj.NumDLULPatternSlots);
            end

            % Select the slots to be scheduled and then schedule them
            resourceAssignments = {};
            numDLGrants = 0;
            slotsToBeScheduled = selectDLSlotsToBeScheduled(obj);
            for i=1:length(slotsToBeScheduled)
                % Schedule each selected slot
                slotDLGrants = scheduleDLResourcesSlot(obj, slotsToBeScheduled(i));
                resourceAssignments(numDLGrants + 1 : numDLGrants + length(slotDLGrants)) = slotDLGrants(:);
                numDLGrants = numDLGrants + length(slotDLGrants);
                updateHARQContextDL(obj, slotDLGrants);
            end
        end

        function resourceAssignments = runULScheduler(obj, currentTimeInfo)
            %runULScheduler Run the UL scheduler
            %
            %   RESOURCEASSIGNMENTS = runULScheduler(OBJ) runs the UL scheduler
            %   and returns the resource assignments structure array.
            %
            %   CURRENTTIMEINFO is the information passed to scheduler for
            %   scheduling. It is a structure with following fields:
            %       SFN - Current system frame number
            %       CurrSlot - Current slot number
            %       CurrSymbol - Current symbol number
            %
            %   RESOURCEASSIGNMENTS is a structure that contains the
            %   UL resource assignments information.

            %Set current time information before doing the scheduling
            obj.CurrSlot = currentTimeInfo.CurrSlot;
            obj.CurrSymbol = currentTimeInfo.CurrSymbol;
            obj.SFN = currentTimeInfo.SFN;
            if obj.DuplexMode == 1 % TDD
                % Calculate current DL-UL slot index in the DL-UL pattern
                obj.CurrDLULSlotIndex = mod(obj.SFN*obj.NumSlotsFrame + obj.CurrSlot, obj.NumDLULPatternSlots);
            end

            % Select the slots to be scheduled now and schedule them
            resourceAssignments = {};
            numULGrants = 0;
            slotsToBeSched = selectULSlotsToBeScheduled(obj); % Select the set of slots to be scheduled in this UL scheduler run
            for i=1:length(slotsToBeSched)
                % Schedule each selected slot
                slotULGrants = scheduleULResourcesSlot(obj, slotsToBeSched(i));
                resourceAssignments(numULGrants + 1 : numULGrants + length(slotULGrants)) = slotULGrants(:);
                numULGrants = numULGrants + length(slotULGrants);
                updateHARQContextUL(obj, slotULGrants);
            end

            if obj.DuplexMode == 1 % TDD
                % Update the next to-be-scheduled UL slot. Next UL
                % scheduler run starts assigning resources this slot
                % onwards
                if ~isempty(slotsToBeSched)
                    % If any UL slots are scheduled, set the next
                    % to-be-scheduled UL slot as the next UL slot after
                    % last scheduled UL slot
                    lastSchedULSlot = slotsToBeSched(end);
                    obj.NextULSchedulingSlot = getToBeSchedULSlotNextRun(obj, lastSchedULSlot);
                end
            end
        end

        function updateLCBufferStatusDL(obj, lcBufferStatus)
            %updateLCBufferStatusDL Update DL buffer status for a logical channel of the specified UE
            %
            %   updateLCBufferStatusDL(obj, LCBUFFERSTATUS) updates the
            %   DL buffer status for a logical channel of the specified UE.
            %
            %   LCBUFFERSTATUS is a structure with following three fields.
            %       RNTI - RNTI of the UE
            %       LogicalChannelID - Logical channel ID
            %       BufferStatus - Pending amount in bytes for the specified logical channel of UE

            obj.BufferStatusDL(lcBufferStatus.RNTI, lcBufferStatus.LogicalChannelID) = lcBufferStatus.BufferStatus;
        end

        function processMACControlElement(obj, macCEInfo)
            %processMACControlElement Process the received MAC control element
            %
            %   processMACControlElement(OBJ, MACCEINFO) processes the
            %   received MAC control element (CE). This interface currently
            %   supports buffer status report (BSR) only. MACCEINFO is a
            %   structure with following fields.
            %       RNTI - RNTI of the UE which sent the MAC CE
            %       LCID - Logical channel ID of the MAC CE
            %       Packet - MAC CE

            % Values 59, 60, 61, 62 represents LCIDs corresponding to
            % different BSR formats as per 3GPP TS 38.321
            if(macCEInfo.LCID == 59 || macCEInfo.LCID == 60 || macCEInfo.LCID == 61 || macCEInfo.LCID == 62)
                [lcgIDList, bufferSizeList] = communication.macLayer.macBSRParser(macCEInfo.LCID, macCEInfo.Packet);
                obj.BufferStatusUL(macCEInfo.RNTI, lcgIDList+1) = bufferSizeList;
            end
        end

        function updateChannelQualityUL(obj, channelQualityInfo)
            %updateChannelQualityUL Update uplink channel quality information for a UE
            %   UPDATECHANNELQUALITYUL(OBJ, CHANNELQUALITYINFO) updates
            %   uplink (UL) channel quality information for a UE.
            %   CHANNELQUALITYINFO is a structure with following fields.
            %       RNTI - RNTI of the UE
            %       RankIndicator - Rank indicator for the UE
            %       TPMI - Measured transmitted precoded matrix indicator (TPMI)
            %       CQI - CQI corresponding to RANK and TPMI. It is a
            %       vector of size 'N', where 'N' is number of RBs in UL
            %       bandwidth. Value at index 'i' represents CQI value at
            %       RB-index 'i'

            obj.CSIMeasurementUL(channelQualityInfo.RNTI).CQI = channelQualityInfo.CQI;
            if isfield(channelQualityInfo, 'TPMI')
                obj.CSIMeasurementUL(channelQualityInfo.RNTI).TPMI = channelQualityInfo.TPMI;
            end
            if isfield(channelQualityInfo, 'RankIndicator')
                obj.CSIMeasurementUL(channelQualityInfo.RNTI).RankIndicator = channelQualityInfo.RankIndicator;
            end
        end

        function updateChannelQualityDL(obj, channelQualityInfo)
            %updateChannelQualityDL Update downlink channel quality information for a UE
            %   UPDATECHANNELQUALITYDL(OBJ, CHANNELQUALITYINFO) updates
            %   downlink (DL) channel quality information for a UE.
            %   CHANNELQUALITYINFO is a structure with following fields.
            %       RNTI - RNTI of the UE
            %       RankIndicator - Rank indicator for the UE
            %       PMISet - Precoding matrix indicator. It is a structure with following fields.
            %           i1 - Indicates wideband PMI (1-based). It a three-element vector in the
            %                form of [i11 i12 i13].
            %           i2 - Indicates subband PMI (1-based). It is a vector of length equal to
            %                the number of subbands or number of PRGs.
            %       CQI - CQI corresponding to RANK and TPMI. It is a
            %       vector of size 'N', where 'N' is number of RBs in UL
            %       bandwidth. Value at index 'i' represents CQI value at
            %       RB-index 'i'

            obj.CSIMeasurementDL(channelQualityInfo.RNTI).CQI = channelQualityInfo.CQI;
            if isfield(channelQualityInfo, 'PMISet')
                obj.CSIMeasurementDL(channelQualityInfo.RNTI).PMISet = channelQualityInfo.PMISet;
            end
            if isfield(channelQualityInfo, 'RankIndicator')
                obj.CSIMeasurementDL(channelQualityInfo.RNTI).RankIndicator = channelQualityInfo.RankIndicator;
            end
        end

        function handleDLRxResult(obj, rxResultInfo)
            %handleDLRxResult Update the HARQ process context based on the Rx success/failure for DL packets
            % handleDLRxResult(OBJ, RXRESULTINFO) updates the HARQ
            % process context, based on the ACK/NACK received by gNB for
            % the DL packet.
            %
            % RXRESULTINFO is a structure with following fields.
            %   RNTI - UE that sent the ACK/NACK for its DL reception.
            %
            %   HARQID - HARQ process ID
            %
            %   RxResult - 0 means NACK or no feedback received. 1 means ACK.

            rnti = rxResultInfo.RNTI;
            harqID = rxResultInfo.HARQID;
            if rxResultInfo.RxResult % Rx success
                % Update the DL HARQ process context
                obj.HarqStatusDL{rnti, harqID+1} = []; % Mark the HARQ process as free
                harqProcess = obj.HarqProcessesDL(rnti, harqID+1);
                harqProcess.blkerr(1) = 0;
                obj.HarqProcessesDL(rnti, harqID+1) = harqProcess;

                % Clear the retransmission context for the HARQ
                % process of the UE. It would already be empty if
                % this feedback was not for a retransmission.
                obj.RetransmissionContextDL{rnti, harqID+1}= [];
            else % Rx failure or no feedback received
                harqProcess = obj.HarqProcessesDL(rnti, harqID+1);
                harqProcess.blkerr(1) = 1;
                if harqProcess.RVIdx(1) == length(harqProcess.RVSequence)
                    % Packet reception failed for all redundancy
                    % versions. Mark the HARQ process as free. Also
                    % clear the retransmission context to not allow any
                    % further retransmissions for this packet
                    harqProcess.blkerr(1) = 0;
                    obj.HarqStatusDL{rnti, harqID+1} = []; % Mark the HARQ process as free
                    obj.HarqProcessesDL(rnti, harqID+1) = harqProcess;
                    obj.RetransmissionContextDL{rnti, harqID+1}= [];
                else
                    % Update the retransmission context for the UE
                    % and HARQ process to indicate retransmission
                    % requirement
                    obj.HarqProcessesDL(rnti, harqID+1) = harqProcess;
                    lastDLGrant = obj.HarqStatusDL{rnti, harqID+1};
                    if lastDLGrant.RV == 0 % Only store the original transmission grant's TBS
                        grantRBs = convertRBGBitmapToRBs(obj, lastDLGrant.RBGAllocationBitmap, 0);
                        mcsInfo = obj.MCSTableDL(lastDLGrant.MCS + 1, :);
                        modSchemeBits = mcsInfo(1); % Bits per symbol for modulation scheme
                        modScheme = modSchemeStr(obj, modSchemeBits);
                        codeRate = mcsInfo(2)/1024;
                        % Calculate tbs capability of grant
                        lastTBS = floor(tbsCapability(obj, 0, lastDLGrant.NumLayers, lastDLGrant.MappingType, lastDLGrant.StartSymbol, ...
                            lastDLGrant.NumSymbols, grantRBs, modScheme, codeRate, lastDLGrant.NumCDMGroupsWithoutData)/8);
                        obj.TBSizeDL(rnti, harqID+1) = lastTBS;
                    end
                    obj.RetransmissionContextDL{rnti, harqID+1} = lastDLGrant;
                end
            end
        end

        function handleULRxResult(obj, rxResultInfo)
            %handleULRxResult Update the HARQ process context based on the Rx success/failure for UL packets
            % handleULRxResult(OBJ, RXRESULTINFO) updates the HARQ
            % process context, based on the reception success/failure of
            % UL packets.
            %
            % RXRESULTINFO is a structure with following fields.
            %   RNTI - UE corresponding to the UL packet.
            %
            %   HARQID - HARQ process ID.
            %
            %   RxResult - 0 means Rx failure or no reception. 1 means Rx success.

            rnti = rxResultInfo.RNTI;
            harqID = rxResultInfo.HARQID;
            rxResult = rxResultInfo.RxResult;

            if rxResult % Rx success
                % Update the HARQ process context
                obj.HarqStatusUL{rnti, harqID + 1} = []; % Mark HARQ process as free
                harqProcess = obj.HarqProcessesUL(rnti, harqID + 1);
                harqProcess.blkerr(1) = 0;
                obj.HarqProcessesUL(rnti, harqID+1) = harqProcess;

                % Clear the retransmission context for the HARQ process
                % of the UE. It would already be empty if this
                % reception was not a retransmission.
                obj.RetransmissionContextUL{rnti, harqID+1}= [];
            else % Rx failure or no packet received
                % No packet received (or corrupted) from UE although it
                % was scheduled to send. Store the transmission uplink
                % grant in retransmission context, which will be used
                % while assigning grant for retransmission
                harqProcess = obj.HarqProcessesUL(rnti, harqID+1);
                harqProcess.blkerr(1) = 1;
                if harqProcess.RVIdx(1) == length(harqProcess.RVSequence)
                    % Packet reception failed for all redundancy
                    % versions. Mark the HARQ process as free. Also
                    % clear the retransmission context to not allow any
                    % further retransmissions for this packet
                    harqProcess.blkerr(1) = 0;
                    obj.HarqStatusUL{rnti, harqID+1} = []; % Mark HARQ as free
                    obj.HarqProcessesUL(rnti, harqID+1) = harqProcess;
                    obj.RetransmissionContextUL{rnti, harqID+1}= [];
                else
                    obj.HarqProcessesUL(rnti, harqID+1) = harqProcess;
                    lastULGrant = obj.HarqStatusUL{rnti, harqID+1};
                    if lastULGrant.RV == 0 % Only store the original transmission grant's TBS
                        grantRBs = convertRBGBitmapToRBs(obj, lastULGrant.RBGAllocationBitmap, 1);
                        mcsInfo = obj.MCSTableUL(lastULGrant.MCS + 1, :);
                        modSchemeBits = mcsInfo(1); % Bits per symbol for modulation scheme
                        modScheme = modSchemeStr(obj, modSchemeBits);
                        codeRate = mcsInfo(2)/1024;
                        % Calculate tbs capability of grant
                        lastTBS = floor(tbsCapability(obj, 1, lastULGrant.NumLayers, lastULGrant.MappingType, lastULGrant.StartSymbol, ...
                            lastULGrant.NumSymbols, grantRBs, modScheme, codeRate, lastULGrant.NumCDMGroupsWithoutData)/8);
                        obj.TBSizeUL(rnti, harqID+1) = lastTBS;
                    end
                    obj.RetransmissionContextUL{rnti, harqID+1} = lastULGrant;
                end
            end
        end
        function [selectedUE, mcsIndex] = runSchedulingStrategy(~, schedulerInput)
            %runSchedulingStrategy Implements the round-robin scheduling
            %
            %   [SELECTEDUE, MCSINDEX] = runSchedulingStrategy(~,SCHEDULERINPUT) runs
            %   the round robin algorithm and returns the selected UE for this RBG
            %   (among the eligible ones), along with the suitable MCS index based on
            %   the channel conditions. This function gets called for selecting a UE for
            %   each RBG to be used for new transmission, i.e. once for each of the
            %   remaining RBGs after assignment for retransmissions is completed.
            %
            %   SCHEDULERINPUT structure contains the following fields which scheduler
            %   would use (not necessarily all the information) for selecting the UE to
            %   which RBG would be assigned.
            %
            %       eligibleUEs    -  RNTI of the eligible UEs contending for the RBG
            %       RBGIndex       -  RBG index in the slot which is getting scheduled
            %       slotNum        -  Slot number in the frame whose RBG is getting scheduled
            %       RBGSize        -  RBG Size in terms of number of RBs
            %       cqiRBG         -  Uplink Channel quality on RBG for UEs. This is a
            %                         N-by-P  matrix with uplink CQI values for UEs on
            %                         different RBs of RBG. 'N' is the number of eligible
            %                         UEs and 'P' is the RBG size in RBs
            %       mcsRBG         -  MCS for eligible UEs based on the CQI values of the RBs
            %                         of RBG. This is a N-by-2 matrix where 'N' is number of
            %                         eligible UEs. For each eligible UE it contains, MCS
            %                         index (first column) and efficiency (bits/symbol
            %                         considering both Modulation and Coding scheme)
            %       pastDataRate   -  Served data rate. Vector of N elements containing
            %                         historical served data rate to eligible UEs. 'N' is
            %                         the number of eligible UEs
            %       bufferStatus   -  Buffer-Status of UEs. Vector of N elements where 'N'
            %                         is the number of eligible UEs, containing pending
            %                         buffer status for UEs
            %       ttiDur         -  TTI duration in ms
            %       UEs            -  RNTI of all the UEs (even the non-eligible ones for
            %                         this RBG)
            %       lastSelectedUE - The RNTI of the UE which was assigned the last
            %                        scheduled RBG
            %
            %   SELECTEDUE The UE (among the eligible ones) which gets assigned
            %                   this particular resource block group
            %
            %   MCSINDEX   The suitable MCS index based on the channel conditions

            % Select next UE for scheduling. After the last selected UE, go in
            % sequence and find the first UE which is eligible and with non-zero
            % buffer status
            selectedUE = -1;
            mcsIndex = -1;
            scheduledUE = schedulerInput.lastSelectedUE;
            for i = 1:length(schedulerInput.UEs)
                scheduledUE = mod(scheduledUE, length(schedulerInput.UEs))+1; % Next UE selected in round-robin fashion
                % Selected UE through round-robin strategy must be in eligibility-list
                % and must have something to send, otherwise move to the next UE
                index = find(schedulerInput.eligibleUEs == scheduledUE, 1);
                if(~isempty(index))
                    bufferStatus = schedulerInput.bufferStatus(index);
                    if(bufferStatus > 0) % Check if UE has any data pending
                        % Select the UE and calculate the expected MCS index
                        % for uplink grant, based on the CQI values for the RBs
                        % of this RBG
                        selectedUE = schedulerInput.eligibleUEs(index);
                        mcsIndex = schedulerInput.mcsRBG(index, 1);
                        break;
                    end
                end
            end
        end

    end

    methods (Access = protected)
        function selectedSlots = selectULSlotsToBeScheduled(obj)
            %selectULSlotsToBeScheduled Select UL slots to be scheduled
            % SELECTEDSLOTS = selectULSlotsToBeScheduled(OBJ) selects the
            % slots to be scheduled by UL scheduler in the current run. The
            % time of current scheduler run is inferred from the values of
            % object properties: SFN, CurrSlot and CurrSymbol.
            %
            % SELECTEDSLOTS is the array of slot numbers selected for
            % scheduling in the current invocation of UL scheduler by MAC

            if obj.DuplexMode == 0 % FDD
                selectedSlots = selectULSlotsToBeScheduledFDD(obj);
            else % TDD
                selectedSlots = selectULSlotsToBeScheduledTDD(obj);
            end
        end

        function selectedSlots = selectDLSlotsToBeScheduled(obj)
            %selectDLSlotsToBeScheduled Select DL slots to be scheduled
            % SELECTEDSLOTS = selectDLSlotsToBeScheduled(OBJ) selects the
            % slots to be scheduled by DL scheduler in the current run. The
            % time of current scheduler run is inferred from the values of
            % object properties: SFN, CurrSlot and CurrSymbol.
            %
            % SELECTEDSLOTS is the array of slot numbers selected for
            % scheduling in the current invocation of DL scheduler by MAC

            if obj.DuplexMode == 0 % FDD
                selectedSlots = selectDLSlotsToBeScheduledFDD(obj);
            else % TDD
                selectedSlots = selectDLSlotsToBeScheduledTDD(obj);
            end
        end

        function uplinkGrants = scheduleULResourcesSlot(obj, slotNum)
            %scheduleULResourcesSlot Schedule UL resources of a slot
            %   UPLINKGRANTS = scheduleULResourcesSlot(OBJ, SLOTNUM)
            %   assigns UL resources of the slot, SLOTNUM. Based on the UL
            %   assignment done, it also updates the UL HARQ process
            %   context.
            %
            %   SLOTNUM is the slot number in the 10 ms frame whose UL
            %   resources are getting scheduled. For FDD, all the symbols
            %   can be used for UL. For TDD, the UL resources can stretch
            %   the full slot or might just be limited to few symbols in
            %   the slot.
            %   The time of current scheduler run is inferred
            %   from the value of object properties: SFN, CurrSlot and
            %   CurrSymbol.
            %
            %   UPLINKGRANTS is a cell array where each cell-element
            %   represents an uplink grant and has following fields:
            %
            %       RNTI                Uplink grant is for this UE
            %
            %       Type                Whether assignment is for new transmission ('newTx'),
            %                           retransmission ('reTx')
            %
            %       HARQID              Selected uplink HARQ process ID
            %
            %       RBGAllocationBitmap Frequency-domain resource assignment. A
            %                           bitmap of resource-block-groups of
            %                           the PUSCH bandwidth. Value 1
            %                           indicates RBG is assigned to the UE
            %
            %       StartSymbol         Start symbol of time-domain resources
            %
            %       NumSymbols          Number of symbols allotted in time-domain
            %
            %       SlotOffset          Slot-offset of PUSCH assignment
            %                           w.r.t the current slot
            %
            %       MCS                 Selected modulation and coding scheme index for UE with
            %                           respect to the resource assignment done
            %
            %       NDI                 New data indicator flag
            %
            %       DMRSLength          DM-RS length
            %
            %       MappingType         Mapping type
            %
            %       NumLayers           Number of layers
            %
            %       NumAntennaPorts     Number of antenna ports
            %
            %       TPMI                Transmitted precoding matrix indicator
            %
            %       NumCDMGroupsWithoutData    Number of DM-RS code division multiplexing (CDM) groups without data

            % Calculate offset of the slot to be scheduled, from the current
            % slot
            if slotNum >= obj.CurrSlot  % Slot to be scheduled is in the current frame
                slotOffset = slotNum - obj.CurrSlot;
            else % Slot to be scheduled is in the next frame
                slotOffset = (obj.NumSlotsFrame + slotNum) - obj.CurrSlot;
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
                if (mod(numSlotFrames*obj.SFN + slotNum - reservedResourceInfo(3), reservedResourceInfo(2)) == 0) % SRS slot check
                    reservedSymbol = reservedResourceInfo(1);
                    if (reservedSymbol >= firstULSym) && (reservedSymbol <= firstULSym+numULSym-1)
                        numULSym = reservedSymbol - firstULSym; % Allow PUSCH to only span till the symbol before the SRS symbol
                    end
                    break; % Only 1 symbol for SRS per slot
                end
            end
            if obj.SchedulingType == 0 % Slot based scheduling
                if obj.PUSCHMappingType =='A' && (firstULSym~=0 || numULSym<4)
                    % PUSCH Mapping type A transmissions always start at symbol 0 and
                    % number of symbols must be >=4, as per TS 38.214 - Table 6.1.2.1-1
                    uplinkGrants = [];
                    return;
                end
                % Assignments to span all the symbols in the slot
                uplinkGrants = assignULResourceTTI(obj, slotNum, firstULSym, numULSym);

            else % Symbol based scheduling
                numTTIs = floor(numULSym / obj.TTIGranularity); % UL TTIs in the slot

                % UL grant array with maximum size to store grants
                uplinkGrants = cell((ceil(14/obj.TTIGranularity) * length(obj.UEs)), 1);
                numULGrants = 0;

                % Schedule all UL TTIs in the slot one-by-one
                startSym = firstULSym;
                for i = 1 : numTTIs
                    ttiULGrants = assignULResourceTTI(obj, slotNum, startSym, obj.TTIGranularity);
                    uplinkGrants(numULGrants + 1 : numULGrants + length(ttiULGrants)) = ttiULGrants(:);
                    numULGrants = numULGrants + length(ttiULGrants);
                    startSym = startSym + obj.TTIGranularity;
                end

                remULSym = mod(numULSym, obj.TTIGranularity); % Remaining unscheduled UL symbols
                % Schedule the remaining unscheduled UL symbols
                if remULSym >= 1 % Minimum PUSCH granularity is 1 symbol
                    ttiULGrants = assignULResourceTTI(obj, slotNum, startSym, remULSym);
                    uplinkGrants(numULGrants + 1 : numULGrants + length(ttiULGrants)) = ttiULGrants(:);
                    numULGrants = numULGrants + length(ttiULGrants);
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
            %   The time of current scheduler run is inferred
            %   from the value of object properties: SFN, CurrSlot and
            %   CurrSymbol.
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
            else % Symbol based scheduling
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

               % Schedule all DL TTIs of length 'obj.TTIGranularity' in the slot one-by-one
                startSym = firstDLSym;
                for i = 1 : numTTIs
                    TTIDLGrants = assignDLResourceTTI(obj, slotNum, startSym,  obj.TTIGranularity);
                    downlinkGrants(numDLGrants + 1 : numDLGrants + length(TTIDLGrants)) = TTIDLGrants(:);
                    numDLGrants = numDLGrants + length(TTIDLGrants);
                    startSym = startSym + obj.TTIGranularity;
                end

                remDLSym = mod(numDLSym, obj.TTIGranularity); % Remaining unscheduled DL symbols
                % Schedule the remaining unscheduled DL symbols with
                % granularities lesser than obj.TTIGranularity
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
                        end
                    end
                end
                downlinkGrants = downlinkGrants(1 : numDLGrants);
            end
        end

        function selectedSlots = selectULSlotsToBeScheduledFDD(obj)
            %selectULSlotsToBeScheduledFDD Select the set of slots to be scheduled by UL scheduler (for FDD mode)

            selectedSlots = zeros(obj.NumSlotsFrame, 1);
            numSelectedSlots = 0;
            obj.SlotsSinceSchedulerRunUL = obj.SlotsSinceSchedulerRunUL + 1;
            if obj.SlotsSinceSchedulerRunUL == obj.SchedulerPeriodicity
                % Scheduler periodicity reached. Select the same number of
                % slots as the scheduler periodicity. Offset of slots to be
                % scheduled in this scheduler run must be such that UEs get
                % required PUSCH preparation time
                firstScheduledSlotOffset = max(1, ceil(obj.PUSCHPrepSymDur/14));
                lastScheduledSlotOffset = firstScheduledSlotOffset + obj.SchedulerPeriodicity - 1;
                for slotOffset = firstScheduledSlotOffset:lastScheduledSlotOffset
                    numSelectedSlots = numSelectedSlots+1;
                    slotNum = mod(obj.CurrSlot + slotOffset, obj.NumSlotsFrame);
                    selectedSlots(numSelectedSlots) = slotNum;
                end
                obj.SlotsSinceSchedulerRunUL = 0;
            end
            selectedSlots = selectedSlots(1:numSelectedSlots);
        end

        function selectedSlots = selectDLSlotsToBeScheduledFDD(obj)
            %selectDLSlotsToBeScheduledFDD Select the slots to be scheduled by DL scheduler (for FDD mode)

            selectedSlots = zeros(obj.NumSlotsFrame, 1);
            numSelectedSlots = 0;
            obj.SlotsSinceSchedulerRunDL = obj.SlotsSinceSchedulerRunDL + 1;
            if obj.SlotsSinceSchedulerRunDL == obj.SchedulerPeriodicity
                % Scheduler periodicity reached. Select the slots till the
                % slot when scheduler would run next
                for slotOffset = 1:obj.SchedulerPeriodicity
                    numSelectedSlots = numSelectedSlots+1;
                    slotNum = mod(obj.CurrSlot + slotOffset, obj.NumSlotsFrame);
                    selectedSlots(numSelectedSlots) = slotNum;
                end
                obj.SlotsSinceSchedulerRunDL = 0;
            end
            selectedSlots = selectedSlots(1:numSelectedSlots);
        end

        function selectedSlots = selectULSlotsToBeScheduledTDD(obj)
            %selectULSlotsToBeScheduledTDD Get the set of slots to be scheduled by UL scheduler (for TDD mode)
            % The criterion used here selects all the upcoming slots
            % (including the current one) containing unscheduled UL symbols
            % which must be scheduled now. These slots can be scheduled now
            % but cannot be scheduled in the next slot with DL symbols,
            % based on PUSCH preparation time capability of UEs (It is
            % assumed that all the UEs have same PUSCH preparation
            % capability).

            selectedSlots = zeros(obj.NumSlotsFrame, 1);
            numSlotsSelected = 0;
            % Do the scheduling in the slot starting with DL symbol
            if find(obj.DLULSlotFormat(obj.CurrDLULSlotIndex+1, 1) == obj.DLType, 1)
                % Calculate how far the next DL slot is
                nextDLSlotOffset = 1;
                while nextDLSlotOffset < obj.NumSlotsFrame % Consider only the slots within 10 ms
                    slotIndex = mod(obj.CurrDLULSlotIndex + nextDLSlotOffset, obj.NumDLULPatternSlots);
                    if find(obj.DLULSlotFormat(slotIndex + 1, :) == obj.DLType, 1)
                        break; % Found a slot with DL symbols
                    end
                    nextDLSlotOffset = nextDLSlotOffset + 1;
                end
                nextDLSymOffset = (nextDLSlotOffset * 14); % Convert to number of symbols

                % Calculate how many slots ahead is the next to-be-scheduled
                % slot
                if obj.CurrSlot <= obj.NextULSchedulingSlot
                    % To-be-scheduled slot is in the current frame
                    nextULSchedSlotOffset = obj.NextULSchedulingSlot - obj.CurrSlot;
                else
                    % To-be-scheduled slot is in the next frame
                    nextULSchedSlotOffset = (obj.NumSlotsFrame + obj.NextULSchedulingSlot) - obj.CurrSlot;
                end

                % Start evaluating candidate future slots one-by-one, to check
                % if they must be scheduled now, starting from the slot which
                % is 'nextULSchedSlotOffset' slots ahead
                while nextULSchedSlotOffset < obj.NumSlotsFrame
                    % Get slot index of candidate slot in DL-UL pattern and its
                    % format
                    slotIdxDLULPattern = mod(obj.CurrDLULSlotIndex + nextULSchedSlotOffset, obj.NumDLULPatternSlots);
                    slotFormat = obj.DLULSlotFormat(slotIdxDLULPattern + 1, :);

                    firstULSym = find(slotFormat == obj.ULType, 1, 'first'); % Check for location of first UL symbol in the candidate slot
                    if firstULSym % If slot has any UL symbol
                        nextULSymOffset = (nextULSchedSlotOffset * 14) + firstULSym - 1;
                        if (nextULSymOffset - nextDLSymOffset) < obj.PUSCHPrepSymDur
                            % The UL resources of this candidate slot cannot be
                            % scheduled in the first upcoming slot with DL
                            % symbols. Check if it can be scheduled now. If so,
                            % add it to the list of selected slots
                            if nextULSymOffset >= obj.PUSCHPrepSymDur
                                numSlotsSelected = numSlotsSelected + 1;
                                selectedSlots(numSlotsSelected) = mod(obj.CurrSlot + nextULSchedSlotOffset, obj.NumSlotsFrame);
                            end
                        else
                            % Slots which are 'nextULSchedSlotOffset' or more
                            % slots ahead can be scheduled in next slot with DL
                            % symbols as scheduling there will also be able to
                            % give enough PUSCH preparation time for UEs.
                            break;
                        end
                    end
                    nextULSchedSlotOffset = nextULSchedSlotOffset + 1; % Move to the next slot
                end
            end
            selectedSlots = selectedSlots(1 : numSlotsSelected); % Keep only the selected slots in the array
        end

        function selectedSlots = selectDLSlotsToBeScheduledTDD(obj)
            %selectDLSlotsToBeScheduledTDD Select the slots to be scheduled by DL scheduler (for TDD mode)
            % Return the slot number of next slot with DL resources
            % (symbols). In every run the DL scheduler schedules the next
            % slot with DL symbols.

            selectedSlots = [];
            % Do the scheduling in the slot starting with DL symbol
            if find(obj.DLULSlotFormat(obj.CurrDLULSlotIndex+1, 1) == obj.DLType, 1)
                % Calculate how far the next DL slot is
                nextDLSlotOffset = 1;
                while nextDLSlotOffset < obj.NumSlotsFrame % Consider only the slots within 10 ms
                    slotIndex = mod(obj.CurrDLULSlotIndex + nextDLSlotOffset, obj.NumDLULPatternSlots);
                    if find(obj.DLULSlotFormat(slotIndex + 1, :) == obj.DLType, 1)
                        % Found a slot with DL symbols, calculate the slot
                        % number
                        selectedSlots = mod(obj.CurrSlot + nextDLSlotOffset, obj.NumSlotsFrame);
                        break;
                    end
                    nextDLSlotOffset = nextDLSlotOffset + 1;
                end
            end
        end

        function selectedSlot = getToBeSchedULSlotNextRun(obj, lastSchedULSlot)
            %getToBeSchedULSlotNextRun Get the first slot to be scheduled by UL scheduler in the next run (for TDD mode)
            % Based on the last scheduled UL slot, get the slot number of
            % the next UL slot (which would be scheduled in the next
            % UL scheduler run)

            % Calculate offset of the last scheduled slot
            if lastSchedULSlot >= obj.CurrSlot
                lastSchedULSlotOffset = lastSchedULSlot - obj.CurrSlot;
            else
                lastSchedULSlotOffset = (obj.NumSlotsFrame + lastSchedULSlot) - obj.CurrSlot;
            end

            candidateSlotOffset = lastSchedULSlotOffset + 1;
            % Slot index in DL-UL pattern
            candidateSlotDLULIndex = mod(obj.CurrDLULSlotIndex + candidateSlotOffset, obj.NumDLULPatternSlots);
            while isempty(find(obj.DLULSlotFormat(candidateSlotDLULIndex+1,:) == obj.ULType, 1))
                % Slot does not have UL symbols. Check the next slot
                candidateSlotOffset = candidateSlotOffset + 1;
                candidateSlotDLULIndex = mod(obj.CurrDLULSlotIndex + candidateSlotOffset, obj.NumDLULPatternSlots);
            end
            selectedSlot = mod(obj.CurrSlot + candidateSlotOffset, obj.NumSlotsFrame);
        end

        function ulGrantsTTI = assignULResourceTTI(obj, slotNum, startSym, numSym)
            %assignULResourceTTI Perform the uplink scheduling of a set of contiguous UL symbols representing a TTI, of the specified slot
            % A UE getting retransmission opportunity in the TTI is not
            % eligible for getting resources for new transmission. An
            % uplink assignment can be non-contiguous, scattered over RBGs
            % of the PUSCH bandwidth

            rbgAllocationBitmap = zeros(1, obj.NumRBGsUL);
            % Assignment of resources for retransmissions
            [reTxUEs, rbgAllocationBitmap, reTxULGrants] = scheduleRetransmissionsUL(obj, slotNum, startSym, numSym, rbgAllocationBitmap);
            ulGrantsTTI = reTxULGrants;
            % Assignment of resources for new transmissions, if there
            % are RBGs remaining after retransmissions. UEs which got
            % assigned resources for retransmissions as well as those with
            % no free HARQ process, are not eligible for assignment
            eligibleUEs = getNewTxEligibleUEs(obj, obj.ULType, reTxUEs);
            if any(~rbgAllocationBitmap) && ~isempty(eligibleUEs) % If any RBG is free in the TTI and there are any eligible UEs
                [~, ~, newTxULGrants] = scheduleNewTxUL(obj, slotNum, eligibleUEs, startSym, numSym, rbgAllocationBitmap);
                ulGrantsTTI = [ulGrantsTTI;newTxULGrants];
            end
        end

        function dlGrantsTTI = assignDLResourceTTI(obj, slotNum, startSym, numSym)
            %assignDLResourceTTI Perform the downlink scheduling of a set of contiguous DL symbols representing a TTI, of the specified slot
            % A UE getting retransmission opportunity in the TTI is not
            % eligible for getting resources for new transmission. A
            % downlink assignment can be non-contiguous, scattered over RBGs
            % of the PDSCH bandwidth

            rbgAllocationBitmap = zeros(1, obj.NumRBGsDL);
            % Assignment of resources for retransmissions
            [reTxUEs, rbgAllocationBitmap, reTxDLGrants] = scheduleRetransmissionsDL(obj, slotNum, startSym, numSym, rbgAllocationBitmap);
            dlGrantsTTI = reTxDLGrants;
            % Assignment of resources for new transmissions, if there
            % are RBGs remaining after retransmissions. UEs which got
            % assigned resources for retransmissions as well those with
            % no free HARQ process, are not considered
            eligibleUEs = getNewTxEligibleUEs(obj, obj.DLType, reTxUEs);
            % If any RBG is free in the slot and there are eligible UEs
            if any(~rbgAllocationBitmap) && ~isempty(eligibleUEs)
                [~, ~, newTxDLGrants] = scheduleNewTxDL(obj, slotNum, eligibleUEs, startSym, numSym, rbgAllocationBitmap);
                dlGrantsTTI = [dlGrantsTTI;newTxDLGrants];
            end
        end

        function [reTxUEs, updatedRBGStatus, ULGrants] = scheduleRetransmissionsUL(obj, scheduledSlot, startSym, numSym, rbgOccupancyBitmap)
            %scheduleRetransmissionsUL Assign resources of a set of contiguous UL symbols representing a TTI, of the specified slot for uplink retransmissions
            % Return the uplink assignments to the UEs which are allotted
            % retransmission opportunity and the updated
            % RBG-occupancy-status to convey what all RBGs are used. All
            % UEs are checked if they require retransmission for any of
            % their HARQ processes. If there are multiple such HARQ
            % processes for a UE then one HARQ process is selected randomly
            % among those. All UEs get maximum 1 retransmission opportunity
            % in a TTI

            % Holds updated RBG occupancy status as the RBGs keep getting
            % allotted for retransmissions
            updatedRBGStatus = rbgOccupancyBitmap;

            reTxGrantCount = 0;
            % Store UEs which get retransmission opportunity
            reTxUEs = zeros(length(obj.UEs), 1);
            % Store retransmission UL grants of this TTI
            ULGrants = cell(length(obj.UEs), 1);

            % Create a random permutation of UE RNTIs, to define the order
            % in which UEs would be considered for retransmission
            % assignments for this scheduler run
            reTxAssignmentOrder = randperm(length(obj.UEs));

            % Calculate offset of scheduled slot from the current slot
            if scheduledSlot >= obj.CurrSlot
                slotOffset = scheduledSlot - obj.CurrSlot;
            else
                slotOffset = (obj.NumSlotsFrame + scheduledSlot) - obj.CurrSlot;
            end

            % Consider retransmission requirement of the UEs as per
            % reTxAssignmentOrder
            for i = 1:length(reTxAssignmentOrder)
                reTxContextUE = obj.RetransmissionContextUL(obj.UEs(reTxAssignmentOrder(i)), :);
                failedRxHarqs = find(~cellfun(@isempty,reTxContextUE));
                if ~isempty(failedRxHarqs) % At least one UL HARQ process for UE requires retransmission
                    % Select one HARQ process randomly
                    selectedHarqId = failedRxHarqs(randi(length(failedRxHarqs))) - 1;
                    % Select rank and precoding matrix for the UE
                    [rank, tpmi, numAntennaPorts] = selectRankAndPrecodingMatrixUL(obj, obj.CSIMeasurementUL(reTxAssignmentOrder(i)), obj.NumSRSPorts(reTxAssignmentOrder(i)));
                    % Read the TBS of original grant. Retransmission grant TBS also needs to be
                    % big enough to accommodate the packet.
                    lastTBSBits = obj.TBSizeUL(obj.UEs(reTxAssignmentOrder(i)), selectedHarqId+1)*8; % TBS in bits
                    lastGrant = reTxContextUE{selectedHarqId+1};
                    % Assign resources and MCS for retransmission
                    [isAssigned, allottedRBGBitmap, mcs] = getRetransmissionResources(obj, obj.ULType, reTxAssignmentOrder(i), ...
                        lastTBSBits, updatedRBGStatus, scheduledSlot, startSym, numSym, rank, lastGrant);
                    if isAssigned
                        % Fill the retransmission uplink grant properties
                        grant = struct();
                        grant.RNTI = reTxAssignmentOrder(i);
                        grant.Type = 'reTx';
                        grant.HARQID = selectedHarqId;
                        grant.RBGAllocationBitmap = allottedRBGBitmap;
                        grant.StartSymbol = startSym;
                        grant.NumSymbols = numSym;
                        grant.SlotOffset = slotOffset;
                        grant.MCS = mcs;
                        grant.NDI = obj.HarqNDIUL(reTxAssignmentOrder(i), selectedHarqId+1); % Fill same NDI (for retransmission)
                        grant.DMRSLength = obj.PUSCHDMRSLength;
                        grant.MappingType = obj.PUSCHMappingType;
                        grant.NumLayers = rank;
                        % Set number of CDM groups without data (1...3)
                        if numSym > 1
                            grant.NumCDMGroupsWithoutData = 2;
                        else
                            grant.NumCDMGroupsWithoutData = 1; % To ensure some REs for data
                        end
                        grant.NumAntennaPorts = numAntennaPorts;
                        grantRBs = convertRBGBitmapToRBs(obj, grant.RBGAllocationBitmap, obj.ULType);
                        tpmiRBs = tpmi(grantRBs+1);
                        grant.TPMI = floor(sum(tpmiRBs)/numel(tpmiRBs)); % Taking average of the measured TPMI on grant RBs
                        % Set the RV
                        harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesUL(reTxAssignmentOrder(i), selectedHarqId+1), 1);
                        grant.RV = harqProcess.RVSequence(harqProcess.RVIdx(1));

                        reTxGrantCount = reTxGrantCount+1;
                        reTxUEs(reTxGrantCount) = reTxAssignmentOrder(i);
                        ULGrants{reTxGrantCount} = grant;
                        % Mark the allotted RBGs as occupied.
                        updatedRBGStatus = updatedRBGStatus | allottedRBGBitmap;

                        % Clear the retransmission context for this HARQ
                        % process of the selected UE to make it ineligible
                        % for retransmission assignments (Retransmission
                        % context would again get set, if Rx fails again in
                        % future for this retransmission assignment)
                        obj.RetransmissionContextUL{obj.UEs(reTxAssignmentOrder(i)), selectedHarqId+1} = [];
                    end
                end
            end
            reTxUEs = reTxUEs(1 : reTxGrantCount);
            ULGrants = ULGrants(~cellfun('isempty', ULGrants)); % Remove all empty elements
        end

        function [reTxUEs, updatedRBGStatus, DLGrants] = scheduleRetransmissionsDL(obj, scheduledSlot, startSym, numSym, rbgOccupancyBitmap)
            %scheduleRetransmissionsDL Assign resources of a set of contiguous DL symbols representing a TTI, of the specified slot for downlink retransmissions
            % Return the downlink assignments to the UEs which are
            % allotted retransmission opportunity and the updated
            % RBG-occupancy-status to convey what all RBGs are used. All
            % UEs are checked if they require retransmission for any of
            % their HARQ processes. If there are multiple such HARQ
            % processes for a UE then one HARQ process is selected randomly
            % among those. All UEs get maximum 1 retransmission opportunity
            % in a TTI

            % Holds updated RBG occupancy status as the RBGs keep getting
            % allotted for retransmissions
            updatedRBGStatus = rbgOccupancyBitmap;

            reTxGrantCount = 0;
            % Store UEs which get retransmission opportunity
            reTxUEs = zeros(length(obj.UEs), 1);
            % Store retransmission DL grants of this TTI
            DLGrants = cell(length(obj.UEs), 1);

            % Create a random permutation of UE RNTIs, to define the order
            % in which retransmission assignments would be done for this
            % TTI
            reTxAssignmentOrder = randperm(length(obj.UEs));

            % Calculate offset of currently scheduled slot from the current slot
            if scheduledSlot >= obj.CurrSlot
                slotOffset = scheduledSlot - obj.CurrSlot; % Scheduled slot is in current frame
            else
                slotOffset = (obj.NumSlotsFrame + scheduledSlot) - obj.CurrSlot; % Scheduled slot is in next frame
            end

            % Consider retransmission requirement of the UEs as per
            % reTxAssignmentOrder
            for i = 1:length(reTxAssignmentOrder) % For each UE
                reTxContextUE = obj.RetransmissionContextDL(obj.UEs(reTxAssignmentOrder(i)), :);
                failedRxHarqs = find(~cellfun(@isempty,reTxContextUE));
                if ~isempty(failedRxHarqs) % At least one DL HARQ process for UE requires retransmission
                    % Select rank and precoding matrix for the UE
                    [rank, W] = selectRankAndPrecodingMatrixDL(obj, reTxAssignmentOrder(i), obj.CSIMeasurementDL(reTxAssignmentOrder(i)), obj.NumCSIRSPorts(reTxAssignmentOrder(i)));
                    % Select one HARQ process randomly
                    selectedHarqId = failedRxHarqs(randi(length(failedRxHarqs))) - 1;
                    % Read TBS. Retransmission grant TBS also needs to be
                    % big enough to accommodate the packet
                    lastTBSBits = obj.TBSizeDL(obj.UEs(reTxAssignmentOrder(i)), selectedHarqId+1)*8;
                    lastGrant = reTxContextUE{selectedHarqId+1};
                    % Assign resources and MCS for retransmission
                    [isAssigned, allottedRBGBitmap, mcs] = getRetransmissionResources(obj, obj.DLType, reTxAssignmentOrder(i),  ...
                        lastTBSBits, updatedRBGStatus, scheduledSlot, startSym, numSym, rank, lastGrant);
                    if isAssigned
                        % Fill the retransmission downlink grant properties
                        grant = struct();
                        grant.RNTI = reTxAssignmentOrder(i);
                        grant.Type = 'reTx';
                        grant.HARQID = selectedHarqId;
                        grant.RBGAllocationBitmap = allottedRBGBitmap;
                        grant.StartSymbol = startSym;
                        grant.NumSymbols = numSym;
                        grant.SlotOffset = slotOffset;
                        grant.MCS = mcs;
                        grant.NDI = obj.HarqNDIDL(reTxAssignmentOrder(i), selectedHarqId+1); % Fill same NDI (for retransmission)
                        grant.FeedbackSlotOffset = getPDSCHFeedbackSlotOffset(obj, slotOffset);
                        grant.DMRSLength = obj.PDSCHDMRSLength;
                        grant.MappingType = obj.PDSCHMappingType;
                        grant.NumLayers = rank;
                        grant.PrecodingMatrix = W;
                        grant.NumCDMGroupsWithoutData = 2; % Number of CDM groups without data (1...3)

                        % Set the RV
                        harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesDL(reTxAssignmentOrder(i), selectedHarqId+1), 1);
                        grant.RV = harqProcess.RVSequence(harqProcess.RVIdx(1));

                        reTxGrantCount = reTxGrantCount+1;
                        reTxUEs(reTxGrantCount) = reTxAssignmentOrder(i);
                        DLGrants{reTxGrantCount} = grant;
                        % Mark the allotted RBGs as occupied.
                        updatedRBGStatus = updatedRBGStatus | allottedRBGBitmap;
                        % Clear the retransmission context for this HARQ
                        % process of the selected UE to make it ineligible
                        % for retransmission assignments (Retransmission
                        % context would again get set, if Rx fails again in
                        % future for this retransmission assignment)
                        obj.RetransmissionContextDL{obj.UEs(reTxAssignmentOrder(i)), selectedHarqId+1} = [];
                    end
                end
            end
            reTxUEs = reTxUEs(1 : reTxGrantCount);
            DLGrants = DLGrants(~cellfun('isempty', DLGrants)); % Remove all empty elements
        end

        function [newTxUEs, updatedRBGStatus, ULGrants] = scheduleNewTxUL(obj, scheduledSlot, eligibleUEs, startSym, numSym, rbgOccupancyBitmap)
            %scheduleNewTxUL Assign resources of a set of contiguous UL symbols representing a TTI, of the specified slot for new uplink transmissions
            % Return the uplink assignments, the UEs which are allotted
            % new transmission opportunity and the RBG-occupancy-status to
            % convey what all RBGs are used. Eligible set of UEs are passed
            % as input along with the bitmap of occupancy status of RBGs
            % for the slot getting scheduled. Only RBGs marked as 0 are
            % available for assignment to UEs

            % Stores UEs which get new transmission opportunity
            newTxUEs = zeros(length(eligibleUEs), 1);

            % Stores UL grants of this TTI
            ULGrants = cell(length(eligibleUEs), 1);

            % To store the MCS of all the RBGs allocated to UEs. As PUSCH
            % assignment to a UE must have a single MCS even if multiple
            % RBGs are allotted, average of all the values is taken.
            rbgMCS = -1*ones(length(eligibleUEs), obj.NumRBGsUL);

            % To store allotted RB count to UE in the slot
            allottedRBCount = zeros(length(eligibleUEs), 1);

            % Holds updated RBG occupancy status as the RBGs keep getting
            % allotted for new transmissions
            updatedRBGStatus = rbgOccupancyBitmap;

            % Calculate offset of scheduled slot from the current slot
            if scheduledSlot >= obj.CurrSlot
                slotOffset = scheduledSlot - obj.CurrSlot;
            else
                slotOffset = (obj.NumSlotsFrame + scheduledSlot) - obj.CurrSlot;
            end

            % Select rank and precoding matrix for the eligible UEs
            numEligibleUEs = length(eligibleUEs);
            tpmi = zeros(numEligibleUEs, obj.NumPUSCHRBs); % To store selected precoding matrices for the UEs
            rank = zeros(numEligibleUEs, 1); % To store selected rank for the UEs
            numAntennaPorts = zeros(numEligibleUEs, 1); % To store selected antenna port count for PUSCH
            for i=1:numEligibleUEs
                [rank(i), tpmi(i, :), numAntennaPorts(i)] = selectRankAndPrecodingMatrixUL(obj, obj.CSIMeasurementUL(eligibleUEs(i)), obj.NumSRSPorts(eligibleUEs(i)));
            end

            % For each available RBG, based on the scheduling strategy
            % select the most appropriate UE. Also ensure that the number of
            % RBs allotted to a UE in the slot does not exceed the limit as
            % defined by the class property 'RBAllocationLimit'
            RBGEligibleUEs = eligibleUEs; % To keep track of UEs currently eligible for RBG allocations in this slot
            newTxGrantCount = 0;
            for i = 1:length(rbgOccupancyBitmap)
                % Resource block group is free
                if ~rbgOccupancyBitmap(i)
                    RBGIndex = i-1;
                    schedulerInput = createSchedulerInput(obj, obj.ULType, scheduledSlot, RBGEligibleUEs, rank, RBGIndex, startSym, numSym);
                    % Run the scheduling strategy to select a UE for the RBG and appropriate MCS
                    [selectedUE, mcs] = runSchedulingStrategy(obj, schedulerInput);
                    if selectedUE ~= -1 % If RBG is assigned to any UE
                        updatedRBGStatus(i) = 1; % Mark as assigned
                        obj.LastSelectedUEUL = selectedUE;
                        selectedUEIdx = find(eligibleUEs == selectedUE, 1, 'first'); % Find UE index in eligible UEs set
                        rbgMCS(selectedUEIdx, i) = mcs;
                        if isempty(find(newTxUEs == selectedUE,1))
                            % Selected UE is allotted first RBG in this TTI
                            grant.RNTI = selectedUE;
                            grant.Type = 'newTx';
                            grant.RBGAllocationBitmap = zeros(1, length(rbgOccupancyBitmap));
                            grant.RBGAllocationBitmap(RBGIndex+1) = 1;
                            grant.StartSymbol = startSym;
                            grant.NumSymbols = numSym;
                            grant.SlotOffset = slotOffset;
                            grant.MappingType = obj.PUSCHMappingType;
                            grant.DMRSLength = obj.PUSCHDMRSLength;
                            grant.NumLayers = rank(selectedUEIdx);
                            % Set number of CDM groups without data (1...3)
                            if numSym > 1
                                grant.NumCDMGroupsWithoutData = 2;
                            else
                                grant.NumCDMGroupsWithoutData = 1; % To ensure some REs for data
                            end
                            grant.NumAntennaPorts = numAntennaPorts(selectedUEIdx);

                            newTxGrantCount = newTxGrantCount + 1;
                            newTxUEs(newTxGrantCount) = selectedUE;
                            ULGrants{selectedUEIdx} = grant;
                        else
                            % Add RBG to the UE's grant
                            grant = ULGrants{selectedUEIdx};
                            grant.RBGAllocationBitmap(RBGIndex+1) = 1;
                            ULGrants{selectedUEIdx} = grant;
                        end

                        if RBGIndex < obj.NumRBGsUL-1
                            allottedRBCount(selectedUEIdx) = allottedRBCount(selectedUEIdx) + obj.RBGSizeUL;
                            % Check if the UE which got this RBG remains
                            % eligible for further RBGs in this TTI, as per
                            % set 'RBAllocationLimitUL'.
                            nextRBGSize = obj.RBGSizeUL;
                            if RBGIndex == obj.NumRBGsUL-2 % If next RBG index is the last one in the BWP
                                nextRBGSize = obj.NumPUSCHRBs - ((RBGIndex+1) * obj.RBGSizeUL);
                            end
                            if allottedRBCount(selectedUEIdx) > (obj.RBAllocationLimitUL - nextRBGSize)
                                % Not eligible for next RBG as max RB
                                % allocation limit would get breached
                                RBGEligibleUEs = setdiff(RBGEligibleUEs, selectedUE, 'stable');
                            end
                        end
                    end
                end
            end

            % Calculate a single MCS and TPMI value for the PUSCH assignment to UEs
            % from the MCS values of all the RBGs allotted. Also select a
            % free HARQ process to be used for uplink over the selected
            % RBGs. It was already ensured that UEs in eligibleUEs set have
            % at least one free HARQ process before deeming them eligible
            % for getting resources for new transmission
            for i = 1:length(eligibleUEs)
                % If any resources were assigned to this UE
                if ~isempty(ULGrants{i})
                    grant = ULGrants{i};
                    grant.MCS = obj.MCSForRBGBitmap(rbgMCS(i, :)); % Get a single MCS for all allotted RBGs
                    grantRBs = convertRBGBitmapToRBs(obj, grant.RBGAllocationBitmap, obj.ULType);
                    tpmiRBs = tpmi(i, grantRBs+1);
                    grant.TPMI = floor(sum(tpmiRBs)/numel(tpmiRBs)); % Taking average of the measured TPMI on grant RBs
                    % Select one HARQ process, update its context to reflect
                    % grant
                    selectedHarqId = findFreeUEHarqProcess(obj, obj.ULType, eligibleUEs(i));
                    harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesUL(eligibleUEs(i), selectedHarqId+1), 1);
                    grant.RV = harqProcess.RVSequence(harqProcess.RVIdx(1));

                    grant.HARQID = selectedHarqId; % Fill HARQ id in grant
                    grant.NDI = ~obj.HarqNDIUL(grant.RNTI, selectedHarqId + 1); % Toggle the NDI for new transmission
                    obj.HarqNDIUL(grant.RNTI, selectedHarqId+1) = grant.NDI; % Update the NDI context for the HARQ process
                    obj.HarqStatusUL{eligibleUEs(i), selectedHarqId+1} = grant; % Mark HARQ process as busy
                    ULGrants{i} = grant;
                end
            end
            newTxUEs = newTxUEs(1 : newTxGrantCount);
            ULGrants = ULGrants(~cellfun('isempty',ULGrants)); % Remove all empty elements
        end

        function [newTxUEs, updatedRBGStatus, DLGrants] = scheduleNewTxDL(obj, scheduledSlot, eligibleUEs, startSym, numSym, rbgOccupancyBitmap)
            %scheduleNewTxDL Assign resources of a set of contiguous UL symbols representing a TTI, of the specified slot for new downlink transmissions
            % Return the downlink assignments for the UEs which are allotted
            % new transmission opportunity and the RBG-occupancy-status to
            % convey what all RBGs are used. Eligible set of UEs are passed
            % as input along with the bitmap of occupancy status of RBGs
            % of the slot getting scheduled. Only RBGs marked as 0 are
            % available for assignment to UEs

            % Stores UEs which get new transmission opportunity
            newTxUEs = zeros(length(eligibleUEs), 1);

            % Stores DL grants of the TTI
            DLGrants = cell(length(eligibleUEs), 1);

            % To store the MCS of all the RBGs allocated to UEs. As PDSCH
            % assignment to a UE must have a single MCS even if multiple
            % RBGs are allotted, average of all the values is taken
            rbgMCS = -1*ones(length(eligibleUEs), obj.NumRBGsDL);

            % To store allotted RB count to UE in the slot
            allottedRBCount = zeros(length(eligibleUEs), 1);

            % Holds updated RBG occupancy status as the RBGs keep getting
            % allotted for new transmissions
            updatedRBGStatus = rbgOccupancyBitmap;

            % Calculate offset of scheduled slot from the current slot
            if scheduledSlot >= obj.CurrSlot
                slotOffset = scheduledSlot - obj.CurrSlot;
            else
                slotOffset = (obj.NumSlotsFrame + scheduledSlot) - obj.CurrSlot;
            end

            % Select rank and precoding matrix for the eligible UEs
            numEligibleUEs = length(eligibleUEs);
            W = cell(numEligibleUEs, 1); % To store selected precoding matrices for the UEs
            rank = zeros(numEligibleUEs, 1); % To store selected rank for the UEs
            for i=1:numEligibleUEs
                [rank(i), W{i}] = selectRankAndPrecodingMatrixDL(obj, eligibleUEs(i), obj.CSIMeasurementDL(eligibleUEs(i)), ...
                    obj.NumCSIRSPorts(eligibleUEs(i)));
            end

            % For each available RBG, based on the scheduling strategy
            % select the most appropriate UE. Also ensure that the number of
            % RBs allotted for a UE in the slot does not exceed the limit as
            % defined by the class property 'RBAllocationLimitDL'
            RBGEligibleUEs = eligibleUEs; % To keep track of UEs currently eligible for RBG allocations in this slot
            newTxGrantCount = 0;
            for i = 1:length(rbgOccupancyBitmap)
                % Resource block group is free
                if ~rbgOccupancyBitmap(i)
                    RBGIndex = i-1;
                    schedulerInput = createSchedulerInput(obj, obj.DLType, scheduledSlot, RBGEligibleUEs, rank, RBGIndex, startSym, numSym);
                    % Run the scheduling strategy to select a UE for the RBG and appropriate MCS
                    [selectedUE, mcs] = runSchedulingStrategy(obj, schedulerInput);
                    if selectedUE ~= -1 % If RBG is assigned to any UE
                        updatedRBGStatus(i) = 1; % Mark as assigned
                        obj.LastSelectedUEDL = selectedUE;
                        selectedUEIdx = find(eligibleUEs == selectedUE, 1, 'first'); % Find UE index in eligible UEs set
                        rbgMCS(selectedUEIdx, i) = mcs;
                        if isempty(find(newTxUEs == selectedUE,1))
                            % Selected UE is allotted first RBG in this TTI
                            grant.RNTI = selectedUE;
                            grant.Type = 'newTx';
                            grant.RBGAllocationBitmap = zeros(1, length(rbgOccupancyBitmap));
                            grant.RBGAllocationBitmap(RBGIndex+1) = 1;
                            grant.StartSymbol = startSym;
                            grant.NumSymbols = numSym;
                            grant.SlotOffset = slotOffset;
                            grant.FeedbackSlotOffset = getPDSCHFeedbackSlotOffset(obj, slotOffset);
                            grant.MappingType = obj.PDSCHMappingType;
                            grant.DMRSLength = obj.PDSCHDMRSLength;
                            grant.NumLayers = rank(selectedUEIdx);
                            grant.PrecodingMatrix = W{selectedUEIdx};
                            grant.NumCDMGroupsWithoutData = 2; % Number of CDM groups without data (1...3)

                            newTxGrantCount = newTxGrantCount + 1;
                            newTxUEs(newTxGrantCount) = selectedUE;
                            DLGrants{selectedUEIdx} = grant;
                        else
                            % Add RBG to the UE's grant
                            grant = DLGrants{selectedUEIdx};
                            grant.RBGAllocationBitmap(RBGIndex+1) = 1;
                            DLGrants{selectedUEIdx} = grant;
                        end
                        if RBGIndex < obj.NumRBGsDL-1
                            allottedRBCount(selectedUEIdx) = allottedRBCount(selectedUEIdx) + obj.RBGSizeDL;
                            % Check if the UE which got this RBG remains
                            % eligible for further RBGs in this TTI, as per
                            % set 'RBAllocationLimitDL'.
                            nextRBGSize = obj.RBGSizeDL;
                            if RBGIndex == obj.NumRBGsDL-2 % If next RBG index is the last one in BWP
                                nextRBGSize = obj.NumPDSCHRBs - ((RBGIndex+1) * obj.RBGSizeDL);
                            end
                            if allottedRBCount(selectedUEIdx) > (obj.RBAllocationLimitDL - nextRBGSize)
                                % Not eligible for next RBG as max RB
                                % allocation limit would get breached
                                RBGEligibleUEs = setdiff(RBGEligibleUEs, selectedUE, 'stable');
                            end
                        end
                    end
                end
            end

            % Calculate a single MCS value for the PDSCH assignment to UEs
            % from the MCS values of all the RBGs allotted. Also select a
            % free HARQ process to be used for downlink over the selected
            % RBGs. It was already ensured that UEs in eligibleUEs set have
            % at least one free HARQ process before deeming them eligible
            % for getting resources for new transmission
            for i = 1:length(eligibleUEs)
                % If any resources were assigned to this UE
                if ~isempty(DLGrants{i})
                    grant = DLGrants{i};
                    grant.MCS = obj.MCSForRBGBitmap(rbgMCS(i, :)); % Get a single MCS for all allotted RBGs
                    % Select one HARQ process, update its context to reflect
                    % grant
                    selectedHarqId = findFreeUEHarqProcess(obj, obj.DLType, eligibleUEs(i));
                    harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesDL(eligibleUEs(i), selectedHarqId+1), 1);
                    grant.RV = harqProcess.RVSequence(harqProcess.RVIdx(1));
                    grant.HARQID = selectedHarqId; % Fill HARQ ID
                    grant.NDI = ~obj.HarqNDIDL(grant.RNTI, selectedHarqId+1); % Toggle the NDI for new transmission
                    obj.HarqStatusDL{eligibleUEs(i), selectedHarqId+1} = grant; % Mark HARQ process as busy
                    DLGrants{i} = grant;
                end
            end
            newTxUEs = newTxUEs(1 : newTxGrantCount);
            DLGrants = DLGrants(~cellfun('isempty',DLGrants)); % Remove all empty elements
        end

        function k1 = getPDSCHFeedbackSlotOffset(obj, PDSCHSlotOffset)
            %getPDSCHFeedbackSlotOffset Calculate k1 i.e. slot offset of feedback (ACK/NACK) transmission from the PDSCH transmission slot

            % PDSCH feedback is currently supported to be sent with
            % at least 1 slot gap after Tx slot i.e k1=2 is the earliest
            % possible value, subjected to the UL time availability. For
            % FDD, k1 is set as 2 as every slot is a UL slot. For TDD, k1
            % is set to slot offset of first upcoming slot with UL symbols.
            % Input 'PDSCHSlotOffset' is the slot offset of PDSCH
            % transmission slot from the current slot
            if obj.DuplexMode == 0 % FDD
                k1 = 2;
            else % TDD
                % Calculate offset of first slot containing UL symbols, from PDSCH transmission slot
                k1 = 2;
                while(k1 < obj.NumSlotsFrame)
                    slotIndex = mod(obj.CurrDLULSlotIndex + PDSCHSlotOffset + k1, obj.NumDLULPatternSlots);
                    if find(obj.DLULSlotFormat(slotIndex + 1, :) == obj.ULType, 1)
                        break; % Found a slot with UL symbols
                    end
                    k1 = k1 + 1;
                end
            end
        end

        function schedulerInput = createSchedulerInput(obj, linkDir, slotNum, eligibleUEs, selectedRank, rbgIndex, startSym, numSym)
            %createSchedulerInput Create the input structure for scheduling strategy
            %
            % linkDir       - Link direction for scheduler (0 means DL and 1
            %                   means UL)
            % slotNum       - Slot whose TTI is currently getting scheduled
            %
            % eligibleUEs   - RNTI of the eligible UEs contending for the RBG
            %
            % selectedRank  - Selected rank for UEs. It is an array of size eligibleUEs
            %
            % rbgIndex      - Index of the RBG (which is getting scheduled) in the bandwidth
            %
            % startSym      - Start symbol of the TTI getting scheduled
            %
            % numSym        - Number of symbols in the TTI getting scheduled
            %
            % schedulerInput structure contains the following fields which
            % scheduler uses (not necessarily all the information) for
            % selecting the UE, which RBG would be assigned to:
            %
            %   eligibleUEs: RNTI of the eligible UEs contending for the RBG
            %
            %   selectedRank  - Selected rank for UEs. It is an array of size eligibleUEs
            %
            %   RBGIndex: RBG index in the slot which is getting scheduled
            %
            %   slotNum: Slot whose TTI is currently getting scheduled
            %
            %   startSym: Start symbol of TTI
            %
            %   numSym: Number of symbols in TTI
            %
            %   RBGSize: RBG Size in terms of number of RBs
            %
            %   cqiRBG: Channel quality on RBG for UEs. N-by-P matrix with CQI
            %   values for UEs on different RBs of RBG. 'N' is number of
            %   eligible UEs and 'P' is RBG size in RBs
            %
            %   mcsRBG: MCS for eligible UEs based on the CQI values on the RBs of RBG.
            %   N-by-2 matrix where 'N' is number of eligible UEs. For each eligible
            %   UE, it has MCS index (first column) and efficiency (bits/symbol considering
            %   both Modulation and coding scheme)
            %
            %   bufferStatus: Buffer status of UEs. Vector of N elements where 'N'
            %   is number of eligible UEs, containing pending buffer status for UEs
            %
            %   ttiDur: TTI duration in ms
            %
            %   UEs: RNTI of all the UEs (even the non-eligible ones for this RBG)
            %
            %   lastSelectedUE: The RNTI of UE which was assigned the last scheduled RBG

            schedulerInput = obj.SchedulerInput;
            if linkDir % Uplink
                numRBs = obj.NumPUSCHRBs;
                rbgSize = obj.RBGSizeUL;
                ueBufferStatus = obj.BufferStatusUL;
                channelQuality = zeros(length(obj.UEs), obj.NumPUSCHRBs);
                for i = 1:length(eligibleUEs)
                    channelQuality(eligibleUEs(i), :) = obj.CSIMeasurementUL(eligibleUEs(i)).CQI;
                end
                mcsTable = obj.MCSTableUL;
                schedulerInput.lastSelectedUE = obj.LastSelectedUEUL;
            else % Downlink
                numRBs = obj.NumPDSCHRBs;
                rbgSize = obj.RBGSizeDL;
                ueBufferStatus = obj.BufferStatusDL;
                channelQuality = zeros(length(obj.UEs), obj.NumPDSCHRBs);
                for i = 1:length(eligibleUEs)
                    channelQuality(eligibleUEs(i), :) = obj.CSIMeasurementDL(eligibleUEs(i)).CQI;
                end
                mcsTable = obj.MCSTableDL;
                schedulerInput.lastSelectedUE = obj.LastSelectedUEDL;
            end
            schedulerInput.LinkDir = linkDir;
            startRBIndex = rbgSize * rbgIndex;
            % Last RBG can have lesser RBs as number of RBs might not
            % be completely divisible by RBG size
            lastRBIndex = min(startRBIndex + rbgSize - 1, numRBs - 1);
            schedulerInput.eligibleUEs = eligibleUEs;
            schedulerInput.slotNum = slotNum;
            schedulerInput.startSym = startSym;
            schedulerInput.numSym = numSym;
            schedulerInput.RBGIndex = rbgIndex;
            schedulerInput.RBGSize = lastRBIndex - startRBIndex + 1; % Number of RBs in this RBG
            schedulerInput.bufferStatus = sum(ueBufferStatus(eligibleUEs, :), 2);
            schedulerInput.cqiRBG = channelQuality(eligibleUEs, startRBIndex+1 : lastRBIndex+1);
            cqiSetRBG = floor(sum(schedulerInput.cqiRBG, 2)/size(schedulerInput.cqiRBG, 2));
            schedulerInput.mcsRBG = zeros(numel(eligibleUEs), 2);
            for i = 1:numel(eligibleUEs)
                mcsRBG = getMCSIndex(obj, cqiSetRBG(i));

                schedulerInput.mcsRBG(i, 1) = mcsRBG; % MCS value
                schedulerInput.mcsRBG(i, 2) = mcsTable(mcsRBG + 1, 3); % Spectral efficiency
            end
            schedulerInput.ttiDur = (numSym * obj.SlotDuration)/14; % In ms
            schedulerInput.UEs = obj.UEs;
            schedulerInput.selectedRank = selectedRank;
        end

        function harqId = findFreeUEHarqProcess(obj, linkDir, rnti)
            %findFreeUEHarqProcess Returns index of a free uplink or downlink HARQ process of UE, based on the link direction (UL/DL)

            harqId = -1;
            numHarq = obj.NumHARQ;
            if linkDir % Uplink
                harqProcessInfo = obj.HarqStatusUL(rnti, :);
            else % Downlink
                harqProcessInfo = obj.HarqStatusDL(rnti, :);
            end
            for i = 1:numHarq
                harqStatus = harqProcessInfo{i};
                if isempty(harqStatus) % Free process
                    harqId = i-1;
                    return;
                end
            end
        end

        function eligibleUEs = getNewTxEligibleUEs(obj, linkDir, reTxUEs)
            %getNewTxEligibleUEs Return the UEs eligible for getting resources for new transmission
            % Out of all the UEs, the UEs which did not get retransmission
            % opportunity in the current TTI and have at least one free
            % HARQ process are considered eligible for getting resources
            % for new UL (linkDir = 1) or DL (linkDir = 0)
            % opportunity

            noReTxUEs = setdiff(obj.UEs, reTxUEs, 'stable'); % UEs which did not get any re-Tx opportunity
            eligibleUEs = noReTxUEs;
            % Eliminate further the UEs which do not have free HARQ process
            for i = 1:length(noReTxUEs)
                freeHarqId = findFreeUEHarqProcess(obj, linkDir, noReTxUEs(i));
                if freeHarqId == -1
                    % No HARQ process free on this UE, so not eligible.
                    eligibleUEs = setdiff(eligibleUEs, noReTxUEs(i), 'stable');
                end
            end
        end

        function [isAssigned, allottedBitmap, mcs] = getRetransmissionResources(obj, linkDir, rnti, ...
                tbs, rbgOccupancyBitmap, ~, startSym, numSym, rank, lastGrant)
            %getRetransmissionResources Based on the tbs, get the retransmission resources
            % A set of RBGs are chosen for retransmission grant along with
            % the corresponding MCS. The approach used is to find the set
            % of RBGs (which are free) with best channel quality w.r.t UE,
            % to increase the successful reception probability
            cdmGroupsWithoutData = 2;
            if linkDir % Uplink
                cqiRBs = obj.CSIMeasurementUL(rnti).CQI;
                cqiRBGs = zeros(obj.NumRBGsUL, 1);
                numRBGs = obj.NumRBGsUL;
                allottedBitmap = zeros(1, numRBGs);
                RBGSize = obj.RBGSizeUL;
                numRBs = obj.NumPUSCHRBs;
                mcsTable = obj.MCSTableUL;
                mappingType = obj.PUSCHMappingType;
                if numSym == 1
                    cdmGroupsWithoutData = 1;
                end
            else % Downlink
                cqiRBs = obj.CSIMeasurementDL(rnti).CQI;
                cqiRBGs = zeros(obj.NumRBGsDL, 1);
                allottedBitmap = zeros(1, obj.NumRBGsDL);
                numRBGs = obj.NumRBGsDL;
                RBGSize = obj.RBGSizeDL;
                numRBs = obj.NumPDSCHRBs;
                mcsTable = obj.MCSTableDL;
                mappingType = obj.PDSCHMappingType;
            end

            isAssigned = 0;
            mcs = 0;
            % Calculate average CQI for each RBG
            for i = 1:numRBGs
                if ~rbgOccupancyBitmap(i)
                    startRBIndex = (i-1)*RBGSize + 1;
                    lastRBIndex = min(i*RBGSize, numRBs);
                    cqiForRBs = cqiRBs(startRBIndex : lastRBIndex);
                    cqiRBGs(i) = floor(sum(cqiForRBs)/numel(cqiForRBs));
                end
            end

            % Get the indices of RBGs in decreasing order of their CQI
            % values. Then start assigning the RBGs in this order, if the
            % RBG is free to use. Continue assigning the RBGs till the tbs
            % requirement is satisfied.
            [~, sortedIndices] = sort(cqiRBGs, 'descend');
            requiredBits = tbs;
            mcsRBGs = -1*ones(numRBGs, 1);
            % Get number of PDSCH/PUSCH REs per PRB
            [~, nREPerPRB] = tbsCapability(obj, linkDir, rank, mappingType, startSym, ...
                numSym, 1, 'QPSK', mcsTable(1,2)/1024, cdmGroupsWithoutData);
            for i = 1:numRBGs
                if ~rbgOccupancyBitmap(sortedIndices(i)) % Free RBG
                    % Calculate transport block bits capability of RBG
                    cqiRBG = cqiRBGs(sortedIndices(i));
                    mcsIndex = getMCSIndex(obj, cqiRBG);
                    mcsInfo = mcsTable(mcsIndex + 1, :);
                    numRBsRBG = RBGSize;
                    if sortedIndices(i) == numRBGs && mod(numRBs, RBGSize) ~= 0
                        % Last RBG might have lesser number of RBs
                        numRBsRBG = mod(numRBs, RBGSize);
                    end
                    servedBits = rank*nREPerPRB*numRBsRBG*mcsInfo(3); % Approximate TBS bits served by current RBG
                    requiredBits = max(0, requiredBits - servedBits);
                    allottedBitmap(sortedIndices(i)) = 1; % Selected RBG
                    mcsRBGs(sortedIndices(i)) = mcsIndex; % MCS for RBG
                    if ~requiredBits
                        % Retransmission TBS requirement have met
                        isAssigned = 1;
                        rbgMCS = mcsRBGs(mcsRBGs>=0);
                        mcs = floor(sum(rbgMCS)/numel(rbgMCS)); % Average MCS
                        break;
                    end
                end
            end

            % Although TBS requirement is fulfilled by RBG set with
            % corresponding MCS values calculated above but as the
            % retransmission grant needs to have a single MCS, so average
            % MCS of selected RBGs might bring down the tbs capability of
            % grant below the required tbs. If that happens, select the
            % biggest of the MCS values to satisfy the TBS requirement
            if isAssigned
                grantRBs = convertRBGBitmapToRBs(obj, allottedBitmap, linkDir);
                mcsInfo = mcsTable(mcs + 1, :);
                modSchemeBits = mcsInfo(1); % Bits per symbol for modulation scheme
                modScheme = modSchemeStr(obj, modSchemeBits);
                codeRate = mcsInfo(2)/1024;
                % Calculate tbs capability of grant
                actualServedBits = tbsCapability(obj, linkDir, rank, mappingType, startSym, ...
                        numSym, grantRBs, modScheme, codeRate, cdmGroupsWithoutData);
                if actualServedBits < tbs
                    % Average MCS is not sufficing, so taking the maximum MCS
                    % value
                    mcs = max(mcsRBGs);
                end
            else
                if all(allottedBitmap)
                    % Even if giving all the RBGs for retransmission grant
                    % is not sufficing then force the retransmission by
                    % sending the reTx with same MCS as last Tx
                    isAssigned = 1;
                    mcs = lastGrant.MCS;
                    if rank >= lastGrant.NumLayers % If rank of reTx is same then assign same set of RBGs
                        allottedBitmap = lastGrant.RBGAllocationBitmap;
                    else % To compensate for lesser rank, use all the RBGs
                        allottedBitmap = ones(length(rbgOccupancyBitmap), 1);
                    end
                end
            end
        end

        function CQITable = getCQITableDL(~)
            %getCQITableDL Returns the CQI table as per TS 38.214 - Table
            %5.2.2.1-3

            CQITable = [0  0   0
                2 	78      0.1523
                2 	193 	0.3770
                2 	449 	0.8770
                4 	378 	1.4766
                4 	490 	1.9141
                4 	616 	2.4063
                6 	466 	2.7305
                6 	567 	3.3223
                6 	666 	3.9023
                6 	772 	4.5234
                6 	873 	5.1152
                8 	711 	5.5547
                8 	797 	6.2266
                8 	885 	6.9141
                8 	948 	7.4063];
        end

        function CQITable = getCQITableUL(~)
            %getCQITableUL Return the CQI table as per TS 38.214 - Table
            %5.2.2.1-3. As uplink channel quality is assumed in terms of CQIs,
            %using the same table as DL CQI table in 3GPP standard.

            CQITable = [0  0   0
                2 	78      0.1523
                2 	193 	0.3770
                2 	449 	0.8770
                4 	378 	1.4766
                4 	490 	1.9141
                4 	616 	2.4063
                6 	466 	2.7305
                6 	567 	3.3223
                6 	666 	3.9023
                6 	772 	4.5234
                6 	873 	5.1152
                8 	711 	5.5547
                8 	797 	6.2266
                8 	885 	6.9141
                8 	948 	7.4063];
        end

        function mcs = MCSForRBGBitmap(~, mcsValues)
            %MCSForRBGBitmap Calculates and returns single MCS value for the PUSCH assignment to a UE from the MCS values of all the RBGs allotted

            % Taking average of all the MCS values to reach the final MCS
            % value. This is just one way of doing it, it can be deduced
            % in any other way too
            validMCSValues = mcsValues(mcsValues>=0);
            mcs = floor(sum(validMCSValues)/numel(validMCSValues));
        end

        function [rank, W] = selectRankAndPrecodingMatrixDL(obj, rnti, csiReport, numCSIRSPorts)
            %selectRankAndPrecodingMatrixDL Select rank and precoding matrix based on the CSI report from the UE
            %   [RANK, W] = selectRankAndPrecodingMatrixDL(OBJ, RNTI,
            %   CSIREPORT, NUMCSIRSPORTS) selects the rank and precoding
            %   matrix for a UE.
            %
            %   RNTI - RNTI of the UE
            %
            %   CSIREPORT is the channel state information report. It is a
            %   structure with the fields: RankIndicator, PMISet, CQI
            %
            %   RANK is the selected rank i.e. the number of transmission
            %   layers
            %
            %   NUMCSIRSPORTS is number of CSI-RS ports for the UE
            %
            %   W is an array of size RANK-by-P-by-NPRG, where NPRG is the
            %   number of PRGs in the carrier and P is the number of CSI-RS
            %   ports. W defines a different precoding matrix of size
            %   RANK-by-P for each PRG. The effective PRG bundle size
            %   (precoder granularity) is Pd_BWP = ceil(NRB / NPRG). Valid
            %   PRG bundle sizes are given in TS 38.214 Section 5.1.2.3, and
            %   the corresponding values of NPRG, are as follows:
            %   Pd_BWP = 2 (NPRG = ceil(NRB / 2))
            %   Pd_BWP = 4 (NPRG = ceil(NRB / 4))
            %   Pd_BWP = 'wideband' (NPRG = 1)
            %
            % Rank selection procedure followed: Select the advised rank in the CSI report
            % Precoder selection procedure followed: Form the combined precoding matrix for
            % all the PRGs in accordance with the CSI report.
            %
            % The function can be modified to return rank and precoding
            % matrix of choice.

            rank = csiReport.RankIndicator;
            if numCSIRSPorts == 1
                % Single antenna port
                W = 1;
            else
                codebook = obj.Type1SinglePanelCodebook{rnti, rank};
                numSubbands = length(csiReport.PMISet.i2);
                subBandSize = ceil(obj.NumPDSCHRBs/numSubbands);
                numPRGs =  ceil(obj.NumPDSCHRBs/obj.PrecodingGranularity);
                prgInSubband = ceil(subBandSize/obj.PrecodingGranularity); % Number of PRGs in subband
                rbLastSubband = obj.NumPDSCHRBs - (numSubbands-1)*subBandSize;
                prgLastSubband = ceil(rbLastSubband/obj.PrecodingGranularity);
                W = complex(zeros(rank, numCSIRSPorts, numPRGs));

                % Populate W for each subband except the last one
                for k = 1:numSubbands-1
                    for m = 1:prgInSubband
                        % Fill same precoding matrix for PRGs in a subband
                        W(:, :, prgInSubband*(k-1)+m) = codebook(:, :, csiReport.PMISet.i2(k), ...
                            csiReport.PMISet.i1(1), csiReport.PMISet.i1(2), csiReport.PMISet.i1(3)).';
                    end
                end

                % Populate W for last subband
                for m = 1:prgLastSubband
                    % Fill same precoding matrix for PRGs in the last subband
                    W(:, :, prgInSubband*(numSubbands-1)+m) = codebook(:, :, csiReport.PMISet.i2(end), ...
                        csiReport.PMISet.i1(1), csiReport.PMISet.i1(2), csiReport.PMISet.i1(3)).';
                end
            end
        end

        function [rank, tpmi, numAntennaPorts] = selectRankAndPrecodingMatrixUL(obj, csiReport, numSRSPorts)
            %selectRankAndPrecodingMatrixUL Select rank and precoding matrix based on the UL CSI measurement for the UE
            %   [RANK, TPMI, NumAntennaPorts] = selectRankAndPrecodingMatrixUL(OBJ, CSIREPORT, NUMSRSPORTS)
            %   selects the rank and precoding matrix for a UE.
            %
            %   CSIREPORT is the SRS-based channel state information measurement for the UE. It is a
            %   structure with the fields: RankIndicator, TPMI, CQI
            %
            %   NUMSRSPORTS Number of SRS ports used for CSI measurement
            %
            %   RANK is the selected rank i.e. the number of transmission
            %   layers
            %
            %   TPMI is transmitted precoding matrix indicator over the
            %   RBs of the bandwidth.
            %
            %   NUMANTENNAPORTS Number of antenna ports selected for the UE
            %
            % Rank selection procedure followed: Select the advised rank as
            % per the CSI measurement
            % Precoder selection procedure followed: Select the advised TPMI as
            % per the CSI measurement
            %
            % The function can be modified to return rank and precoding
            % matrix of choice.

            rank = csiReport.RankIndicator;
            % Fill the TPMI for each RB by keeping same value of TPMI for all
            % the RBs in the CSI subband
            tpmi = zeros(1, obj.NumPUSCHRBs);
            numSubbands = length(csiReport.TPMI);
            subbandSize = ceil(obj.NumPUSCHRBs/numSubbands);
            for i = 1:numSubbands-1
                tpmi((i-1)*subbandSize+1 : i*subbandSize) = csiReport.TPMI(i);
            end
            tpmi((numSubbands-1)*subbandSize+1:end) = csiReport.TPMI(end);
            numAntennaPorts = numSRSPorts;
        end

        function mcsRowIndex = getMCSIndex(obj, cqiIndex)
            %getMCSIndex Returns the MCS row index based on cqiIndex

            modulation = obj.CQITableUL(cqiIndex + 1, 1);
            codeRate = obj.CQITableUL(cqiIndex + 1, 2);

            for mcsRowIndex = 1:28 % MCS indices
                if modulation ~= obj.MCSTableUL(mcsRowIndex, 1)
                    continue;
                end
                if codeRate <= obj.MCSTableUL(mcsRowIndex, 2)
                    break;
                end
            end
            mcsRowIndex = mcsRowIndex - 1;
        end

        function RBSet = convertRBGBitmapToRBs(obj, rbgBitmap, linkType)
            %convertRBGBitmapToRBs Convert RBGBitmap to corresponding RB indices

            if linkType % Uplink
                rbgSize = obj.RBGSizeUL;
                numRBs = obj.NumPUSCHRBs;
            else % Downlink
                rbgSize = obj.RBGSizeDL;
                numRBs = obj.NumPDSCHRBs;
            end
            RBSet = -1*ones(numRBs, 1); % To store RB indices of last UL grant
            for rbgIndex = 0:length(rbgBitmap)-1
                if rbgBitmap(rbgIndex+1)
                    % If the last RBG of BWP is assigned, then it
                    % might not have the same number of RBs as other RBG.
                    if rbgIndex == (length(rbgBitmap)-1)
                        RBSet((rbgSize*rbgIndex + 1) : end) = ...
                            rbgSize*rbgIndex : numRBs-1 ;
                    else
                        RBSet((rbgSize*rbgIndex + 1) : (rbgSize*rbgIndex + rbgSize)) = ...
                            (rbgSize*rbgIndex) : (rbgSize*rbgIndex + rbgSize -1);
                    end
                end
            end
            RBSet = RBSet(RBSet >= 0);
        end

        function populateDuplexModeProperties(obj, param)
            % Populate duplex mode dependent properties

            % Set the RBG size configuration (for defining number of RBs in
            % one RBG) to 1 (configuration-1 RBG table) or 2
            % (configuration-2 RBG table) as defined in 3GPP TS 38.214
            % Section 5.1.2.2.1. If it is not configured, take default
            % value as 1.
            if isfield(param, 'RBGSizeConfig')
                RBGSizeConfig = param.RBGSizeConfig;
            else
                RBGSizeConfig = 1;
            end

            if isfield(param, 'duplexMode')
                obj.DuplexMode = param.duplexMode;
            end
            if isfield(param, 'numRBs')
                obj.NumPUSCHRBs = param.numRBs;
                obj.NumPDSCHRBs = param.numRBs;
            end

            % Calculate UL and DL RBG size in terms of number of RBs
            uplinkRBGSizeIndex = min(find(obj.NumPUSCHRBs <= obj.NominalRBGSizePerBW(:, 1), 1));
            downlinkRBGSizeIndex = min(find(obj.NumPDSCHRBs <= obj.NominalRBGSizePerBW(:, 1), 1));
            if RBGSizeConfig == 1
                obj.RBGSizeUL = obj.NominalRBGSizePerBW(uplinkRBGSizeIndex, 2);
                obj.RBGSizeDL = obj.NominalRBGSizePerBW(downlinkRBGSizeIndex, 2);
            else % RBGSizeConfig is 2
                obj.RBGSizeUL = obj.NominalRBGSizePerBW(uplinkRBGSizeIndex, 3);
                obj.RBGSizeDL = obj.NominalRBGSizePerBW(downlinkRBGSizeIndex, 3);
            end
            % As number of RBs may not be completely divisible by RBG
            % size, last RBG may not have the same number of RBs
            obj.NumRBGsUL = ceil(obj.NumPUSCHRBs/obj.RBGSizeUL);
            obj.NumRBGsDL = ceil(obj.NumPDSCHRBs/obj.RBGSizeDL);

            if obj.DuplexMode == 1 % TDD
                % Validate the TDD configuration and populate the properties
                populateTDDConfiguration(obj, param);

                % Set format of slots in the DL-UL pattern. Value 0, 1 and 2 means
                % symbol type as DL, UL and guard, respectively
                obj.DLULSlotFormat = obj.GuardType * ones(obj.NumDLULPatternSlots, 14);
                obj.DLULSlotFormat(1:obj.NumDLSlots, :) = obj.DLType; % Mark all the symbols of full DL slots as DL
                obj.DLULSlotFormat(obj.NumDLSlots + 1, 1 : obj.NumDLSyms) = obj.DLType; % Mark DL symbols following the full DL slots
                obj.DLULSlotFormat(obj.NumDLSlots + floor(obj.GuardDuration/14) + 1, (obj.NumDLSyms + mod(obj.GuardDuration, 14) + 1) : end)  ...
                        = obj.ULType; % Mark UL symbols at the end of slot before full UL slots
                obj.DLULSlotFormat((end - obj.NumULSlots + 1):end, :) = obj.ULType; % Mark all the symbols of full UL slots as UL type

                % Get the first slot with UL symbols
                slotNum = 0;
                while slotNum < obj.NumSlotsFrame && slotNum < obj.NumDLULPatternSlots
                    if find(obj.DLULSlotFormat(slotNum + 1, :) == obj.ULType, 1)
                        break; % Found a slot with UL symbols
                    end
                    slotNum = slotNum + 1;
                end

                obj.NextULSchedulingSlot = slotNum; % Set the first slot to be scheduled by UL scheduler
            else % FDD
                if isfield(param, 'schedulerPeriodicity')
                    % Number of slots in a frame
                    numSlotsFrame = 10 *(obj.SCS / 15);
                    validateattributes(param.schedulerPeriodicity, {'numeric'}, {'nonempty', ...
                        'integer', 'scalar', '>', 0, '<=', numSlotsFrame}, 'param.SchedulerPeriodicity', ...
                        'SchedulerPeriodicity');
                    obj.SchedulerPeriodicity = param.schedulerPeriodicity;
                end
                % Initialization to make sure that schedulers run in the
                % very first slot of simulation run
                obj.SlotsSinceSchedulerRunDL = obj.SchedulerPeriodicity - 1;
                obj.SlotsSinceSchedulerRunUL = obj.SchedulerPeriodicity - 1;
            end
        end

        function populateTDDConfiguration(obj, param)
            %populateTDDConfiguration Validate TDD configuration and
            %populate the properties

            % Validate the DL-UL pattern duration
            validDLULPeriodicity{1} =  { 1 2 5 10 }; % Applicable for scs = 15 kHz
            validDLULPeriodicity{2} =  { 0.5 1 2 2.5 5 10 }; % Applicable for scs = 30 kHz
            validDLULPeriodicity{3} =  { 0.5 1 1.25 2 2.5 5 10 }; % Applicable for scs = 60 kHz
            validDLULPeriodicity{4} =  { 0.5 0.625 1 1.25 2 2.5 5 10}; % Applicable for scs = 120 kHz
            validSCS = [15 30 60 120];
            if ~ismember(obj.SCS, validSCS)
                error('nr5g:scheduler:InvalidSCS','The subcarrier spacing ( %d ) must be one of the set (%s).',obj.SCS, sprintf(repmat('%d ', 1, length(validSCS)), validSCS));
            end
            numerology = find(validSCS==obj.SCS, 1, 'first');
            validSet = cell2mat(validDLULPeriodicity{numerology});

            if isfield(param, 'dlulPeriodicity')
                validateattributes(param.dlulPeriodicity, {'numeric'}, {'nonempty'}, 'param.dlulPeriodicity', 'dlulPeriodicity');
                if ~ismember(param.dlulPeriodicity, cell2mat(validDLULPeriodicity{numerology}))
                    error('nr5g:scheduler:InvaliddlulPeriodicity','dlulPeriodicity (%.3f) must be one of the set (%s).', ...
                        param.dlulPeriodicity, sprintf(repmat('%.3f ', 1, length(validSet)), validSet));
                end
                numSlotsDLDULPattern = param.dlulPeriodicity/obj.SlotDuration;

                % Validate the number of full DL slots at the beginning of DL-UL pattern
                validateattributes(param.numDLSlots, {'numeric'}, {'nonempty'}, 'param.numDLSlots', 'numDLSlots');
                if~(param.numDLSlots <= (numSlotsDLDULPattern-1))
                    error('nr5g:scheduler:InvalidnumDLSlots','Number of full DL slots (%d) must be less than numSlotsDLDULPattern(%d).', ...
                        param.numDLSlots, numSlotsDLDULPattern);
                end

                % Validate the number of full UL slots at the end of DL-UL pattern
                validateattributes(param.numULSlots, {'numeric'}, {'nonempty'}, 'param.numULSlots', 'numULSlots');
                if~(param.numULSlots <= (numSlotsDLDULPattern-1))
                    error('nr5g:scheduler:InvalidNumULSlots','Number of full UL slots (%d) must be less than numSlotsDLDULPattern(%d).', ...
                        param.numULSlots, numSlotsDLDULPattern);
                end

                if~(param.numDLSlots + param.numULSlots  <= (numSlotsDLDULPattern-1))
                    error('nr5g:scheduler:InvalidnumDLULSlots','Sum of full DL and UL slots(%d) must be less than numSlotsDLDULPattern(%d).', ...
                        param.numDLSlots + param.numULSlots, numSlotsDLDULPattern);
                end

                % Validate that there must be some UL resources in the DL-UL pattern
                if obj.SchedulingType == 0 && param.numULSlots == 0
                    error('nr5g:scheduler:InvalidNumULSlots','Number of full UL slots (%d) must be greater than {0} for slot based scheduling', param.NumULSlots);
                end
                if obj.SchedulingType == 1 && param.numULSlots == 0 && param.numULSyms == 0
                    error('nr5g:scheduler:InvalidULResources','DL-UL pattern must contain UL resources. Set numULSlots(%d) or numULSyms(%d) to a positive integer).', ...
                        param.numULSlots, param.numULSyms);
                end
                % Validate that there must be some DL resources in the DL-UL pattern
                if(param.numDLSlots == 0 && param.numDLSyms == 0)
                    error('nr5g:hNRScheduler:InvalidDLResources','DL-UL pattern must contain DL resources. Set numDLSlots(%d) or numDLSyms(%d) to a positive integer).', ...
                        param.numDLSlots, param.numDLSyms);
                end

                obj.NumDLULPatternSlots = param.dlulPeriodicity/obj.SlotDuration;
                obj.NumDLSlots = param.numDLSlots;
                obj.NumULSlots = param.numULSlots;
                obj.NumDLSyms = param.numDLSyms;
                obj.NumULSyms = param.numULSyms;

                totalSymbolsDLULPattern = numSlotsDLDULPattern*14;
                totalSymbolSpecified = param.numDLSlots*14 + param.numULSlots*14 + param.numDLSyms + param.numULSyms;
                if(totalSymbolsDLULPattern < totalSymbolSpecified)
                    error('nr5g:hNRScheduler:InvalidDLULAssignment','Total number of symbols specified as DL or UL(%d) must be less than or equal to total number of symbols in the DL-UL pattern(%d).', ...
                        totalSymbolSpecified, totalSymbolsDLULPattern);
                end

                % All the remaining symbols in DL-UL pattern are assumed to
                % be guard symbols
                obj.GuardDuration = (obj.NumDLULPatternSlots * 14) - ...
                    (((obj.NumDLSlots + obj.NumULSlots)*14) + ...
                    obj.NumDLSyms + obj.NumULSyms);
            end
        end

        function modScheme = modSchemeStr(~, modSchemeBits)
            %modSchemeStr Return the modulation scheme string based on modulation scheme bits

            % Modulation scheme and corresponding bits/symbol
            fullmodlist = ["pi/2-BPSK", "BPSK", "QPSK", "16QAM", "64QAM", "256QAM"]';
            qm = [1 1 2 4 6 8];
            modScheme = fullmodlist((modSchemeBits == qm)); % Get modulation scheme string
        end

        function [servedBits, nREPerPRB] = tbsCapability(obj, linkDir, nLayers, mappingType,  ...
                startSym, numSym, prbSet, modScheme, codeRate, numCDMGroups)
            %tbsCapability Calculate the served bits and number of PDSCH/PUSCH REs per PRB

            if linkDir % Uplink
                % PUSCH configuration object
                pusch = obj.PUSCHConfig;
                pusch.SymbolAllocation = [startSym numSym];
                pusch.MappingType = mappingType;
                if mappingType == 'A'
                    dmrsAdditonalPos = obj.PUSCHDMRSAdditionalPosTypeA;
                else
                    dmrsAdditonalPos = obj.PUSCHDMRSAdditionalPosTypeB;
                end
                pusch.DMRS.DMRSAdditionalPosition = dmrsAdditonalPos;
                pusch.DMRS.NumCDMGroupsWithoutData = numCDMGroups;
                pusch.PRBSet = prbSet;
                pusch.Modulation = modScheme;
                [~, pxschIndicesInfo] = nrPUSCHIndices(obj.CarrierConfigUL, pusch);
                % Overheads in PUSCH transmission
                xOh = 0;
            else % Downlink
                % PDSCH configuration object
                pdsch = obj.PDSCHConfig;
                pdsch.SymbolAllocation = [startSym numSym];
                pdsch.MappingType = mappingType;
                if mappingType == 'A'
                    dmrsAdditonalPos = obj.PDSCHDMRSAdditionalPosTypeA;
                else
                    dmrsAdditonalPos = obj.PDSCHDMRSAdditionalPosTypeB;
                end
                pdsch.DMRS.DMRSAdditionalPosition = dmrsAdditonalPos;
                pdsch.DMRS.NumCDMGroupsWithoutData = numCDMGroups;
                pdsch.PRBSet = prbSet;
                pdsch.Modulation = modScheme;
                [~, pxschIndicesInfo] = nrPDSCHIndices(obj.CarrierConfigDL, pdsch);
                xOh = obj.XOverheadPDSCH;
            end

            servedBits = nrTBS(modScheme, nLayers, length(prbSet), ...
                pxschIndicesInfo.NREPerPRB, codeRate, xOh);
            nREPerPRB = pxschIndicesInfo.NREPerPRB;
        end

        function updateHARQContextDL(obj, grants)
            %updateHARQContextDL Update DL HARQ context based on the grants

            for grantIndex = 1:length(grants) % Update HARQ context
                grant = grants{grantIndex};
                harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesDL(grant.RNTI, grant.HARQID+1), 1);
                obj.HarqProcessesDL(grant.RNTI, grant.HARQID+1) = harqProcess;
                obj.HarqStatusDL{grant.RNTI, grant.HARQID+1} = grant; % Mark HARQ process as busy
                obj.HarqNDIDL(grant.RNTI, grant.HARQID+1) = grant.NDI;
                if strcmp(grant.Type, 'reTx')
                    % Clear the retransmission context for this HARQ
                    % process of the selected UE to make it ineligible
                    % for retransmission assignments
                    obj.RetransmissionContextDL{grant.RNTI, grant.HARQID+1} = [];
                end
            end
        end

        function updateHARQContextUL(obj, grants)
            %updateHARQContextUL Update UL HARQ context based on the grants

            for grantIndex = 1:length(grants) % Update HARQ context
                grant = grants{grantIndex};
                harqProcess = communication.harq.updateHARQProcess(obj.HarqProcessesUL(grant.RNTI, grant.HARQID+1), 1);
                obj.HarqProcessesUL(grant.RNTI, grant.HARQID+1) = harqProcess;
                obj.HarqStatusUL{grant.RNTI, grant.HARQID+1} = grant; % Mark HARQ process as busy
                obj.HarqNDIUL(grant.RNTI, grant.HARQID+1) = grant.NDI;
                if strcmp(grant.Type, 'reTx')
                    % Clear the retransmission context for this HARQ
                    % process of the selected UE to make it ineligible
                    % for retransmission assignments
                    obj.RetransmissionContextUL{grant.RNTI, grant.HARQID+1} = [];
                end
            end
        end

        function MCSTable = getMCSTableUL(~)
            %getMCSTableUL Return the MCS table as per TS 38.214 - Table 5.1.3.1-2

            % Modulation CodeRate Efficiency
            MCSTable = [2	120	0.2344
                2	193     0.3770
                2	308     0.6016
                2	449     0.8770
                2	602     1.1758
                4	378     1.4766
                4	434     1.6953
                4	490     1.9141
                4	553     2.1602
                4	616     2.4063
                4	658     2.5703
                6	466     2.7305
                6	517     3.0293
                6	567     3.3223
                6	616     3.6094
                6	666     3.9023
                6	719     4.2129
                6	772     4.5234
                6	822     4.8164
                6	873     5.1152
                8	682.5	5.3320
                8	711     5.5547
                8	754     5.8906
                8	797     6.2266
                8	841     6.5703
                8	885     6.9141
                8	916.5	7.1602
                8	948     7.4063
                2    0       0
                4    0       0
                6    0       0
                8    0       0];
        end

        function MCSTable = getMCSTableDL(~)
            %getMCSTableDL Return the MCS table as per TS 38.214 - Table 5.1.3.1-2

            % Modulation CodeRate Efficiency
            MCSTable = [2	120	0.2344
                2	193     0.3770
                2	308     0.6016
                2	449     0.8770
                2	602     1.1758
                4	378     1.4766
                4	434     1.6953
                4	490     1.9141
                4	553     2.1602
                4	616     2.4063
                4	658     2.5703
                6	466     2.7305
                6	517     3.0293
                6	567     3.3223
                6	616     3.6094
                6	666     3.9023
                6	719     4.2129
                6	772     4.5234
                6	822     4.8164
                6	873     5.1152
                8	682.5	5.3320
                8	711     5.5547
                8	754     5.8906
                8	797     6.2266
                8	841     6.5703
                8	885     6.9141
                8	916.5	7.1602
                8	948     7.4063
                2    0       0
                4    0       0
                6    0       0
                8    0       0];
        end

    end
end