classdef schedulingLogger < handle
    %schedulingLogger Scheduler logging mechanism
    %   The class implements logging mechanism. The following types of
    %   informations is logged:
    %    (i) Logs of CQI values for UEs over the bandwidth
    %   (ii) Logs of resource grid assignment to UEs

    %   Copyright 2019-2021 The MathWorks, Inc.

    properties
        %NCellID Cell ID to which the logging and visualization object belongs
        NCellID (1, 1) {mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1;

        %NumUEs Count of UEs
        NumUEs

        %NumHARQ Number of HARQ processes
        % The default value is 16 HARQ processes
        NumHARQ (1, 1) {mustBeInteger, mustBeInRange(NumHARQ, 1, 16)} = 16;

        %NumFrames Number of frames in simulation
        NumFrames

        %SchedulingType Type of scheduling (slot based or symbol based)
        % Value 0 means slot based and value 1 means symbol based. The
        % default value is 0
        SchedulingType (1, 1) {mustBeMember(SchedulingType, [0, 1])} = 0;

        %DuplexMode Duplexing mode
        % Frequency division duplexing (FDD) or time division duplexing (TDD)
        % Value 0 means FDD and 1 means TDD. The default value is 0
        DuplexMode (1, 1) {mustBeMember(DuplexMode, [0, 1])} = 0;

        %ColumnIndexMap Mapping the column names of logs to respective column indices
        % It is a map object
        ColumnIndexMap

        %GrantColumnIndexMap Mapping the column names of scheduling logs to respective column indices
        % It is a map object
        GrantLogsColumnIndexMap

        %NumRBs Number of resource blocks
        % A vector of two elements and represents the number of PDSCH and
        % PUSCH RBs respectively
        NumRBs = zeros(2, 1);

        %Bandwidth Carrier bandwidth
        % A vector of two elements and represents the downlink and uplink
        % bandwidth respectively
        Bandwidth

        %RBGSizeConfig Type of RBG table to use
        % Flag used in determining the RBGsize. Value 1 represents
        % (configuration-1 RBG table) or 2 represents (configuration-2 RBG
        % table) as defined in 3GPP TS 38.214 Section 5.1.2.2.1. The
        % default value is 1
        RBGSizeConfig = 1;

        %SchedulingLog Symbol-by-symbol log of the simulation
        % In FDD mode first element contains downlink scheduling
        % information and second element contains uplink scheduling
        % information. In TDD mode first element contains scheduling
        % information of both downlink and uplink
        SchedulingLog = cell(2, 1);

        %GrantLog Log of the scheduling grants
        % It also contains the parameters for scheduling decisions
        GrantLog

        %IsLogReplay Flag to decide the type of post-simulation visualization
        % whether to show plain replay of the resource assignment during
        % simulation or of the selected slot (or frame). During the
        % post-simulation visualization, setting the value to 1 just
        % replays the resource assignment of the simulation frame-by-frame
        % (or slot-by-slot). Setting value to 0 gives the option to select
        % a particular frame (or slot) to see the way resources are
        % assigned in the chosen frame (or slot)
        IsLogReplay

        %PeakDataRateDL Theoretical peak data rate in the downlink direction
        PeakDataRateDL

        %PeakDataRateUL Theoretical peak data rate in the uplink direction
        PeakDataRateUL
    end

    properties (GetAccess = public, SetAccess = private)
        % UEIdList RNTIs of UEs in a cell as row vector
        UEIdList
    end

    properties (Constant)
        %NumSym Number of symbols in a slot
        NumSym = 14;

        %NominalRBGSizePerBW Nominal RBG size table
        % It is for the specified bandwidth in accordance with
        % 3GPP TS 38.214, Section 5.1.2.2.1
        NominalRBGSizePerBW = [
            36   2   4
            72   4   8
            144  8   16
            275  16  16
            ];

        % Duplexing mode related constants
        %FDDDuplexMode Frequency division duplexing mode
        FDDDuplexMode = 0;
        %TDDDuplexMode Time division duplexing mode
        TDDDuplexMode = 1;

        % Constants related to scheduling type
        %SymbolBased Symbol based scheduling
        SymbolBased = 1;
        %SlotBased Slot based scheduling
        SlotBased = 0;

        % Constants related to downlink and uplink information. These
        % constants are used for indexing logs and identifying plots
        %DownlinkIdx Index for all downlink information
        DownlinkIdx = 1;
        %UplinkIdx Index for all downlink information
        UplinkIdx = 2;
    end

    properties (Access = private)
        %NumSlotsFrame Number of slots in 10ms time frame
        NumSlotsFrame

        %CurrSlot Current slot in the frame
        CurrSlot

        %CurrFrame Current frame
        CurrFrame

        %CurrSymbol Current symbol in the slot
        CurrSymbol

        %NumLogs Number of logs to be created based on number of links
        NumLogs

        %SymbolInfo Information about how each symbol (UL/DL/Guard) is allocated
        SymbolInfo

        %SlotInfo Information about how each slot (UL/DL/Guard) is allocated
        SlotInfo

        %PlotIds IDs of the plots
        PlotIds

        %GrantCount Keeps track of count of grants sent
        GrantCount = 0

        %RBGSize Number of RBs in an RBG. First element represents RBG
        % size for PDSCHRBs and second element represents RBG size for
        % PUSCHRBS
        RBGSize = zeros(2, 1);

        %LogInterval Represents the log interval
        % It represents the difference (in terms of number of symbols) between
        % two consecutive rows which contains valid data in SchedulingLog
        % cell array
        LogInterval

        %StepSize Represents the granularity of logs
        StepSize

        %UEMetricsUL UE metrics for each slot in the UL direction
        % It is an array of size N-by-3 where N is the number of UEs in
        % each cell. Each column of the array contains the following
        % metrics: throughput bytes transmitted, goodput bytes transmitted,
        % and pending buffer amount bytes.
        UEMetricsUL

        %UEMetricsDL UE metrics for each slot in the DL direction
        % It is an array of size N-by-3 where N is the number of UEs in
        % each cell. Each column of the array contains the following
        % metrics: throughput bytes transmitted, goodput bytes transmitted,
        % and pending buffer amount bytes.
        UEMetricsDL

        %PrevUEMetricsUL UE metrics returned in the UL direction for previous query
        % It is an array of size N-by-3 where N is the number of UEs in
        % each cell. Each column of the array contains the following
        % metrics: throughput bytes transmitted, goodput bytes transmitted,
        % and pending buffer amount bytes.
        PrevUEMetricsUL
        
        %PrevUEMetricsDL UE metrics returned in the DL direction for previous query
        % It is an array of size N-by-3 where N is the number of UEs in
        % each cell. Each column of the array contains the following
        % metrics: throughput bytes transmitted, goodput bytes transmitted,
        % and pending buffer amount bytes.
        PrevUEMetricsDL
        
        %UplinkChannelQuality Current channel quality for the UEs in uplink
        % It is an array of size M-by-N where M and N represents the number
        % of UEs in each cell and the number of RBs respectively.
        UplinkChannelQuality

        %DownlinkChannelQuality Current channel quality for the UEs in downlink
        % It is an array of size M-by-N where M and N represents the number
        % of UEs in each cell and the number of RBs respectively.
        DownlinkChannelQuality

        %HARQProcessStatusUL HARQ process status for each UE in UL
        % It is an array of size M-by-N where M and N represents the number
        % of UEs and number of HARQ processes for each UE respectively. Each
        % element stores the last received new data indicator (NDI) values
        % in the uplink
        HARQProcessStatusUL

        %HARQProcessStatusDL HARQ process status for each UE in DL
        % It is an array of size M-by-N where M and N represents the number
        % of UEs and number of HARQ processes for each UE respectively. Each
        % element stores the last received new data indicator (NDI) values
        % in the downlink
        HARQProcessStatusDL

        %PeakDLSpectralEfficiency Theoretical peak spectral efficiency in
        % the downlink direction
        PeakDLSpectralEfficiency

        %PeakULSpectralEfficiency Theoretical peak spectral efficiency in
        % the uplink direction
        PeakULSpectralEfficiency

        %LogGranularity Granularity of logs
        % It indicates whether logging is done for each symbol or each slot
        % (1 slot = 14 symbols)
        LogGranularity = 14;

        %Events List of events registered. It contains list of periodic events
        % By default events are triggered after every slot boundary. This event
        % list contains events which depends on the traces or which
        % requires periodic trigger after each slot boundary.
        % It is an array of structures and contains following fields
        %    CallBackFn - Call back to invoke when triggering the event
        %    TimeToInvoke - Time at which event has to be invoked
        Events = [];
    end

    methods
        function obj = schedulingLogger(simParameters, varargin)
            %schedulingLogger Construct scheduling log and visualization object
            %
            % OBJ = hNRSchedulingLogger(SIMPARAMETERS) Create scheduling
            % information logging object.
            %
            % OBJ = hNRSchedulingLogger(SIMPARAMETERS, FLAG) Create scheduling
            % information logging object.
            %
            % OBJ = hNRSchedulingLogger(SIMPARAMETERS, FLAG, ISLOGREPLAY)
            % Create scheduling information logging object.
            %
            % SIMPARAMETERS - It is a structure and contain simulation
            % configuration information.
            %
            % NumFramesSim      - Simulation time in terms of number of 10 ms frames
            % NumUEs            - Number of UEs
            % NCellID           - Cell identifier
            % DuplexMode        - Duplexing mode (FDD or TDD)
            % SchedulingType    - Slot-based or symbol-based scheduling
            % NumHARQ           - Number of HARQ processes
            % NumRBs            - Number of resource blocks in PUSCH and PDSCH bandwidth
            % SCS               - Subcarrier spacing
            % DLBandwidth       - Downlink bandwidth
            % ULBandwidth       - Uplink bandwidth
            % DLULPeriodicity   - Duration of the DL-UL pattern in ms (for
            %                     TDD mode)
            % NumDLSlots        - Number of full DL slots at the start of
            %                     DL-UL pattern (for TDD mode)
            % NumDLSyms         - Number of DL symbols after full DL slots
            %                     in the DL-UL pattern (for TDD mode)
            % NumULSlots        - Number of full UL slots at the end of
            %                     DL-UL pattern (for TDD mode)
            % NumULSyms         - Number of UL symbols before full UL slots
            %                     in the DL-UL pattern (for TDD mode)
            % RBGSizeConfig     - Configuration table to use for
            %                     determining the RBG size (value 1
            %                     represents table-1 and value 2 represent
            %                     table-2)
            % TTIGranularity    - Minimum TTI granularity in terms of
            %                     number of symbols (for symbol-based scheduling)
            %
            % If FLAG = 0, Visualize downlink information.
            % If FLAG = 1, Visualize uplink information.
            % If FLAG = 2, Visualize  downlink and uplink information.
            %
            % ISLOGREPLAY = true Replays the resource assignment of the simulation
            % frame-by-frame (or slot-by-slot).
            % ISLOGREPLAY = false Gives the option to select a particular frame
            % (or slot) to see the way resources are assigned in the chosen
            % frame (or slot).

            % Validate number of frames in simulation
            obj.NumFrames = simParameters.numFrames;

            if isfield(simParameters, 'cellID')
                obj.NCellID = simParameters.cellID;
            end

            obj.NumUEs = simParameters.numUEs;
            obj.UEIdList = 1:obj.NumUEs;

            if isfield(simParameters, 'NumHARQ')
                obj.NumHARQ = simParameters.NumHARQ;
            end
            if isfield(simParameters, 'schedulingType')
                obj.SchedulingType = simParameters.schedulingType;
            end
            obj.ColumnIndexMap = containers.Map('KeyType','char','ValueType','double');
            obj.GrantLogsColumnIndexMap = containers.Map('KeyType','char','ValueType','double');
            obj.NumSlotsFrame = (10 * simParameters.scs) / 15; % Number of slots in a 10 ms frame

            % Symbol duration for the given numerology
            symbolDuration = 1e-3/(14*(simParameters.scs/15)); % Assuming normal cyclic prefix

            % Validate the number of transmitter antennas on gNB
            if ~isfield(simParameters, 'gNBTxAnts')
                simParameters.GNBTxAnts = 1;
            elseif ~ismember(simParameters.gNBTxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:hNRSchedulingLogger:InvalidAntennaSize',...
                    'Number of gNB Tx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', simParameters.gNBTxAnts);
            end
            % Validate the number of receiver antennas on gNB
            if ~isfield(simParameters, 'gNBRxAnts')
                simParameters.gNBRxAnts = 1;
            elseif ~ismember(simParameters.gNBRxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:hNRSchedulingLogger:InvalidAntennaSize',...
                    'Number of gNB Rx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', simParameters.gNBRxAnts);
            end
            if ~isfield(simParameters, 'ueTxAnts')
                simParameters.ueTxAnts = ones(simParameters.numUEs, 1);
                % Validate the number of transmitter antennas on UEs
            elseif ~ismember(simParameters.ueTxAnts, [1,2,4,8,16])
                error('nr5g:hNRSchedulingLogger:InvalidAntennaSize',...
                    'Number of UE Rx antennas (%d) must be a member of [1,2,4,8,16].', simParameters.ueTxAnts(rnti));
            end
            if ~isfield(simParameters, 'ueRxAnts')
                simParameters.ueRxAnts = ones(simParameters.numUEs, 1);
                % Validate the number of receiver antennas on UEs
            elseif ~ismember(simParameters.ueRxAnts, [1,2,4,8,16])
                error('nr5g:hNRSchedulingLogger:InvalidAntennaSize',...
                    'Number of UE Rx antennas (%d) must be a member of [1,2,4,8,16].', simParameters.ueRxAnts(rnti));
            end

            % Maximum number of transmission layers for each UE in DL
            numLayersDL = min(simParameters.gNBTxAnts*ones(simParameters.numUEs, 1), simParameters.ueRxAnts);
            % Maximum number of transmission layers for each UE in UL
            numLayersUL = min(simParameters.gNBRxAnts*ones(simParameters.numUEs, 1), simParameters.ueTxAnts);
            % Verify Duplex mode and update the properties
            if isfield(simParameters, 'duplexMode')
                obj.DuplexMode = simParameters.duplexMode;
            end
            if obj.DuplexMode == obj.TDDDuplexMode || obj.SchedulingType == obj.SymbolBased
                obj.LogGranularity = 1;
            end
            if isfield(simParameters, 'numDLSlots')
                numDLSlots = simParameters.numDLSlots;
            else
                numDLSlots = 2;
            end
            if isfield(simParameters, 'numDLSyms')
                numDLSyms = simParameters.numDLSyms;
            else
                numDLSyms = 8;
            end
            if isfield(simParameters, 'numULSlots')
                numULSlots = simParameters.numULSlots;
            else
                numULSlots = 2;
            end
            if isfield(simParameters, 'numULSyms')
                numULSyms = simParameters.numULSyms;
            else
                numULSyms = 4;
            end
            if isfield(simParameters, 'dlulPeriodicity')
                dlulPeriodicity = simParameters.dlulPeriodicity;
            else
                dlulPeriodicity = 5;
            end

            if obj.DuplexMode == obj.TDDDuplexMode % TDD
                obj.NumLogs = 1;
                % Number of DL symbols in one DL-UL pattern
                numDLSymbols = numDLSlots*14 + numDLSyms;
                % Number of UL symbols in one DL-UL pattern
                numULSymbols = numULSlots*14 + numULSyms;
                % Number of symbols in one DL-UL pattern
                numSymbols = dlulPeriodicity*(simParameters.scs/15)*14;
                % Normalized scalar considering the downlink symbol
                % allocation in the frame structure
                scaleFactorDL = numDLSymbols/numSymbols;
                % Normalized scalar considering the uplink symbol allocation
                % in the frame structure
                scaleFactorUL = numULSymbols/numSymbols;
            else % FDD
                obj.NumLogs = 2;
                % Normalized scalars in the DL and UL directions are 1 for
                % FDD mode
                scaleFactorDL = 1;
                scaleFactorUL = 1;
            end

            obj.UEMetricsUL = zeros(simParameters.numUEs, 3);
            obj.UEMetricsDL = zeros(simParameters.numUEs, 3);
            obj.PrevUEMetricsUL = zeros(simParameters.numUEs, 3);
            obj.PrevUEMetricsDL = zeros(simParameters.numUEs, 3);
            
            % Store current UL and DL CQI values on the RBs for the UEs.
            obj.UplinkChannelQuality = zeros(simParameters.numUEs, simParameters.numRBs);
            obj.DownlinkChannelQuality = zeros(simParameters.numUEs, simParameters.numRBs);

            % Store the last received new data indicator (NDI) values for UL and DL HARQ
            % processes.
            obj.HARQProcessStatusUL = zeros(simParameters.numUEs, obj.NumHARQ);
            obj.HARQProcessStatusDL = zeros(simParameters.numUEs, obj.NumHARQ);

            if isfield(simParameters, 'dlBandwidth')
                obj.Bandwidth(obj.DownlinkIdx) = simParameters.dlBandwidth;
            end
            if isfield(simParameters, 'ulBandwidth')
                obj.Bandwidth(obj.UplinkIdx) = simParameters.ulBandwidth;
            end
            % Calculate uplink and downlink peak data rates as per 3GPP TS
            % 37.910. The number of layers used for the peak DL data rate
            % calculation is taken as the average of maximum layers
            % possible for each UE. The maximum layers possible for each UE
            % is min(gNBTxAnts, ueRxAnts)
            % Determine the plots
            if isempty(varargin) || (nargin >= 2  && varargin{1} == 2)
                % Downlink & Uplink
                obj.PlotIds = [obj.DownlinkIdx obj.UplinkIdx];
                % Average of the peak DL throughput values for each UE
                obj.PeakDataRateDL = 1e-6*(sum(numLayersDL)/simParameters.numUEs)*scaleFactorDL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
                obj.PeakDataRateUL = 1e-6*(sum(numLayersUL)/simParameters.numUEs)*scaleFactorUL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
                % Calculate uplink and downlink peak spectral efficiency
                obj.PeakDLSpectralEfficiency = 1e6*obj.PeakDataRateDL/obj.Bandwidth(obj.DownlinkIdx);
                obj.PeakULSpectralEfficiency = 1e6*obj.PeakDataRateUL/obj.Bandwidth(obj.UplinkIdx);
            elseif varargin{1} == 0 % Downlink
                obj.PlotIds = obj.DownlinkIdx;
                obj.PeakDataRateDL = 1e-6*(sum(numLayersDL)/simParameters.numUEs)*scaleFactorDL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
                % Calculate downlink peak spectral efficiency
                obj.PeakDLSpectralEfficiency = 1e6*obj.PeakDataRateDL/obj.Bandwidth(obj.DownlinkIdx);
            else % Uplink
                obj.PlotIds = obj.UplinkIdx;
                obj.PeakDataRateUL = 1e-6*(sum(numLayersUL)/simParameters.numUEs)*scaleFactorUL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
                % Calculate uplink peak spectral efficiency
                obj.PeakULSpectralEfficiency = 1e6*obj.PeakDataRateUL/obj.Bandwidth(obj.UplinkIdx);
            end

            % Initialize number of RBs, RBG size, CQI and metrics properties
            if isfield(simParameters, 'RBGSizeConfig')
                obj.RBGSizeConfig = simParameters.RBGSizeConfig;
            end
            for idx = 1: numel(obj.PlotIds)
                logIdx = obj.PlotIds(idx);
                obj.NumRBs(logIdx) = simParameters.numRBs; % Number of RBs in DL/UL
                % Calculate the RBGSize
                rbgSizeIndex = min(find(obj.NumRBs(logIdx) <= obj.NominalRBGSizePerBW(:, 1), 1));
                if obj.RBGSizeConfig == 1
                    obj.RBGSize(logIdx) = obj.NominalRBGSizePerBW(rbgSizeIndex, 2);
                else
                    obj.RBGSize(logIdx) = obj.NominalRBGSizePerBW(rbgSizeIndex, 3);
                end
            end

            % Initialize the scheduling logs and resources grid related
            % properties
            for idx=1:min(obj.NumLogs, numel(obj.PlotIds))
                plotId = obj.PlotIds(idx);
                if obj.DuplexMode == obj.FDDDuplexMode
                    logIdx = plotId; % FDD
                else
                    logIdx = idx; % TDD
                end
                % Construct the log format
                obj.SchedulingLog{logIdx} = constructLogFormat(obj, logIdx, simParameters);
            end

            % Check if it is post simulation analysis
            if nargin == 3
                obj.IsLogReplay = varargin{2};
            end

            % Construct the grant log format
            obj.GrantLog = constructGrantLogFormat(obj, simParameters);

            if ~isempty(obj.IsLogReplay) && obj.SchedulingType == obj.SlotBased
                % Post simulation log visualization and slot based scheduling
                obj.StepSize = 1;
                obj.LogInterval = 1;
            else
                % Live visualization
                obj.LogInterval = obj.NumSym;
                if obj.SchedulingType % Symbol based scheduling
                    obj.StepSize = 1;
                else % Slot based scheduling
                    obj.StepSize = obj.NumSym;
                end
            end
        end

        function [dlMetrics, ulMetrics, cellMetrics] = getMACMetrics(obj, firstSlot, lastSlot, rntiList)
            %getMACMetrics Returns the MAC metrics
            %
            % [DLMETRICS, ULMETRICS] = getMACMetrics(OBJ, FIRSTSLOT,
            % LASTSLOT, RNTILIST) Returns the MAC metrics of the UE with
            % specified RNTI within the cell for both uplink and downlink direction
            %
            % FIRSTSLOT - Represents the starting slot number for
            % querying the metrics
            %
            % LASTSLOT -  Represents the ending slot for querying the metrics
            %
            % RNTILIST - Radio network temporary identifiers of the UEs
            %
            % ULMETRICS and DLMETRICS are array of structures with following properties
            %
            %   RNTI - Radio network temporary identifier of the UE
            %
            %   TxBytes - Total number of bytes transmitted (newTx and reTx combined)
            %
            %   NewTxBytes - Number of bytes transmitted (only newTx)
            %
            %   BufferStatus - Current buffer status of the UE
            %
            %   AssignedRBCount - Number of resource blocks assigned to the UE
            %
            %   RBsScheduled - Total number resource blocks scheduled
            %
            % CELLMETRICS is an array structure with following properties and
            % contains cell wide metrics in downlink and uplink
            % respectively
            %
            %   DLTxBytes - Total number of bytes transmitted (newTx and
            %   reTx combined) in downlink
            %
            %   DLNewTxBytes - Number of bytes transmitted (only newTx) in
            %   downlink
            %
            %   DLRBsScheduled - Total number resource blocks scheduled in
            %   downlink
            %
            %   ULTxBytes - Total number of bytes transmitted (newTx and
            %   reTx combined) in uplink
            %
            %   ULNewTxBytes - Number of bytes transmitted (only newTx) in uplink
            %
            %   ULRBsScheduled - Total number resource blocks scheduled in uplink

            % Calculate the actual log start and end index
            stepLogStartIdx = (firstSlot-1) * obj.LogInterval + 1;
            stepLogEndIdx = lastSlot*obj.LogInterval;

            % Create structure for both DL and UL
            outStruct = struct('RNTI', 0, 'TxBytes', 0, ...
                'NewTxBytes', 0, 'BufferStatus', 0, ...
                'AssignedRBCount', 0, 'RBsScheduled', 0);
            outputStruct = repmat(outStruct, [numel(rntiList) 2]);
            assignedRBsStep = zeros(obj.NumUEs, 2);
            macTxStep = zeros(obj.NumUEs, 2);
            macNewTxStep = zeros(obj.NumUEs, 2);
            bufferStatus = zeros(obj.NumUEs, 2);

            % Update the DL and UL metrics properties
            for idx = 1:min(obj.NumLogs, numel(obj.PlotIds))
                plotId = obj.PlotIds(idx);
                % Determine scheduling log index
                if obj.DuplexMode == obj.FDDDuplexMode
                    schedLogIdx = plotId;
                else
                    schedLogIdx = 1;
                end

                numULSyms = 0;
                numDLSyms = 0;

                % Read the information of each slot and update the metrics
                % properties
                for i = stepLogStartIdx:obj.StepSize:stepLogEndIdx
                    slotLog = obj.SchedulingLog{schedLogIdx}(i, :);
                    rbgAssignment = slotLog{obj.ColumnIndexMap('RBG Allocation Map')};
                    throughputBytes = slotLog{obj.ColumnIndexMap('Throughput Bytes')};
                    goodputBytes = slotLog{obj.ColumnIndexMap('Goodput Bytes')};
                    ueBufferStatus = slotLog{obj.ColumnIndexMap('Buffer status of UEs (In bytes)')};
                    if(obj.DuplexMode == obj.TDDDuplexMode)
                        switch (slotLog{obj.ColumnIndexMap('Type')})
                            case 'UL'
                                linkIdx = 2; % Uplink information index
                                numULSyms = numULSyms + 1;
                            case 'DL'
                                linkIdx = 1; % Downlink information index
                                numDLSyms = numDLSyms + 1;
                            otherwise
                                continue;
                        end
                    else
                        linkIdx = plotId;
                    end

                    % Calculate the RBs allocated to an UE
                    for ueIdx = 1 : obj.NumUEs
                        numRBGs = sum(rbgAssignment(ueIdx, :));
                        if rbgAssignment(ueIdx, end) % If RBG is allocated
                            % If the last RBG of BWP is assigned, then it might not
                            % have same number of RBs as other RBG.
                            if(mod(obj.NumRBs(plotId), obj.RBGSize(plotId)) == 0)
                                numRBs = numRBGs * obj.RBGSize(plotId);
                            else
                                lastRBGSize = mod(obj.NumRBs(plotId), obj.RBGSize(plotId));
                                numRBs = (numRBGs - 1) * obj.RBGSize(plotId) + lastRBGSize;
                            end
                        else
                            numRBs = numRBGs * obj.RBGSize(plotId);
                        end

                        assignedRBsStep(ueIdx, linkIdx) = assignedRBsStep(ueIdx, linkIdx) + numRBs;
                        macTxStep(ueIdx, linkIdx) = macTxStep(ueIdx, linkIdx) + throughputBytes(ueIdx);
                        macNewTxStep(ueIdx, linkIdx) = macNewTxStep(ueIdx, linkIdx) + goodputBytes(ueIdx);
                        bufferStatus(ueIdx, linkIdx) = ueBufferStatus(ueIdx);
                    end
                end
            end

            % Extract required metrics of the UEs specified in rntiList
            for idx = 1:numel(obj.PlotIds)
                linkIdx = obj.PlotIds(idx);
                for listIdx = 1:numel(rntiList)
                    ueIdx = find(rntiList(listIdx) == obj.UEIdList);
                    outputStruct(listIdx, linkIdx).RNTI = rntiList(listIdx);
                    outputStruct(listIdx, linkIdx).AssignedRBCount = assignedRBsStep(ueIdx, linkIdx);
                    outputStruct(listIdx, linkIdx).TxBytes = macTxStep(ueIdx, linkIdx);
                    outputStruct(listIdx, linkIdx).NewTxBytes = macNewTxStep(ueIdx, linkIdx);
                    outputStruct(listIdx, linkIdx).BufferStatus = bufferStatus(ueIdx, linkIdx);
                end
            end
            dlMetrics = outputStruct(:, obj.DownlinkIdx); % Downlink Info
            ulMetrics = outputStruct(:, obj.UplinkIdx); % Uplink Info
            % Cell wide metrics
            cellMetrics.DLTxBytes = sum(macTxStep(:, obj.DownlinkIdx));
            cellMetrics.DLNewTxBytes = sum(macNewTxStep(:, obj.DownlinkIdx));
            cellMetrics.ULTxBytes = sum(macTxStep(:, obj.UplinkIdx));
            cellMetrics.ULNewTxBytes = sum(macNewTxStep(:, obj.UplinkIdx));
            cellMetrics.ULRBsScheduled = sum(assignedRBsStep(:, obj.UplinkIdx));
            cellMetrics.DLRBsScheduled = sum(assignedRBsStep(:, obj.DownlinkIdx));
        end

        function [resourceGrid, resourceGridReTxInfo, resourceGridHarqInfo, varargout] = getRBGridsInfo(obj, frameNumber, slotNumber)
            %plotRBGrids Return the resource grid information
            %
            % getRBGridsInfo(OBJ, FRAMENUMBER, SLOTNUMBER) Return the resource grid status
            %
            % FRAMENUMBER - Frame number
            %
            % SLOTNUMBER - Slot number
            %
            % RESOURCEGRID In FDD mode first element contains downlink
            % resource grid allocation status and second element contains uplink
            % resource grid allocation status. In TDD mode first element
            % contains resource grid allocation status for downlink and uplink.
            % Each element is a 2D resource grid of N-by-P matrix where 'N' is
            % the number of slot or symbols and 'P' is the number of RBs in the
            % bandwidth to store how UEs are assigned different time-frequency
            % resources.
            %
            % RESOURCEGRIDHARQINFO In FDD mode first element contains
            % downlink HARQ information and second element contains uplink
            % HARQ information. In TDD mode first element contains HARQ
            % information for downlink and uplink. Each element is a 2D
            % resource grid of N-by-P matrix where 'N' is the number of
            % slot or symbols and 'P' is the number of RBs in the bandwidth
            % to store the HARQ process
            %
            % RESOURCEGRIDRETXINFO First element contains transmission
            % status in downlink and second element contains transmission
            % status in uplink for FDD mode. In TDD mode first element
            % contains transmission status for both downlink and uplink.
            % Each element is a 2D resource grid of N-by-P matrix where 'N'
            % is the number of slot or symbols and 'P' is the number of RBs
            % in the bandwidth to store type:new-transmission or
            % retransmission.

            resourceGrid = cell(2, 1);
            resourceGridReTxInfo = cell(2, 1);
            resourceGridHarqInfo = cell(2, 1);
            if obj.SchedulingType % Symbol based scheduling
                frameLogStartIdx = (frameNumber * obj.NumSlotsFrame * obj.LogInterval) + (slotNumber * obj.LogInterval);
                frameLogEndIdx = frameLogStartIdx + obj.LogInterval;
            else % Slot based scheduling
                frameLogStartIdx = frameNumber * obj.NumSlotsFrame * obj.LogInterval;
                frameLogEndIdx = frameLogStartIdx + (obj.NumSlotsFrame * obj.LogInterval);
            end

            % Read the resource grid information from logs
            for idx = 1:min(obj.NumLogs, numel(obj.PlotIds))
                plotId = obj.PlotIds(idx);
                if obj.DuplexMode == obj.FDDDuplexMode
                    logIdx = obj.PlotIds(idx);
                else
                    logIdx = 1;
                    symSlotInfo = cell(14,1);
                end

                % Reset the resource grid status
                if obj.SchedulingType % Symbol based scheduling
                    numRows = obj.NumSym;
                else % Slot based scheduling
                    numRows = obj.NumSlotsFrame;
                end
                emptyGrid = zeros(numRows, obj.NumRBs(logIdx));
                resourceGrid{logIdx} = emptyGrid;
                resourceGridReTxInfo{logIdx} = emptyGrid;
                resourceGridHarqInfo{logIdx} = emptyGrid;

                slIdx = 0; % Counter to keep track of the number of symbols/slots to be plotted
                for i = frameLogStartIdx+1:obj.StepSize:frameLogEndIdx % For each symbol in the slot or each slot in the frame
                    slIdx = slIdx + 1;
                    slotLog = obj.SchedulingLog{logIdx}(i, :);
                    rbgAssignment = slotLog{obj.ColumnIndexMap('RBG Allocation Map')};
                    harqIds = slotLog{obj.ColumnIndexMap('HARQ Process ID')};
                    txType = slotLog{obj.ColumnIndexMap('Transmission')};
                    % Symbol or slot information
                    if obj.DuplexMode == obj.TDDDuplexMode
                        symSlotInfo{slIdx} = slotLog{obj.ColumnIndexMap('Type')};
                    end
                    for j = 1 : obj.NumUEs % For each UE
                        if (strcmp(txType(j), 'newTx') || strcmp(txType(j), 'newTx-Start') || strcmp(txType(j), 'newTx-InProgress') || strcmp(txType(j), 'newTx-End'))
                            type = 1; % New transmission
                        else
                            type = 2; % Retransmission
                        end

                        % Updating the resource grid status and related
                        % information
                        RBGAllocationBitmap = rbgAssignment(j, :);
                        for k=1:length(RBGAllocationBitmap) % For all RBGs
                            if(RBGAllocationBitmap(k) == 1)
                                startRBIndex = (k - 1) * obj.RBGSize(plotId) + 1;
                                endRBIndex = k * obj.RBGSize(plotId);
                                if(k == length(RBGAllocationBitmap) && (mod(obj.NumRBs(plotId), obj.RBGSize(plotId)) ~=0))
                                    % If it is last RBG and it does not
                                    % have same number of RBs as other RBGs
                                    endRBIndex = (k - 1) * obj.RBGSize(plotId) + mod(obj.NumRBs(plotId), obj.RBGSize(plotId));
                                end
                                resourceGrid{logIdx}(slIdx, startRBIndex : endRBIndex) = j;
                                resourceGridReTxInfo{logIdx}(slIdx, startRBIndex : endRBIndex) = type;
                                resourceGridHarqInfo{logIdx}(slIdx, startRBIndex : endRBIndex) = harqIds(j);
                            end
                        end
                    end
                end
            end
            if obj.DuplexMode == obj.TDDDuplexMode
                varargout{1} = symSlotInfo;
            end
        end

        function [dlCQIInfo, ulCQIInfo] = getCQIRBGridsInfo(obj, frameNumber, slotNumber)
            %getCQIRBGridsInfo Return channel quality information
            %
            % getCQIRBGridsInfo(OBJ, FRAMENUMBER, SLOTNUMBER) Return
            % resource grid channel quality information
            %
            % FRAMENUMBER - Frame number
            %
            % SLOTNUMBER - Slot number
            %
            % DLCQIINFO - Downlink channel quality information
            %
            % ULCQIINFO - Uplink channel quality information

            cqiInfo = cell(2, 1);
            lwRowIndex = frameNumber * obj.NumSlotsFrame * obj.LogInterval;
            if obj.SchedulingType % Symbol based scheduling
                upRowIndex = lwRowIndex + (slotNumber + 1) * obj.LogInterval;
            else % Slot based scheduling
                upRowIndex = lwRowIndex + (slotNumber * obj.LogInterval) + 1;
            end

            if (obj.DuplexMode == obj.TDDDuplexMode) % TDD
                % Get the symbols types in the current frame
                symbolTypeInFrame = {obj.SchedulingLog{1}(lwRowIndex+1:upRowIndex, obj.ColumnIndexMap('Type'))};
                cqiInfo{obj.DownlinkIdx} = zeros(obj.NumUEs, obj.NumRBs(obj.DownlinkIdx));
                cqiInfo{obj.UplinkIdx} = zeros(obj.NumUEs, obj.NumRBs(obj.UplinkIdx));
                % Get the UL symbol indices
                ulIdx = find(strcmp(symbolTypeInFrame{1}, 'UL'));
                % Get the DL symbol indices
                dlIdx = find(strcmp(symbolTypeInFrame{1}, 'DL'));
                if ~isempty(dlIdx)
                    % Update downlink channel quality based on latest DL
                    % symbol/slot
                    cqiInfo{obj.DownlinkIdx} = obj.SchedulingLog{1}{lwRowIndex + dlIdx(end), obj.ColumnIndexMap('Channel Quality')};
                end
                if ~isempty(ulIdx)
                    % Update uplink channel quality based on latest UL
                    % symbol/slot
                    cqiInfo{obj.UplinkIdx} = obj.SchedulingLog{1}{lwRowIndex + ulIdx(end), obj.ColumnIndexMap('Channel Quality')};
                end
            else
                for idx=1:numel(obj.PlotIds)
                    plotId = obj.PlotIds(idx);
                    cqiInfo{plotId} = obj.SchedulingLog{plotId}{upRowIndex, obj.ColumnIndexMap('Channel Quality')};
                end
            end
            dlCQIInfo = cqiInfo{obj.DownlinkIdx};
            ulCQIInfo = cqiInfo{obj.UplinkIdx};
        end

        function logCellSchedulingStats(obj, symbolNum, gNB, UEs, varargin)
            %logCellSchedulingStats Log the MAC layer statistics
            %
            % LOGCELLSCHEDULINGSTATS(OBJ, SYMBOLNUM, GNB, UES, LINKDIR) Logs
            % the scheduling stats for all the nodes in the cell
            %
            % SYMBOLNUM - Symbol number in the simulation
            %
            % GNB - It is an object of type hNRGNB and contains information
            % about the gNB
            %
            % UEs - It is a cell array of length equal to the number of UEs
            % in the cell. Each element of the array is an object of type
            % hNRUE.
            %
            % LINKDIR - Indicates the downlink/uplink direction. 0 and 1
            % denotes downlink and uplink, respectively.

            if ~isempty(varargin)
                linkDir = varargin{1};
            else
                linkDir = 2; % For both UL & DL
            end

            % Read UL and DL assignments by gNB MAC scheduler
            % at current time. Resource assignments returned by a scheduler (either
            % UL or DL) are empty if either the scheduler was not scheduled to run at
            % the current time or the scheduler did not schedule any resources
            [resourceAssignmentsUL, resourceAssignmentsDL] = getCurrentSchedulingAssignments(gNB.MACEntity);
            % Read throughput and goodput bytes sent for each UE
            [obj.UEMetricsDL(:, 1), obj.UEMetricsDL(:, 2)] = getTTIBytes(gNB);
            obj.UEMetricsDL(:, 3) = getBufferStatus(gNB); % Read pending buffer (in bytes) on gNB, for all the UEs
            for ueIdx = 1:obj.NumUEs
                obj.HARQProcessStatusUL(ueIdx, :) = getLastNDIFlagHarq(UEs{ueIdx}.MACEntity, 1); % 1 for UL
                obj.HARQProcessStatusDL(ueIdx, :) = getLastNDIFlagHarq(UEs{ueIdx}.MACEntity, 0); % 0 for DL
                % Read the UL channel quality at gNB for each of the UEs for logging
                obj.UplinkChannelQuality(ueIdx,:) = getChannelQualityStatus(gNB.MACEntity, 1, ueIdx); % 1 for UL
                % Read the DL channel quality at gNB for each of the UEs for logging
                obj.DownlinkChannelQuality(ueIdx,:) = getChannelQualityStatus(gNB.MACEntity, 0, ueIdx); % 0 for DL
                % Read throughput and goodput bytes transmitted for the UE in the
                % current TTI for logging
                [obj.UEMetricsUL(ueIdx, 1), obj.UEMetricsUL(ueIdx, 2)] = getTTIBytes(UEs{ueIdx});
                obj.UEMetricsUL(ueIdx, 3) = getBufferStatus(UEs{ueIdx}); % Read pending buffer (in bytes) on UE
            end
            if obj.DuplexMode == 1 % TDD
                symbolType = currentSymbolType(gNB.MACEntity); % Get current symbol type: DL/UL/Guard
                if(symbolType == 0 && linkDir ~= 1) % DL
                    metrics = obj.UEMetricsDL;
                    metrics(:, 1:2) = metrics(:, 1:2) - obj.PrevUEMetricsDL(:, 1:2);
                    obj.PrevUEMetricsDL = obj.UEMetricsDL;
                    logScheduling(obj, symbolNum, [resourceAssignmentsUL resourceAssignmentsDL], metrics, obj.DownlinkChannelQuality, obj.HARQProcessStatusDL, symbolType);
                elseif(symbolType == 1 && linkDir ~= 0) % UL
                    metrics = obj.UEMetricsUL;
                    metrics(:, 1:2) = metrics(:, 1:2) - obj.PrevUEMetricsUL(:, 1:2);
                    obj.PrevUEMetricsUL = obj.UEMetricsUL;
                    logScheduling(obj, symbolNum, [resourceAssignmentsUL resourceAssignmentsDL], metrics, obj.UplinkChannelQuality, obj.HARQProcessStatusUL, symbolType);
                else % Guard
                    logScheduling(obj, symbolNum, [resourceAssignmentsUL resourceAssignmentsDL], zeros(obj.NumUEs, 3), zeros(obj.NumUEs, obj.NumRBs(1)), zeros(obj.NumUEs, 16), symbolType); % UL
                end
            else
                % Store the scheduling logs
                if linkDir ~= 1 %  DL
                    metrics = obj.UEMetricsDL;
                    metrics(:, 1:2) = metrics(:, 1:2) - obj.PrevUEMetricsDL(:, 1:2);
                    obj.PrevUEMetricsDL = obj.UEMetricsDL;
                    logScheduling(obj, symbolNum, resourceAssignmentsDL, metrics, obj.DownlinkChannelQuality, obj.HARQProcessStatusDL, 0); % DL
                end
                if linkDir ~= 0 % UL
                    metrics = obj.UEMetricsUL;
                    metrics(:, 1:2) = metrics(:, 1:2) - obj.PrevUEMetricsUL(:, 1:2);
                    obj.PrevUEMetricsUL = obj.UEMetricsUL;
                    logScheduling(obj, symbolNum, resourceAssignmentsUL, metrics, obj.UplinkChannelQuality, obj.HARQProcessStatusUL, 1); % UL
                end
            end

            % Invoke the dependent events after every slot
            if obj.SchedulingType
                if mod(symbolNum, 14) == 0 && symbolNum > 1
                    % Invoke the events at the last symbol of the slot
                    invokeDepEvents(obj, (symbolNum/14));
                end
            else
                % Invoke the events at the first symbol of the last slot in a frame
                if mod(symbolNum-1, 14) == 0 && symbolNum > 1
                    invokeDepEvents(obj, ((symbolNum-1)/14)+1);
                end
            end
        end

        function logScheduling(obj, symbolNumSimulation, resourceAssignments, UEMetrics, UECQIs, HarqProcessStatus, type)
            %logScheduling Log the scheduling operations
            %
            % logScheduling(OBJ, SYMBOLNUMSIMULATION, RESOURCEASSIGNMENTS,
            % UEMETRICS, UECQIS, HARQPROCESSSTATUS, RXRESULTUES, TYPE) Logs
            % the scheduling operations based on the input arguments
            %
            % SYMBOLNUMSIMULATION - Cumulative symbol number in the
            % simulation
            %
            % RESOURCEASSIGNMENTS - Resource assignment information.
            %
            % UEMETRICS - N-by-P matrix where N represents the number of
            % UEs and P represents the number of metrics collected.
            %
            % UECQIs - N-by-P matrix where N represents the number of
            % UEs and P represents the number of RBs.
            %
            % HARQPROCESSSTATUS - N-by-P matrix where N represents the number of
            % UEs and P represents the number of HARQ process.
            %
            % TYPE - Type will be based on scheduling type.
            %        - In slot based scheduling type takes two values.
            %          type = 0, represents the downlink and type = 1,
            %          represents uplink.
            %
            %        - In symbol based scheduling type takes three values.
            %          type = 0, represents the downlink, type = 1,
            %          represents uplink and type = 2 represents guard.

            % Determine the log index based on link type and duplex mode
            if obj.DuplexMode == obj.FDDDuplexMode
                if  type == 0
                    linkIndex = obj.DownlinkIdx; % Downlink log
                else
                    linkIndex = obj.UplinkIdx; % Uplink log
                end
            else
                % TDD
                linkIndex = 1;
            end

            % Calculate symbol number in slot (0-13), slot number in frame
            % (0-obj.NumSlotsFrame), and frame number in the simulation.
            slotDuration = 10/obj.NumSlotsFrame;
            obj.CurrSymbol = mod(symbolNumSimulation - 1, obj.NumSym);
            obj.CurrSlot = mod(floor((symbolNumSimulation - 1)/obj.NumSym), obj.NumSlotsFrame);
            obj.CurrFrame = floor((symbolNumSimulation-1)/(obj.NumSym * obj.NumSlotsFrame));
            timestamp = obj.CurrFrame * 10 + (obj.CurrSlot * slotDuration) + (obj.CurrSymbol * (slotDuration / 14));

            columnMap = obj.ColumnIndexMap;
            grantLogsColumnIndexMap = obj.GrantLogsColumnIndexMap;
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, columnMap('Timestamp')} = timestamp;
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, columnMap('Frame Number')} = obj.CurrFrame;
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, columnMap('Slot Number')} = obj.CurrSlot;
            if obj.SchedulingType % Symbol based scheduling
                obj.SchedulingLog{linkIndex}{symbolNumSimulation, columnMap('Symbol Number')} = obj.CurrSymbol;
            end

            if(obj.DuplexMode == obj.TDDDuplexMode) % TDD
                % Log the type: DL/UL/Guard
                switch(type)
                    case 0
                        symbolTypeDesc = 'DL';
                    case 1
                        symbolTypeDesc = 'UL';
                    case 2
                        symbolTypeDesc = 'Guard';
                end
                obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('Type')} = symbolTypeDesc;
            end

            for j = 1:length(resourceAssignments)
                % Fill logs w.r.t. each assignment
                assignment = resourceAssignments{j};
                % Calculate row number in the logs, for the Tx start
                % symbol
                logIndex = (obj.CurrFrame * obj.NumSlotsFrame * obj.NumSym) +  ...
                    ((obj.CurrSlot + assignment.SlotOffset) * obj.NumSym) + assignment.StartSymbol + 1;

                allottedUE = assignment.RNTI;

                % Fill the start Tx symbol logs
                obj.SchedulingLog{linkIndex}{logIndex, columnMap('RBG Allocation Map')}(allottedUE, :) = assignment.RBGAllocationBitmap;
                obj.SchedulingLog{linkIndex}{logIndex, columnMap('UEs MCS')}(allottedUE) = assignment.MCS;
                obj.SchedulingLog{linkIndex}{logIndex, columnMap('HARQ Process ID')}(allottedUE) = assignment.HARQID;
                obj.SchedulingLog{linkIndex}{logIndex, columnMap('Grant NDI Flag')}(allottedUE) = assignment.NDI;
                if obj.SchedulingType % Symbol based scheduling
                    obj.SchedulingLog{linkIndex}{logIndex, columnMap('Transmission')}(allottedUE) = {strcat(assignment.Type, '-Start')};
                    % Fill the logs from the symbol after Tx start, up to
                    % the symbol before Tx end
                    for k = 1:assignment.NumSymbols-2
                        obj.SchedulingLog{linkIndex}{logIndex + k, columnMap('RBG Allocation Map')}(allottedUE, :) = assignment.RBGAllocationBitmap;
                        obj.SchedulingLog{linkIndex}{logIndex + k, columnMap('UEs MCS')}(allottedUE) = assignment.MCS;
                        obj.SchedulingLog{linkIndex}{logIndex + k, columnMap('HARQ Process ID')}(allottedUE) = assignment.HARQID;
                        obj.SchedulingLog{linkIndex}{logIndex + k, columnMap('Grant NDI Flag')}(allottedUE) = assignment.NDI;
                        obj.SchedulingLog{linkIndex}{logIndex + k, columnMap('Transmission')}(allottedUE) = {strcat(assignment.Type, '-InProgress')};
                    end

                    % Fill the last Tx symbol logs
                    obj.SchedulingLog{linkIndex}{logIndex + assignment.NumSymbols -1, columnMap('RBG Allocation Map')}(allottedUE, :) = assignment.RBGAllocationBitmap;
                    obj.SchedulingLog{linkIndex}{logIndex + assignment.NumSymbols -1, columnMap('UEs MCS')}(allottedUE) = assignment.MCS;
                    obj.SchedulingLog{linkIndex}{logIndex + assignment.NumSymbols -1, columnMap('HARQ Process ID')}(allottedUE) = assignment.HARQID;
                    obj.SchedulingLog{linkIndex}{logIndex + assignment.NumSymbols -1, columnMap('Grant NDI Flag')}(allottedUE) = assignment.NDI;
                    obj.SchedulingLog{linkIndex}{logIndex + assignment.NumSymbols -1, columnMap('Transmission')}(allottedUE) = {strcat(assignment.Type, '-End')};
                else % Slot based scheduling
                    obj.SchedulingLog{linkIndex}{logIndex, columnMap('Transmission')}(allottedUE) = {assignment.Type};
                end
                obj.GrantCount  = obj.GrantCount + 1;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('RNTI')} = assignment.RNTI;
                slotNumGrant = mod(obj.CurrSlot + assignment.SlotOffset, obj.NumSlotsFrame);
                if(obj.CurrSlot + assignment.SlotOffset >= obj.NumSlotsFrame)
                    frameNumGrant = obj.CurrFrame + 1; % Assignment is for a slot in next frame
                else
                    frameNumGrant = obj.CurrFrame;
                end
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Frame')} = frameNumGrant;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Slot')} = slotNumGrant;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('RBG Allocation Map')} = mat2str(assignment.RBGAllocationBitmap);
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Start Sym')} = assignment.StartSymbol;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Num Sym')} = assignment.NumSymbols;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('MCS')} = assignment.MCS;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('NumLayers')} = assignment.NumLayers;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('HARQ ID')} = assignment.HARQID;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('NDI Flag')} = assignment.NDI;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('RV')} = assignment.RV;
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Tx Type')} = assignment.Type;
                if(isfield(assignment, 'FeedbackSlotOffset'))
                    % DL grant
                    obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Feedback Slot Offset (DL grants only)')} = assignment.FeedbackSlotOffset;
                    obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Grant type')} = 'DL';
                else
                    % UL Grant
                    obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('Grant type')} = 'UL';
                end
                obj.GrantLog{obj.GrantCount, grantLogsColumnIndexMap('CQI on RBs')} = mat2str(UECQIs(assignment.RNTI, :));
            end

            obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('Channel Quality')} = UECQIs;
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('HARQ process NDI status (at symbol start)')} = HarqProcessStatus;
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('Throughput Bytes')} = UEMetrics(:, 1); % Throughput bytes sent by UEs
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('Goodput Bytes')} = UEMetrics(:, 2); % Goodput bytes sent by UEs
            obj.SchedulingLog{linkIndex}{symbolNumSimulation, obj.ColumnIndexMap('Buffer status of UEs (In bytes)')} = UEMetrics(:, 3); % Current buffer status of UEs in bytes
        end

        function varargout = getSchedulingLogs(obj)
            %getSchedulingLogs Get the per-symbol logs of the whole simulation

            % Get keys of columns (i.e. column names) in sorted order of values (i.e. column indices)
            [~, idx] = sort(cell2mat(values(obj.ColumnIndexMap)));
            columnTitles = keys(obj.ColumnIndexMap);
            columnTitles = columnTitles(idx);
            varargout = cell(obj.NumLogs, 1);

            for logIdx = 1:obj.NumLogs
                if isempty(obj.SchedulingLog{logIdx})
                    continue;
                end
                if obj.SchedulingType
                    % Symbol based scheduling
                    finalLogIndex = (obj.CurrFrame)*obj.NumSlotsFrame*obj.NumSym + (obj.CurrSlot)*obj.NumSym + obj.CurrSymbol + 1;
                    obj.SchedulingLog{logIdx} = obj.SchedulingLog{logIdx}(1:finalLogIndex, :);
                    % For symbol based scheduling, keep 1 row per symbol
                    varargout{logIdx} = [columnTitles; obj.SchedulingLog{logIdx}(1:finalLogIndex, :)];
                else
                    % Slot based scheduling
                    finalLogIndex = (obj.CurrFrame)*obj.NumSlotsFrame*obj.NumSym + (obj.CurrSlot+1)*obj.NumSym;
                    obj.SchedulingLog{logIdx} = obj.SchedulingLog{logIdx}(1:finalLogIndex, :);
                    % For slot based scheduling: keep 1 row per slot and eliminate symbol number as a column title
                    varargout{logIdx} = [columnTitles; obj.SchedulingLog{logIdx}(1:obj.NumSym:finalLogIndex, :)];
                end
            end
        end

        function logs = getGrantLogs(obj)
            %getGrantLogs Get the scheduling assignment logs of the whole simulation

            % Get keys of columns (i.e. column names) in sorted order of values (i.e. column indices)
            [~, idx] = sort(cell2mat(values(obj.GrantLogsColumnIndexMap)));
            columnTitles = keys(obj.GrantLogsColumnIndexMap);
            columnTitles = columnTitles(idx);
            % Read valid rows
            obj.GrantLog = obj.GrantLog(1:obj.GrantCount, :);
            logs = [columnTitles; obj.GrantLog];
        end

        function [dlStats, ulStats] = getPerformanceIndicators(obj)
            %getPerformanceIndicators Outputs the data rate, spectral
            % efficiency values
            %
            % DLSTATS - 5-by-1 array containing the following statistics in
            %           the downlink direction: Theoretical peak data rate,
            %           achieved data rate, theoretical peak spectral
            %           efficiency, achieved spectral efficiency, achieved
            %           goodput
            % ULSTATS - 5-by-1 array containing the following statistics in
            %           the uplink direction: Theoretical peak data rate,
            %           achieved data rate, theoretical peak spectral
            %           efficiency, achieved spectral efficiency, achieved
            %           goodput

            if obj.DuplexMode == obj.FDDDuplexMode
                if ismember(obj.DownlinkIdx, obj.PlotIds)
                    totalDLTxBytes = sum(cell2mat(obj.SchedulingLog{obj.DownlinkIdx}(:,  obj.ColumnIndexMap('Throughput Bytes'))));
                    totalDLNewTxBytes = sum(cell2mat(obj.SchedulingLog{obj.DownlinkIdx}(:,  obj.ColumnIndexMap('Goodput Bytes'))));
                end
                if ismember(obj.UplinkIdx, obj.PlotIds)
                    totalULTxBytes = sum(cell2mat(obj.SchedulingLog{obj.UplinkIdx}(:,  obj.ColumnIndexMap('Throughput Bytes'))));
                    totalULNewTxBytes = sum(cell2mat(obj.SchedulingLog{obj.UplinkIdx}(:,  obj.ColumnIndexMap('Goodput Bytes'))));
                end
            else
                dlIdx = strcmp(obj.SchedulingLog{1}(:, obj.ColumnIndexMap('Type')), 'DL');
                totalDLTxBytes = sum(cell2mat(obj.SchedulingLog{1}(dlIdx,  obj.ColumnIndexMap('Throughput Bytes'))));
                totalDLNewTxBytes = sum(cell2mat(obj.SchedulingLog{1}(dlIdx,  obj.ColumnIndexMap('Goodput Bytes'))));
                ulIdx = strcmp(obj.SchedulingLog{1}(:, obj.ColumnIndexMap('Type')), 'UL');
                totalULTxBytes = sum(cell2mat(obj.SchedulingLog{1}(ulIdx,  obj.ColumnIndexMap('Throughput Bytes'))));
                totalULNewTxBytes = sum(cell2mat(obj.SchedulingLog{1}(ulIdx,  obj.ColumnIndexMap('Goodput Bytes'))));
            end
            dlStats = zeros(5, 1);
            ulStats = zeros(5, 1);

            % Downlink stats
            if ismember(obj.DownlinkIdx, obj.PlotIds)
                dlStats(1, 1) = obj.PeakDataRateDL;
                dlStats(2, 1) = totalDLTxBytes * 8 ./ (obj.NumFrames * 0.01 * 1000 * 1000); % Mbps
                dlStats(3, 1) = obj.PeakDLSpectralEfficiency;
                dlStats(4, 1) = 1e6*dlStats(2, 1)/obj.Bandwidth(obj.DownlinkIdx);
                dlStats(5, 1) = totalDLNewTxBytes * 8 ./ (obj.NumFrames * 0.01 * 1000 * 1000); % Mbps
            end
            % Uplink stats
            if ismember(obj.UplinkIdx, obj.PlotIds)
                ulStats(1, 1) = obj.PeakDataRateUL;
                ulStats(2, 1) = totalULTxBytes * 8 ./ (obj.NumFrames * 0.01 * 1000 * 1000); % Mbps
                ulStats(3, 1) = obj.PeakULSpectralEfficiency;
                ulStats(4, 1) = 1e6*ulStats(2, 1)/obj.Bandwidth(obj.UplinkIdx);
                ulStats(5, 1) = totalULNewTxBytes * 8 ./ (obj.NumFrames * 0.01 * 1000 * 1000); % Mbps
            end
        end
        
        function addDepEvent(obj, callbackFcn, numSlots)
            %addDepEvent Adds an event to the events list
            %
            % addDepEvent(obj, callbackFcn, numSlots) Adds an event to the
            % event list
            %
            % CALLBACKFCN - Handle of the function to be invoked
            %
            % NUMSLOTS - Periodicity at which function has to be invoked

            % Create event
            event = struct('CallbackFcn', callbackFcn, 'InvokePeriodicity', numSlots);
            obj.Events = [obj.Events  event];
        end
    end

    methods( Access = private)
        function invokeDepEvents(obj, slotNum)
            numEvents = length(obj.Events);
            for idx=1:numEvents
                event = obj.Events(idx);
                if isempty(event.InvokePeriodicity)
                    event.CallbackFcn(slotNum);
                else
                    invokePeriodicity = event.InvokePeriodicity;
                    if mod(slotNum, invokePeriodicity) == 0
                        event.CallbackFcn(slotNum);
                    end
                end
            end
            % Invoke the pending callbacks
            drawnow;
        end

        function logFormat = constructLogFormat(obj, linkIdx, simParam)
            %constructLogFormat Construct log format

            columnIndex = 1;
            logFormat{1, columnIndex} = 0; % Timestamp (in milliseconds)
            obj.ColumnIndexMap('Timestamp') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = 0; % Frame number
            obj.ColumnIndexMap('Frame Number') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} =  0; % Slot number
            obj.ColumnIndexMap('Slot Number') = columnIndex;

            if(obj.SchedulingType == 1)
                % Symbol number column is only for symbol-based
                % scheduling
                columnIndex = columnIndex + 1;
                logFormat{1, columnIndex} =  0; % Symbol number
                obj.ColumnIndexMap('Symbol Number') = columnIndex;
            end
            if(obj.DuplexMode == obj.TDDDuplexMode)
                % Slot/symbol type as DL/UL/guard is only for TDD mode
                columnIndex = columnIndex + 1;
                logFormat{1, columnIndex} = 'Guard'; % Symbol type
                obj.ColumnIndexMap('Type') = columnIndex;
            end
            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, ceil(obj.NumRBs(linkIdx) / obj.RBGSize(linkIdx))); % RBG allocation for UEs
            obj.ColumnIndexMap('RBG Allocation Map') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1*ones(obj.NumUEs, 1); % MCS for assignments
            obj.ColumnIndexMap('UEs MCS') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1*ones(obj.NumUEs, 1); % HARQ IDs for assignments
            obj.ColumnIndexMap('HARQ Process ID') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1*ones(obj.NumUEs, 1); % NDI flag for assignments
            obj.ColumnIndexMap('Grant NDI Flag') = columnIndex;

            % Tx type of the assignments ('newTx' or 'reTx'), 'noTx' if there is no assignment
            txTypeUEs =  cell(obj.NumUEs, 1);
            txTypeUEs(:) = {'noTx'};
            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = txTypeUEs;
            obj.ColumnIndexMap('Transmission') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, obj.NumRBs(linkIdx)); % Channel quality
            obj.ColumnIndexMap('Channel Quality') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, obj.NumHARQ); % HARQ process status
            obj.ColumnIndexMap('HARQ process NDI status (at symbol start)') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % MAC bytes transmitted
            obj.ColumnIndexMap('Throughput Bytes') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % MAC bytes corresponding to a new transmission
            obj.ColumnIndexMap('Goodput Bytes') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % UEs' buffer status
            obj.ColumnIndexMap('Buffer status of UEs (In bytes)') = columnIndex;

            % Initialize scheduling log for all the symbols in the
            % simulation time. The last time scheduler runs in the
            % simulation, it might assign resources for future slots which
            % are outside of simulation time. Storing those decisions too
            numSlotsSim = simParam.numFrames * obj.NumSlotsFrame; % Simulation time in units of slot duration
            logFormat = repmat(logFormat(1,:), (numSlotsSim + obj.NumSlotsFrame)*obj.NumSym , 1);
        end

        function logFormat = constructGrantLogFormat(obj, simParam)
            %constructGrantLogFormat Construct grant log format

            columnIndex = 1;
            logFormat{1, columnIndex} = -1; % UE's RNTI
            obj.GrantLogsColumnIndexMap('RNTI') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % Frame number
            obj.GrantLogsColumnIndexMap('Frame') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % Slot number
            obj.GrantLogsColumnIndexMap('Slot') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = {''}; % Type: UL or DL
            obj.GrantLogsColumnIndexMap('Grant type') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = {''}; % RBG allocation for UEs
            obj.GrantLogsColumnIndexMap('RBG Allocation Map') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % Start sym
            obj.GrantLogsColumnIndexMap('Start Sym') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % Num sym
            obj.GrantLogsColumnIndexMap('Num Sym') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % MCS Value
            obj.GrantLogsColumnIndexMap('MCS') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % Number of layers
            obj.GrantLogsColumnIndexMap('NumLayers') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % HARQ IDs for assignments
            obj.GrantLogsColumnIndexMap('HARQ ID') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % NDI flag for assignments
            obj.GrantLogsColumnIndexMap('NDI Flag') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = -1; % RV for assignments
            obj.GrantLogsColumnIndexMap('RV') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = {''}; % Tx type: new-Tx or re-Tx
            obj.GrantLogsColumnIndexMap('Tx Type') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = {'NA'}; % PDSCH feedback slot offset (Only applicable for DL grants)
            obj.GrantLogsColumnIndexMap('Feedback Slot Offset (DL grants only)') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = {''}; % CQI values
            obj.GrantLogsColumnIndexMap('CQI on RBs') = columnIndex;

            % Initialize scheduling log for all the symbols in the
            % simulation time. The last time scheduler runs in the
            % simulation, it might assign resources for future slots which
            % are outside of simulation time. Storing those decisions too
            if(obj.SchedulingType == 1 && isfield(simParam, 'ttiGranularity'))
                maxRows = obj.NumFrames*obj.NumSlotsFrame*obj.NumUEs*(ceil(obj.NumSym/simParam.ttiGranularity));
            else
                maxRows = obj.NumFrames*obj.NumSlotsFrame*obj.NumUEs;
            end
            logFormat = repmat(logFormat(1,:), maxRows , 1);
        end

    end
end