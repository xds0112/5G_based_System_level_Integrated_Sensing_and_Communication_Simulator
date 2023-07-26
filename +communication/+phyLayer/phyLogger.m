classdef phyLogger < handle
    %phyRxBuffer Phy statistics logging object
    %   The class implements per slot/symbol logging mechanism
    %   of the physical layer metrics. It is used to log the statistics of a cell

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %NCellID Cell ID to which the logging belongs
        NCellID (1, 1) {mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1;

        % NumUEs Count of UEs in a cell
        NumUEs

        % NumSlotsFrame Number of slots in a 10ms time frame
        NumSlotsFrame

        % BLERStatsLog Slot-by-slot/symbol-by-symbol log of the block error rate (BLER) statistics
        BLERStatsLog
        
        % ColumnIndexMap Mapping the column names of logs to respective column indices
        % It is a map object
        ColumnIndexMap

        % SchedulingType Type of scheduling (slot based or symbol based)
        % Value 0 means slot based and value 1 means symbol based. The
        % default value is 0
        SchedulingType (1, 1) {mustBeInteger, mustBeInRange(SchedulingType, 0, 1)} = 0;
    end
    
    properties (GetAccess = public, SetAccess = private)
        % UEIdList RNTIs of UEs in a cell as row vector
        UEIdList
    end

    properties(Access = private, Hidden)
        % CurrSlot Current slot in the frame
        % It is incremented by 1 slot for every NumSym symbols
        CurrSlot = -1

        % CurrFrame Current frame
        % It is incremented by 1 frame for every NumSlotsFrame slots
        CurrFrame = -1
        
        % CurrSymbol Current symbol
        % It is updated for every call to logBLERStats
        CurrSymbol = -1
        
        %UEBLERStats Downlink BLER values for the current symbol
        % It is an N-by-2 array, where N is the number of UEs. First and
        % second columns of the array contains the number of erroneous
        % packets received and the total number of received packets for 
        % each UE respectively
        UEBLERStats

        %GNBBLERStats Uplink BLER values for the current symbol
        % It is an N-by-2 array, where N is the number of UEs. First and
        % second columns of the array contains the number of erroneous packets
        % received and the total number of received packets from each UE
        % respectively
        GNBBLERStats

        %PrevCumulativeULBlkErr Cumulative uplink block error information returned in the last query
        % It is an array of size N-by-2 where N is the number of UEs,
        % columns 1 and 2 contains the number of erroneously received
        % packets and total received packets, respectively
        PrevCumulativeULBlkErr

        %PrevCumulativeDLBlkErr Cumulative downlink block error information returned in the last query
        % It is an array of size N-by-2 where N is the number of UEs,
        % columns 1 and 2 contains the number of erroneously received
        % packets and total received packets, respectively
        PrevCumulativeDLBlkErr
    end

    properties (Access = private, Constant, Hidden)
        % Constants related to downlink and uplink information. These
        % constants are used for indexing logs and identifying plots
        %DownlinkIdx Index for all downlink information
        DownlinkIdx = 1;
        %UplinkIdx Index for all uplink information
        UplinkIdx = 2;

        %NumSym Number of symbols in a slot
        NumSym = 14;
    end

    methods (Access = public)
        function obj = phyLogger(simParameters)
            %phyRxBuffer Construct Phy logging object
            %
            % OBJ = hNRPhyLogger(SIMPARAMETERS) Create a Phy logging object.
            %
            % SIMPARAMETERS - It is a structure with the following fields
            %
            %   NumUEs            - Number of UEs
            %   NCellID           - Cell identifier
            %   SCS               - Subcarrier spacing
            %   SchedulingType    - Slot-based (value 0) or symbol-based (value 1) scheduling
            %   DuplexMode        - FDD (value 0) or TDD (value 1)

            if isfield(simParameters, 'cellID')
                obj.NCellID = simParameters.cellID;
            end
            if isfield(simParameters, 'schedulingType')
                obj.SchedulingType = simParameters.schedulingType;
            end
            obj.ColumnIndexMap = containers.Map('KeyType','char','ValueType','double');
            obj.NumUEs = simParameters.numUEs;
            obj.UEIdList = 1:obj.NumUEs;
            obj.NumSlotsFrame = (10 * simParameters.scs) / 15; % Number of slots in a 10 ms frame

            % BLER stats
            % Each row represents the statistics of each slot
            obj.BLERStatsLog = constructLogFormat(obj, simParameters);
            
            obj.UEBLERStats = zeros(obj.NumUEs, 2);
            obj.GNBBLERStats = zeros(obj.NumUEs, 2);
            obj.PrevCumulativeULBlkErr = zeros(obj.NumUEs, 2);
            obj.PrevCumulativeDLBlkErr = zeros(obj.NumUEs, 2);
        end
        
        function [dlPhyMetrics, ulPhyMetrics] = getPhyMetrics(obj, firstSlot, lastSlot, rntiList)
            %getPhyMetrics Return the Phy metrics
            %
            % [DLMETRICS, ULMETRICS] = getPhyMetrics(OBJ, FIRSTSLOT,
            % LASTSLOT, RNTILIST) Returns the Phy metrics of the UEs with
            % specified RNTIs for both uplink and downlink
            %
            % FIRSTSLOT - Represents the starting slot number for
            % querying the metrics
            %
            % LASTSLOT -  Represents the ending slot for querying the
            % metrics
            %
            % RNTI - Radio network temporary identifier of a UE
            %
            % ULPHYMETRICS - It contains Phy metrics in uplink direction
            %
            % DLPHYMETRICS - It contains Phy metrics in downlink direction
            %
            % ULPHYMETRICS and DLPHYMETRICS are structures with following properties
            %
            %   RNTI - Radio network temporary identifier of a UE
            %
            %   ErroneousPackets - Number of erroneous packets
            %
            %   TotalPackets - Total number of packets
            
            outputStruct = repmat(struct('RNTI',0,'TotalPackets',0,'ErroneousPackets',0),[numel(rntiList) 2]);
            stepLogStartIdx = (firstSlot-1) * obj.NumSym + 1;
            stepLogEndIdx = lastSlot * obj.NumSym;
            columnMap = obj.ColumnIndexMap;
            metricsColumnIndex = [columnMap('Number of Erroneous Packets(DL)'),...
                columnMap('Number of Packets(DL)'); columnMap('Number of Erroneous Packets(UL)'),...
                columnMap('Number of Packets(UL)')];
            
            % Index at which UE's information is stored
            [~,ueIdxList] = ismember(rntiList, obj.UEIdList);
            for logIdx = 1:2
                blerLogs = zeros(numel(rntiList), 2);
                for stepIdx = stepLogStartIdx:stepLogEndIdx
                    blerLogs(:, 1) = blerLogs(:, 1) + obj.BLERStatsLog{stepIdx, metricsColumnIndex(logIdx, 1)}(ueIdxList);
                    blerLogs(:, 2) = blerLogs(:, 2) + obj.BLERStatsLog{stepIdx, metricsColumnIndex(logIdx, 2)}(ueIdxList);
                end
                
                for ueIdx = 1:numel(rntiList)
                    outputStruct(ueIdx, logIdx).RNTI = rntiList(ueIdx);
                    outputStruct(ueIdx, logIdx).ErroneousPackets = blerLogs(ueIdx, 1);
                    outputStruct(ueIdx, logIdx).TotalPackets = blerLogs(ueIdx, 2);
                end
            end
            
            dlPhyMetrics = outputStruct(:, obj.DownlinkIdx);
            ulPhyMetrics = outputStruct(:, obj.UplinkIdx);
        end
        
        function logCellPhyStats(obj, symbolNum, gNB, UEs)
            %logCellPhyStats Log the Phy layer statistics
            %
            % LOGCELLPHYSTATS(OBJ, SYMBOLNUM, GNB, UES) Logs the BLER stats
            % for all the nodes in the cell
            %
            % SYMBOLNUM - Symbol number in the simulation
            %
            % GNB - It is an object of type hNRGNB and contains information
            % about the gNB
            % UEs - It is a cell array of length equal to the number of UEs
            % in the cell. Each element of the array is an object of type
            % hNRUE.

            % Read the DL BLER for each UE
            for ueIdx = 1:obj.NumUEs
                stats = UEs{ueIdx}.PhyEntity.DLBlkErr;
                obj.UEBLERStats(ueIdx, :) = stats - obj.PrevCumulativeDLBlkErr(ueIdx, :);
                obj.PrevCumulativeDLBlkErr(ueIdx, :) = stats;
            end
            % Read the UL BLER for each UE from gNB
            stats = gNB.PhyEntity.ULBlkErr;
            obj.GNBBLERStats = stats - obj.PrevCumulativeULBlkErr;
            obj.PrevCumulativeULBlkErr = stats;
            % Log the UL and DL error logs
            logBLERStats(obj, symbolNum, obj.UEBLERStats, obj.GNBBLERStats);
        end

        function logBLERStats(obj, symbolNumSimulation, ueBLERStats, gNBBLERStats)
            %logBLERStats Log the block error rate (BLER) statistics
            %
            % logBLERtats(OBJ, SYMBOLNUMSIMULATION, UEBLERSTATS, GNBBLERSTATS) Logs the BLER
            % statistics
            %
            % SYMBOLNUMSIMULATION - Symbol number in the simulation
            %
            % UEBLERSTATS - Represents a N-by-2 array, where N is the number
            % of UEs. First and second columns of the array contains the
            % number of erroneous packets received and the total number of
            % received packets for each UE
            %
            % GNBBLERSTATS - Represents a N-by-2 array, where N is the number
            % of UEs. First and second columns of the array contains the
            % number of erroneous packets received and the total number of
            % received packets from each UE
            
            if isempty(ueBLERStats) % Downlink BLER stats
                ueBLERStats = zeros(obj.NumUEs, 2);
            end
            if isempty(gNBBLERStats) % Uplink BLER stats
                gNBBLERStats = zeros(obj.NumUEs, 2);
            end
            
            columnMap = obj.ColumnIndexMap;            
            % Calculate symbol number in slot (0-13), slot number in frame
            % (0-obj.NumSlotsFrame), frame number, and timestamp(in milliseconds) in the simulation.
            slotDuration = 10/obj.NumSlotsFrame;
            obj.CurrSymbol = mod(symbolNumSimulation - 1, obj.NumSym);
            obj.CurrSlot = mod(floor((symbolNumSimulation - 1)/obj.NumSym), obj.NumSlotsFrame);
            obj.CurrFrame = floor((symbolNumSimulation-1)/(obj.NumSym * obj.NumSlotsFrame));
            timestamp = obj.CurrFrame * 10 + (obj.CurrSlot * slotDuration) + (obj.CurrSymbol * (slotDuration / 14));

            logIndex = (obj.CurrFrame * obj.NumSlotsFrame * obj.NumSym) +  ...
                (obj.CurrSlot * obj.NumSym) + obj.CurrSymbol + 1;
            obj.BLERStatsLog{logIndex, columnMap('Timestamp')} = timestamp;
            obj.BLERStatsLog{logIndex, columnMap('Frame Number')} = obj.CurrFrame;
            obj.BLERStatsLog{logIndex, columnMap('Slot Number')} = obj.CurrSlot;
            obj.BLERStatsLog{logIndex, columnMap('Symbol Number')} = obj.CurrSymbol;
            
            % Number of erroneous packets in downlink
            obj.BLERStatsLog{logIndex, columnMap('Number of Erroneous Packets(DL)')} = ueBLERStats(:, 1);
            % Number of packets in downlink
            obj.BLERStatsLog{logIndex, columnMap('Number of Packets(DL)')} = ueBLERStats(:, 2);
            % Number of erroneous packets in uplink
            obj.BLERStatsLog{logIndex, columnMap('Number of Erroneous Packets(UL)')} = gNBBLERStats(:, 1);
            % Number of packets in uplink
            obj.BLERStatsLog{logIndex, columnMap('Number of Packets(UL)')} = gNBBLERStats(:, 2);
        end

        function [blerLogs, avgBLERLogs] = getBLERLogs(obj)
            %GETBLERLOGS Return the Block Error Rate logs
            %
            % [BLERLOGS, AVGBLERRLOGS] = getBLERLogs(OBJ) Returns the Block Error Rate logs
            %
            % BLERLOGS - It is (N+2)-by-P cell, where N represents the
            % number of slots in the simulation and P represents the number
            % of columns for slot-based scheduling. For symbol-based
            % scheduling, N represents the number of symbols in the simulation.
            % The first row of the logs contains titles for the logs. The 
            % last row of the logs contains the cumulative statistics for 
            % the entire simulation. Each row (excluding the first and last rows)
            % in the logs represents a slot and contains the following information.
            %  Frame                           - Frame number.
            %  Slot                            - Slot number in the frame.
            %  Symbol number                   - Symbol number in the slot
            %  Number of Erroneous Packets(DL) - N-by-1 array, where N is the
            %                                    number of UEs. Each
            %                                    element contains the
            %                                    number of erroneous
            %                                    packets in the downlink
            %  Number of Packets(DL)           - N-by-1 array, where N is the
            %                                    number of UEs. Each
            %                                    element contains the
            %                                    number of packets in the downlink
            %  Number of Erroneous Packets(UL) - N-by-1 array, where N is the
            %                                    number of UEs. Each
            %                                    element contains the
            %                                    number of erroneous
            %                                    packets in the uplink
            %  Number of Packets(UL)           - N-by-1 array, where N is the
            %                                    number of UEs. Each
            %                                    element contains the
            %                                    number of packets in the uplink
            %
            %  AVGBLERLOGS - Average block error rate in the downlink and 
            %  uplink. It is a N-by-2 array, where N represents the number 
            %  of UEs. First and second columns of the array contain the
            %  downlink and uplink information respectively.

            % Get keys of columns (i.e. column names) in sorted order of values (i.e. column indices)
            [~, idx] = sort(cell2mat(values(obj.ColumnIndexMap)));
            columnTitles = keys(obj.ColumnIndexMap);
            columnTitles = columnTitles(idx);

            % Most recent log index for the current simulation
            lastLogIndex = (obj.CurrFrame)*obj.NumSlotsFrame*obj.NumSym + (obj.CurrSlot+1)*obj.NumSym;
            totalULPackets = zeros(obj.NumUEs, 1);
            totalErrULPackets = zeros(obj.NumUEs, 1);
            totalDLPackets = zeros(obj.NumUEs, 1);
            totalErrDLPackets = zeros(obj.NumUEs, 1);
            columnMap = obj.ColumnIndexMap;

            % Calculate statistics for the entire simulation
            for idx = 1:lastLogIndex
                totalErrDLPackets = totalErrDLPackets + obj.BLERStatsLog{idx, columnMap('Number of Erroneous Packets(DL)')};
                totalDLPackets = totalDLPackets + obj.BLERStatsLog{idx, columnMap('Number of Packets(DL)')};
                totalErrULPackets = totalErrULPackets + obj.BLERStatsLog{idx, columnMap('Number of Erroneous Packets(UL)')};
                totalULPackets = totalULPackets + obj.BLERStatsLog{idx, columnMap('Number of Packets(UL)')};
            end

            avgBLERLogs = zeros(obj.NumUEs, 2);
            % Update last row of BLERStatsLog
            % Assign average DL BLER to the first column
            avgBLERLogs(:, 1) = totalErrDLPackets./totalDLPackets;
            % Assign average UL BLER to the second column
            avgBLERLogs(:, 2) = totalErrULPackets./totalULPackets;
            % Setting stats equal to zero if no packets received
            avgBLERLogs(isnan(avgBLERLogs)) = 0;
            blerLogs = [columnTitles; obj.BLERStatsLog(1:lastLogIndex , :)];
        end
    end

    methods(Access = private)
        function logFormat = constructLogFormat(obj, simParam)
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

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} =  0; % Symbol number
            obj.ColumnIndexMap('Symbol Number') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % Number of erroneous packets in the downlink direction
            obj.ColumnIndexMap('Number of Erroneous Packets(DL)') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % Number of packets in the downlink direction
            obj.ColumnIndexMap('Number of Packets(DL)') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % Number of erroneous packets in the uplink direction
            obj.ColumnIndexMap('Number of Erroneous Packets(UL)') = columnIndex;

            columnIndex = columnIndex + 1;
            logFormat{1, columnIndex} = zeros(obj.NumUEs, 1); % Number of packets in the uplink direction
            obj.ColumnIndexMap('Number of Packets(UL)') = columnIndex;

            % Initialize BLER logs for all the symbols in the simulation time
            numSlotsSim = simParam.numFrames * obj.NumSlotsFrame; % Simulation time in units of slot duration
            logFormat = repmat(logFormat(1,:), numSlotsSim*obj.NumSym, 1);
        end
    end
end
