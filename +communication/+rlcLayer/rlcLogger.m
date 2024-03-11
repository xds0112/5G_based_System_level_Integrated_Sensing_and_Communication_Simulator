classdef rlcLogger < handle
    %rlcLogger RLC statistics logging object
    %   The class implements per slot logging mechanism for RLC logical
    %   channels of the UEs. It is used to log the statistics per cell

    %   Copyright 2019-2021 The MathWorks, Inc.

    properties
        %NCellID Cell id to which the logging object belongs
        NCellID (1, 1) {mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1;

        %NumUEs Count of UEs
        NumUEs

        %NumSlotsFrame Number of slots in a 10ms time frame
        NumSlotsFrame

        %RLCStatsLog Slot-by-slot log of the RLC statistics
        % It is a P-by-Q cell array, where P is the number of slots, and Q
        % is the number of columns in the logs. The column names are
        % specified as keys in ColumnIndexMap
        RLCStatsLog

        %ColumnIndexMap Mapping the column names of logs to respective column indices
        % It is a map object
        ColumnIndexMap

        %RLCStatIndexMap Mapping the column names of logs to respective column indices
        % It is a map object
        RLCStatIndexMap
    end
    
    properties (GetAccess = public, SetAccess = private)
        %UEIdList RNTIs of UEs in a cell as row vector
        UEIdList
    end

    properties(Access = private)
        %CurrSlot Current slot in the frame
        % It is incremented by 1 slot for every call to logRLCStats method
        CurrSlot = -1

        %CurrFrame Current frame
        % It is incremented by 1 frame for every NumSlotsFrame slots
        CurrFrame = -1

        %LcidList List of LCIDs of each UE
        % It is a P-by-2 matrix, where P is the number of UEs, and
        % column1, column2 contains information about the downlink and
        % uplink logical channels respectively
        LcidList

        %UERLCStats Current statistics of RLC layer at UE
        % It is a N-by-1 cell array, where N is the number of UEs. Each
        % cell element is a P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        UERLCStats

        %GNBRLCStats Current statistics of RLC layer at gNB
        % It is a N-by-1 cell array, where N is then number of UEs. Each
        % cell element is P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        GNBRLCStats

        %PrevUERLCStats Cumulative RLC statistics returned in the previous query at UE
        % It is a N-by-1 cell array, where N is then number of UEs. Each
        % cell element is a P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        PrevUERLCStats

        %PrevGNBRLCStats Cumulative RLC statistics returned in the previous query at gNB
        % It is a N-by-1 cell array, where N is the number of UEs. Each
        % cell element is a P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        PrevGNBRLCStats

        %FinalUERLCStats Cumulative statistics of RLC layer at UE for the entire simulation
        % It is  a P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        FinalUERLCStats

        %FinalgNBRLCStats Cumulative statistics of RLC layer at gNB for the entire simulation
        % It is  a P-by-Q matrix, where P is the number of logical
        % channels, and Q is the number of statistics collected. Each row
        % represents statistics of a logical channel.
        FinalgNBRLCStats
    end

    properties (Access = private, Constant)
        %NumLogicalChannels Maximum number of logical channels in each UE
        NumLogicalChannels = 32;

        % Constants related to downlink and uplink information
        % These constants are used for indexing logs
        %DownlinkIdx Index for all downlink information
        DownlinkIdx = 1;
        %UplinkIdx Index for all uplink information
        UplinkIdx = 2;

        %RLCStatsTitles Title for the columns of RLC statistics
        RLCStatsTitles = {'RNTI', 'LCID', 'TxDataPDU', 'TxDataBytes', ...
            'ReTxDataPDU', 'ReTxDataBytes' 'TxControlPDU', ...
            'TxControlBytes', 'TxPacketsDropped', 'TxBytesDropped', ...
            'TimerPollRetransmitTimedOut', 'RxDataPDU', ...
            'RxDataPDUBytes', 'RxDataPDUDropped', 'RxDataBytesDropped', ...
            'RxDataPDUDuplicate', 'RxDataBytesDuplicate', ...
            'RxControlPDU', 'RxControlBytes', ...
            'TimerReassemblyTimedOut', 'TimerStatusProhibitTimedOut'};
    end

    methods (Access = public)
        function obj = rlcLogger(simParameters, lchInfo)
            %rlcLogger Construct an RLC logging object
            %
            % OBJ = hNRRLCLogger(SIMPARAMETERS, LCHINFO) Create an RLC
            % logging object
            %
            % SIMPARAMETERS - It is a structure and contains simulation
            % configuration information.
            %   NumUEs            - Number of UEs
            %   NCellID           - Cell identifier
            %   SCS               - Subcarrier spacing
            %
            % LCHINFO - It is an array of structures and contains following
            % fields.
            %   RNTI - Radio network temporary identifier of a UE
            %   LCID - Specifies the logical channel id of a UE
            %   EntityDir - Specifies the logical channel type
            %   corresponding to the logical channel specified in LCID.
            %      - 0 represents the logical channel is in downlink direction
            %      - 1 represents the logical channel is in uplink direction
            %      - 2,3 represents the logical channel is in both downlink & uplink direction

            if isfield(simParameters , 'NCellID')
                obj.NCellID = simParameters.NCellID;
            end
            obj.NumUEs = simParameters.NumUEs;

            obj.NumSlotsFrame = (10 * simParameters.SCS) / 15; % Number of slots in a 10 ms frame

            obj.LcidList = cell(obj.NumUEs, 2);

            numRows = 0; % Number of rows to create in logs
            [obj.UEIdList, ueIdxList] = sort([lchInfo.RNTI]);
            for idx = 1:obj.NumUEs
                ueIdx = ueIdxList(idx);
                % Logical channels in downlink
                dlIdx = sort([find(lchInfo(ueIdx).EntityDir == 0); find(lchInfo(ueIdx).EntityDir == 2); find(lchInfo(ueIdx).EntityDir == 3)]);
                dlLogicalChannels = lchInfo(ueIdx).LCID(dlIdx);
                obj.LcidList{ueIdx, obj.DownlinkIdx} = dlLogicalChannels;
                % Logical channels in uplink
                ulIdx = sort([find(lchInfo(ueIdx).EntityDir == 1); find(lchInfo(ueIdx).EntityDir == 2); find(lchInfo(ueIdx).EntityDir == 3)]);
                ulLogicalChannels = lchInfo(ueIdx).LCID(ulIdx);
                obj.LcidList{ueIdx, obj.UplinkIdx} = ulLogicalChannels;
                % Update the numRows based on logical channel
                % configurations
                numRows = numRows + numel(union(dlLogicalChannels, ulLogicalChannels));
            end

            % RLC Stats
            % Each row represents the statistics of each slot and last row
            % of the log represents the cumulative statistics of the entire
            % simulation
            obj.RLCStatsLog = cell((simParameters.NumFramesSim * obj.NumSlotsFrame) + 1, 5);
            obj.ColumnIndexMap = containers.Map('KeyType','char','ValueType','double');
            obj.ColumnIndexMap('Timestamp') = 1;
            obj.ColumnIndexMap('Frame') = 2;
            obj.ColumnIndexMap('Slot') = 3;
            obj.ColumnIndexMap('UE RLC statistics') = 4;
            obj.ColumnIndexMap('gNB RLC statistics') = 5;
            obj.RLCStatsLog{1, obj.ColumnIndexMap('Timestamp')} = 0; % Timestamp (in milliseconds)
            obj.RLCStatsLog{1, obj.ColumnIndexMap('Frame')} = 0; % Frame number
            obj.RLCStatsLog{1, obj.ColumnIndexMap('Slot')} = 0; % Slot number
            obj.RLCStatsLog{1, obj.ColumnIndexMap('UE RLC statistics')} = cell(1, 1); % UE RLC stats
            obj.RLCStatsLog{1, obj.ColumnIndexMap('gNB RLC statistics')} = cell(1, 1); % gNB RLC stats

            % RLC stats column index map
            obj.RLCStatIndexMap = containers.Map(obj.RLCStatsTitles,1:length(obj.RLCStatsTitles));

            % Initialize RLC stats for the current slot
            obj.UERLCStats = cell(obj.NumUEs, 1);
            obj.GNBRLCStats = cell(obj.NumUEs, 1);
            % To store RLC stats for the previous slot
            obj.PrevUERLCStats = cell(obj.NumUEs, 1);
            obj.PrevGNBRLCStats = cell(obj.NumUEs, 1);

            % Initialize the cumulative statistics of UE and gNB
            obj.FinalUERLCStats = zeros(numRows, numel(obj.RLCStatsTitles));
            obj.FinalgNBRLCStats = zeros(numRows, numel(obj.RLCStatsTitles));
            idx = 1; % To index the number of rows created in logs
            for ueIdx = 1:obj.NumUEs
                % Determine the active logical channel ids
                activeLCHIds = sort(union(obj.LcidList{ueIdx, 1}, obj.LcidList{ueIdx, 2}));
                activeLCHCount = numel(activeLCHIds);
                for lcidx =1:activeLCHCount
                    % Update the statistics with RNTI and LCID
                    obj.FinalUERLCStats(idx, 1) = obj.UEIdList(ueIdx);
                    obj.FinalUERLCStats(idx, 2) = activeLCHIds(lcidx);
                    obj.FinalgNBRLCStats(idx, 1) = obj.UEIdList(ueIdx);
                    obj.FinalgNBRLCStats(idx, 2) = activeLCHIds(lcidx);
                    idx = idx + 1;
                end
            end

        end

        function [dlMetrics, ulMetrics] = getRLCMetrics(obj, firstSlot, lastSlot, rntiList, metricName)
            %getRLCMetrics Return the RLC metrics
            %
            %[DLMETRICS, ULMETRICS] = getRLCMetrics(OBJ, FIRSTSLOT, LASTSLOT, RNTILIST, METRICNAME) Calculate and
            %stores the throughput of each logical channel of each UE
            %
            % FIRSTSLOT - Represents the starting slot number for
            % querying the metrics
            %
            % LASTSLOT -  Represents the ending slot for querying the
            % metrics
            %
            % RNTILIST - Radio network temporary identifier of UEs
            %
            % METRICNAME - Name of the metric to return. It can take one of
            % the values 'TxDataPDU', 'TxDataBytes', 'ReTxDataPDU',
            % 'ReTxDataBytes', 'TxControlPDU', 'TxControlBytes',
            % 'TxPacketsDropped', 'TimerPollRetransmitTimedOut',
            % 'RxDataPDU', 'TxBytesDropped', 'RxDataPDUBytes',
            % 'RxDataPDUDropped', 'RxDataBytesDropped', 'RxDataPDUDuplicate',
            %  'RxDataBytesDuplicate', 'RxControlPDU', 'RxControlBytes',
            %  'TimerReassemblyTimedOut', 'TimerStatusProhibitTimedOut'
            %
            % DLMETRICS and ULMETRICS are structures with following
            % properties
            %
            %   RNTI - Radio network temporary identifier of a UE
            %
            %   LogicalChannels - Logical channel id list
            %
            %   MetricValue - Column vector of elements and contains the
            %   values of the specified metrics for each logical channel

            logIdx = [obj.ColumnIndexMap('gNB RLC statistics') obj.ColumnIndexMap('UE RLC statistics')]; % Indices of gNB and UE RLC statistics
            % Define output structure format for gNB and UE RLC statistics
            outputStruct = repmat(struct('RNTI',[], 'LogicalChannels',[], 'MetricValue',[]), [numel(rntiList) 2]);
            if ~isKey(obj.RLCStatIndexMap, metricName)
                error('nr5g:hNRRLCLogger:InvalidMetricName', 'Invalid metric name');
            end
            metricIndex = obj.RLCStatIndexMap(metricName);

            for idx = 1:2 % UE and gNB RLC statistics

                % Get the statistics of the row, including RNTI and
                % LCID columns
                slotLog = cell2mat(obj.RLCStatsLog{firstSlot, logIdx(idx)}(2:end, :));
               
                matchList = zeros(size(slotLog, 1), 2);
                [~, ueIdxList] = ismember(rntiList, obj.UEIdList);
                count = 1;
                for j = 1:numel(ueIdxList)
                    ueIdx = ueIdxList(j);
                    lcCount = numel(obj.LcidList{ueIdx, idx});
                    matchList(count:count+lcCount-1, 1) =  rntiList(j); % RNTI
                    matchList(count:count+lcCount-1, 2) =  obj.LcidList{ueIdx, idx}; % LCID
                    count = count + lcCount;
                end
                matchList = matchList(1:count-1, :);
                
                [~, rowList] = ismember(matchList, slotLog(:, 1:2), 'rows');
                % Among the statistics first two columns represent
                % RNTI and LCID. The remaining statistics get updated periodically
                if ~isempty(rowList)
                    rlcStats = slotLog(rowList, metricIndex);
                    rowList = rowList + 1;
                    for i = firstSlot+1:lastSlot
                        % Get the statistics of the row, excluding RNTI and
                        % LCID columns
                        rlcStats(:, 1) = rlcStats(:, 1) + cell2mat(obj.RLCStatsLog{i, logIdx(idx)}(rowList, metricIndex));
                    end
                    
                    for listIdx = 1:numel(rntiList)
                        matchRowsIdx = find(rntiList(listIdx) == matchList(:,1)); % Match with RNTI
                        outputStruct(listIdx, idx).RNTI = rntiList(listIdx);
                        outputStruct(listIdx, idx).LogicalChannels = matchList(matchRowsIdx, 2);
                        outputStruct(listIdx, idx).MetricValue = rlcStats(matchRowsIdx);
                    end
                end
            end

            dlMetrics = outputStruct(:, obj.DownlinkIdx);
            ulMetrics = outputStruct(:, obj.UplinkIdx);
        end

        function logCellRLCStats(obj, gNB, UEs)
            %logCellRLCStats Log the RLC layer statistics
            %
            % LOGCELLRLCSTATS(OBJ, GNB, UES) Logs the RLC stats for all 
            % the nodes in the cell
            %
            % GNB - It is an object of type hNRGNB and contains information
            % about the gNB
            % UEs - It is a cell array of length equal to the number of UEs
            % in the cell. Each element of the array is an object of type
            % hNRUE.

            for ueIdx = 1:obj.NumUEs
                % Get RLC statistics
                stats = getRLCStatistics(UEs{ueIdx}, ueIdx);
                if ~isempty(obj.PrevUERLCStats{ueIdx})
                    obj.UERLCStats{ueIdx}(:, 3:end) = stats(:, 3:end) - obj.PrevUERLCStats{ueIdx}(:, 3:end);
                    obj.PrevUERLCStats{ueIdx} = stats;
                else
                    obj.UERLCStats{ueIdx} = stats;
                    obj.PrevUERLCStats{ueIdx} = stats;
                end
                stats = getRLCStatistics(gNB, ueIdx);
                if ~isempty(obj.PrevGNBRLCStats{ueIdx})
                    obj.GNBRLCStats{ueIdx}(:, 3:end) = stats(:, 3:end) - obj.PrevGNBRLCStats{ueIdx}(:, 3:end);
                    obj.PrevGNBRLCStats{ueIdx} = stats;
                else
                    obj.GNBRLCStats{ueIdx} = stats;
                    obj.PrevGNBRLCStats{ueIdx} = stats;
                end
            end
            logRLCStats(obj, obj.UERLCStats, obj.GNBRLCStats); % Update RLC statistics logs
        end

        function logRLCStats(obj, ueRLCStats, gNBRLCStats)
            %logRLCStats Log the RLC statistics
            %
            % logRLCStats(OBJ, UERLCSTATS, GNBRLCSTATS) Logs the RLC
            % statistics
            %
            % UERLCSTATS - Represents a N-by-1 cell, where N is the number
            % of UEs. Each element of the cell is  a P-by-Q matrix, where
            % P is the number of logical channels, and Q is the number of
            % statistics collected. Each row represents statistics of a
            % logical channel.
            %
            % GNBRLCSTATS - Represents a N-by-1 cell, where N is the number
            % of UEs. Each element of the cell is  a P-by-Q matrix, where
            % P is the number of logical channels, and Q is the number of
            % statistics collected. Each row represents statistics of a
            % logical channel of a UE at gNB.

            currUEStats = vertcat(ueRLCStats{:});
            currgNBStats = vertcat(gNBRLCStats{:});
            % Sort the rows based on RNTI and LCID
            currUEStats = sortrows(currUEStats, [obj.RLCStatIndexMap('RNTI') obj.RLCStatIndexMap('LCID')]);
            currgNBStats = sortrows(currgNBStats, [obj.RLCStatIndexMap('RNTI') obj.RLCStatIndexMap('LCID')]);

            % Move to the next slot
            obj.CurrSlot = mod(obj.CurrSlot + 1, obj.NumSlotsFrame);
            if(obj.CurrSlot == 0)
                obj.CurrFrame = obj.CurrFrame + 1; % Next frame
            end
            timestamp = obj.CurrFrame * 10 + (obj.CurrSlot * 10/obj.NumSlotsFrame);
            logIndex = obj.CurrFrame * obj.NumSlotsFrame + obj.CurrSlot + 1;
            obj.RLCStatsLog{logIndex, obj.ColumnIndexMap('Timestamp')} = timestamp;
            obj.RLCStatsLog{logIndex, obj.ColumnIndexMap('Frame')} = obj.CurrFrame;
            obj.RLCStatsLog{logIndex, obj.ColumnIndexMap('Slot')} = obj.CurrSlot;
            % Current cumulative statistics
            obj.FinalUERLCStats(:,3:end) = currUEStats(:,3:end) + obj.FinalUERLCStats(:,3:end);
            obj.FinalgNBRLCStats(:,3:end) = currgNBStats(:,3:end) + obj.FinalgNBRLCStats(:,3:end);
            % Add column titles for the current slot statistics
            obj.RLCStatsLog{logIndex, obj.ColumnIndexMap('UE RLC statistics')} = vertcat(obj.RLCStatsTitles, num2cell(currUEStats));
            obj.RLCStatsLog{logIndex,obj.ColumnIndexMap('gNB RLC statistics')} = vertcat(obj.RLCStatsTitles, num2cell(currgNBStats));
        end

        function rlcLogs = getRLCLogs(obj)
            %GETRLCLOGS Return the per slot logs
            %
            % RLCLOGS = getRLCLogs(OBJ) Returns the RLC logs
            %
            % RLCLOGS - It is (N+2)-by-P cell, where N represents the
            % number of slots in the simulation and P represents the number
            % of columns. The first row of the logs contains titles for the
            % logs. The last row of the logs contains the cumulative
            % statistics for the entire simulation. Each row (excluding
            % first and last rows) in the logs corresponds to a slot and
            % contains the following information.
            %   Timestamp - Timestamp (in milliseconds)
            %   Frame - Frame number.
            %   Slot - Slot number in the frame.
            %   UE RLC statistics - N-by-P cell, where N is the product of
            %                       number of UEs and number of logical
            %                       channels, and P is the number of
            %                       statistics collected. Each row
            %                       represents statistics of a logical
            %                       channel in a UE.
            %   gNB RLC statistics - N-by-P cell, where N is the product of
            %                      number of UEs and number of logical
            %                      channels, and P is the number of
            %                      statistics collected. Each row
            %                      represents statistics of a logical
            %                      channel of a UE at gNB.

            if obj.CurrFrame < 0 % Return empty when logging is not started
                rlcLogs = [];
                return;
            end
            headings = {'Timestamp','Frame number', 'Slot number', 'UE RLC statistics', 'gNB RLC statistics'};
            % Most recent log index for the current simulation
            lastLogIndex = obj.CurrFrame * obj.NumSlotsFrame + obj.CurrSlot + 1;
            % Create a row at the end of the to store the cumulative statistics of the UE
            % and gNB at the end of the simulation
            lastLogIndex = lastLogIndex + 1;
            obj.RLCStatsLog{lastLogIndex, obj.ColumnIndexMap('UE RLC statistics')} = vertcat(obj.RLCStatsTitles, num2cell(obj.FinalUERLCStats));
            obj.RLCStatsLog{lastLogIndex, obj.ColumnIndexMap('gNB RLC statistics')} = vertcat(obj.RLCStatsTitles, num2cell(obj.FinalgNBRLCStats));
            rlcLogs = [headings; obj.RLCStatsLog(1:lastLogIndex, :)];
        end
    end
end