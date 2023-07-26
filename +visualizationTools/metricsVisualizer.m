 classdef metricsVisualizer < handle
    %metricsVisualizer Creates metrics visualization object
    %   The class implements visualization of the metrics. The following three types of
    %   visualizations are shown:
    %       (i) Display of RLC metrics
    %      (ii) Display of MAC Scheduler performance metrics
    %     (iii) Display of Phy metrics
    %
    %   metricsVisualizer methods:
    %
    %   plotLiveMetrics - Updates the metric plots by querying from nodes
    %   plotMetrics     - Updates the metric plots by querying from logs
    %
    %   metricsVisualizer Name-Value pairs:
    %
    %   CellOfInterest              - Cell ID to which the visualization object belongs
    %   VisualizationFlag           - Indicates the plots to visualize
    %   EnableRLCMetricsPlots       - Switch to turn on/off the RLC metrics plots
    %   EnableSchedulerMetricsPlots - Switch to turn on/off the scheduler performance metrics plots
    %   EnablePhyMetricsPlots       - Switch to turn on/off the PHY metrics plots
    %   LCHInfo                     - Logical channel information
    %   RLCMetricName               - Name of the RLC metric to plot
    %   RLCMetricCustomLabel        - Custom label name to display in y-axis for the RLC metrics
    %   RLCLogger                   - RLC logger handle object
    %   MACLogger                   - MAC logger handle object
    %   PhyLogger                   - Phy logger handle object

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %CellOfInterest Cell id to which the visualization belongs
        CellOfInterest (1, 1) {mustBeInteger, mustBeInRange(CellOfInterest, 0, 1007)} = 1;

        %VisualizationFlag  Indicates the plots to visualize
        % It takes the values 0, 1, 2 and represent downlink, uplink, and both
        % link directions respectively. Default value is 2.
        VisualizationFlag = 2

        %LCHInfo Logical channel information. It is an array of structures and contains
        % following fields.
        %   RNTI - Radio network temporary identifier of a UE
        %   LCID - It is an integer vector and specifies the logical channel IDs of a UE
        %   EntityDir - It is an integer vector and specifies the logical channel type
        %   corresponding to the logical channel specified in LCID.
        %      - 0 represents the logical channel is in downlink direction
        %      - 1 represents the logical channel is in uplink direction
        %      - 2,3 represents the logical channel is in both downlink & uplink direction
        LCHInfo

        %RLCLogger RLC logger handle object
        % It is a scalar and object of type hNRRLCLogger
        RLCLogger

        %MACLogger MAC logger handle object
        % It is a scalar and object of type hNRSchedulingLogger
        MACLogger

        %PhyLogger Phy logger handle object
        % It is a scalar and object of type hNRPhyLogger
        PhyLogger

        %RLCMetricName Name of the RLC metric to plot
        % It can take one of the values 'TxDataPDU', 'TxDataBytes',
        % 'ReTxDataPDU', 'ReTxDataBytes', 'TxControlPDU', 'TxControlBytes',
        % 'TxPacketsDropped', 'TimerPollRetransmitTimedOut', 'RxDataPDU',
        % 'TxBytesDropped', 'RxDataPDUBytes', 'RxDataPDUDropped',
        % 'RxDataBytesDropped', 'RxDataPDUDuplicate', 'RxDataBytesDuplicate',
        % 'RxControlPDU', 'RxControlBytes', 'TimerReassemblyTimedOut',
        % 'TimerStatusProhibitTimedOut'. The default value is 'TxDataBytes'
        RLCMetricName = 'TxDataBytes'

        %RLCMetricCustomLabel Custom label name to display in y-axis for the RLC metrics
        RLCMetricCustomLabel = 'Transmitted Bytes';

        %EnableSchedulerMetricsPlots Switch to turn on/off the scheduler performance metrics plots
        % It is a logical scalar. Set the value as true to enable the
        % plots. By default the plots ar disabled
        EnableSchedulerMetricsPlots = false;

        %EnableRLCMetricsPlots Switch to turn on/off the RLC metrics plots
        % It is a logical scalar. Set the value as true to enable the
        % plots. By default the plots ar disabled
        EnableRLCMetricsPlots = false;

        %EnablePhyMetricsPlots Switch to turn on/off the PHY metrics plots
        % It is a logical scalar. Set the value as true to enable the
        % plots. By default the plots ar disabled
        EnablePhyMetricsPlots = false;

        %results restores KPIs
        results
    end

    properties(Hidden)
        %RLCVisualization Timescope to display UE RLC layer's logical channel throughput
        RLCVisualization

        %MACVisualization Timescope to display the downlink and uplink scheduler performance metrics
        MACVisualization = cell(2, 1);

        %PhyVisualization Timescope to display the downlink and uplink block error rates
        PhyVisualization
    end

    properties (Access = private)
        %SimTime Simulation time (in seconds)
        SimTime

        %PeakDataRateDL Theoretical peak data rate
        % A vector of two elements. First and second elements represent the
        % downlink and uplink theoretical peak data rate respectively
        PeakDataRate = zeros(2, 1);

        %Bandwidth Carrier bandwidth
        % A vector of two elements and represents the downlink and uplink
        % bandwidth respectively
        Bandwidth

        %UELegend Legend for the UE
        UELegend

        %NumMetricsSteps Number of times metrics plots are updated
        NumMetricsSteps

        %MetricsStepSize Number of slots in one metrics step
        MetricsStepSize

        %MetricsStepDuration Duration of 1 metrics step
        MetricsStepDuration

        %Nodes Contains the node objects.
        % It is a structure with two fields.
        %    UEs - Contains the UE objects. It is a cell array
        %    GNB - Contains the gNB object. It is a scalar
        Nodes

        %MACTxBytes Total bytes transmitted (newTx + reTx)
        MACTxBytes

        %MACNewTxBytes Total bytes transmitted (only newTx)
        MACNewTxBytes

        %DLBLERInfo Information to calculate DL block error rate
        % It is a M-by-2 matrix, where M represents the number of
        % UEs and the column1, column2 represents the total erroneous
        % packets, and total packets received in downlink
        DLBLERInfo

        %ULBLERInfo Information to calculate UL block error rate
        % It is a M-by-2 matrix, where M represents the number of
        % UEs and the column1, column2 represents the total erroneous
        % packets, and total packets received in uplink
        ULBLERInfo

        %ResourceShareMetrics Number of RBs allocated to each UE
        % Matrics of size 'M-BY-2', where M is the number of UEs, 2
        % represents the columns for downlink and uplink
        ResourceShareMetrics

        %ULRLCMetrics Contains RLC metrics of UEs in uplink
        % It is a M-by-3 matrix, where M represents the number of
        % UEs and the column1, column2, column3  represents the UEs rnti,
        % logical channel ID and metrics of the logical channel respectively
        ULRLCMetrics

        %DLRLCMetrics Contains RLC metrics of UEs in downlink
        % It is a M-by-3 matrix, where M represents the number of
        % UEs and the column1, column2, column3  represents the UEs rnti,
        % logical channel ID and metrics of the logical channel respectively
        DLRLCMetrics
    end

   properties(Access = private, Hidden)
       %PlotIds Represent the IDs of the plots
       PlotIDs = [1 2]

       % UEOfInterestListInfo Information about the list of UEs of interest
       UEOfInterestListInfo

       %MaxMACMetricNodes Maximum number of UEs MAC metrics can be plotted
       MaxMACMetricNodes = 24;

       %MaxMACMetricNodes Maximum number of RLC logical channel metrics can be plotted
       % If the VisualizationFlag = 2 and the total number of RLC logical
       % channels in both uplink and downlink exceeds the limit, first
       % available 50 metrics from each uplink and downlink is selected. If
       % the VisualizationFlag is set 0 or 1 then, metrics of first
       % available 100 metrics in the UEOfInterestListInfo as per the
       % VisualizationFlag is selected
       MaxRLCLCHMetrics = 100;

       %MaxMACMetricNodes Maximum number of Phy metrics can be plotted
       % If the VisualizationFlag = 2 and the number of UEs in both uplink
       % and downlink exceeds the limit, metrics of first 50 UEs in UEOfInterestListInfo from each
       % uplink and downlink is selected. If the VisualizationFlag is set 0 or 1 then,
       % metrics of first available 100 UEs in the UEOfInterestListInfo as per the
       % VisualizationFlag is selected
       MaxPhyMetricNodes = 100;

       %MaxDLRLCLCHCount Number of RLC LCH metrics to be plotted in DL
       MaxDLRLCLCHCount = 0;

       %MaxULRLCLCHCount Number of RLC LCH metrics to be plotted in UL
       MaxULRLCLCHCount = 0;

       %NodesOfInterest Nodes of interest
       NodesOfInterest

       % NumUEs Number of UEs
       NumUEs = 0

       %UEInfo Information about the list of UEs
       % It is a M-by-3 matrix, where M represents the number of
       % UEs and the column1, column2, and column3 represents the UE id,
       % number of logical channels in downlink, uplink respectively
       UEInfo

       %DLRLCMetricsIdx Indices of the DL RLC metrics
       DLRLCMetricsIdx = 0

       %ULRLCMetricsIdx Indices of the UL RLC metrics
       ULRLCMetricsIdx = 0
   end

    properties (Access = private, Constant, Hidden)
        %NumLogicalChannels Maximum number of logical channels in each UE
        NumLogicalChannels = 32;

        % Constants related to downlink and uplink information. These
        % constants are used for indexing logs and identifying plots
        %DownlinkIdx Index for all downlink information
        DownlinkIdx = 1;
        %UplinkIdx Index for all uplink information
        UplinkIdx = 2;
    end

    methods (Access = public)
        function obj = metricsVisualizer(param, varargin)
            %hNRMetricsVisualizer Constructs metrics visualization object
            %
            % OBJ = hNRMetricsVisualizer(PARAM) Create metrics visualization
            % object for downlink and uplink plots.
            %
            % OBJ = hNRMetricsVisualizer(PARAM, Name, Value) creates a metrics visualization
            % object, OBJ, with properties specified by one or more name-value
            % pairs. You can specify additional name-value pair arguments in any
            % order as (Name1,Value1,...,NameN,ValueN).
            %
            % PARAM - It is a structure and contain simulation
            % configuration information.
            %
            %    NumFramesSim      - Number of frames in simulation
            %    SCS               - Subcarrier spacing
            %    UEOfInterest      - List of UEs of interest
            %    NumUEs            - Number of UEs
            %    DLBandwidth       - Downlink bandwidth (in Hz)
            %    ULBandwidth       - Uplink bandwidth (in Hz)
            %    DLULPeriodicity   - Duration of the DL-UL pattern in ms (for
            %                        TDD mode)
            %    NumDLSlots        - Number of full DL slots at the start of
            %                        DL-UL pattern (for TDD mode)
            %    NumDLSyms         - Number of DL symbols after full DL slots
            %                        in the DL-UL pattern (for TDD mode)
            %    NumULSlots        - Number of full UL slots at the end of
            %                        DL-UL pattern (for TDD mode)
            %    NumULSyms         - Number of UL symbols before full UL slots
            %                        in the DL-UL pattern (for TDD mode)
            %    NumMetricsSteps   - Number of times metrics plots to be
            %                        updated
            %    MetricsStepSize   - Interval at which metrics visualization
            %                        updates in terms of number of slots
            %
            % VARARGIN - Optional arguments as name-value pairs

            % Initialize the properties
            for idx = 1:2:numel(varargin)
                obj.(varargin{idx}) = varargin{idx+1};
            end

            % Validate the simulation time
            validateattributes(param.numFrames, {'numeric'}, {'nonempty', 'integer', 'scalar', 'finite', '>', 0}, 'simParameters.numFrames', 'numFrames');

            obj.SimTime = (10 * param.numFrames) / 1000; % Simulation time (in seconds)
            if isempty(obj.NumMetricsSteps)
                obj.NumMetricsSteps = param.numMetricsSteps;
            end
            % Validate the metric plot step-count. Number of steps must be less than or equal to number of slots in simulation
            validateattributes(obj.NumMetricsSteps, {'numeric'}, {'nonempty', 'integer', 'scalar', '>', 0, '<=', param.numFrames * (param.scs / 15) * 10}, 'simParameters.numMetricsSteps', 'numMetricsSteps');

            % Interval at which metrics visualization updates in terms of
            % number of slots. Make sure that MetricsStepSize is an integer
            obj.MetricsStepSize = floor(param.metricsStepSize);
            obj.MetricsStepDuration = obj.MetricsStepSize * (15 / param.scs);

            % Create legend information for the plots
            if isempty(obj.Nodes)
                totalNumUEs = numel(1:param.numUEs);
            else
                totalNumUEs = numel(obj.Nodes.UEs);
            end
            obj.UEInfo = zeros(totalNumUEs, 3);
            obj.UEInfo(:,1) = (1:totalNumUEs)';

            if isfield(param, 'UEOfInterest')
                ueOfInterestList = sort(param.UEOfInterest);
            elseif ~isempty(obj.LCHInfo)
                ueOfInterestList = [obj.LCHInfo.RNTI];
            else
                ueOfInterestList = 1:totalNumUEs;
            end

            numUEsOfInterest = numel(ueOfInterestList);
            obj.UELegend = cell(1, numUEsOfInterest);
            obj.UEOfInterestListInfo = zeros(numUEsOfInterest, 1);
            for idx = 1:numUEsOfInterest
                obj.UEOfInterestListInfo(idx) = ueOfInterestList(idx); % Update the UE id
                obj.UELegend{idx} = ['UE-' num2str(ueOfInterestList(idx)) ' '];
            end
            obj.DLBLERInfo = zeros(totalNumUEs, 2);
            obj.ULBLERInfo = zeros(totalNumUEs, 2);
            obj.ULRLCMetrics = zeros(totalNumUEs*obj.NumLogicalChannels, 3);
            obj.DLRLCMetrics = zeros(totalNumUEs*obj.NumLogicalChannels, 3);

            obj.MACTxBytes = zeros(totalNumUEs, 2);
            obj.MACNewTxBytes = zeros(totalNumUEs, 2);
            obj.ResourceShareMetrics = zeros(totalNumUEs, 2);

            if obj.VisualizationFlag == 2
                % Update the limit
                obj.MaxPhyMetricNodes = 50;
                obj.MaxRLCLCHMetrics = 50;
            else
                % Either UL or DL is enabled
                obj.PlotIDs = obj.VisualizationFlag+1;
            end

            [obj.PeakDataRate(obj.DownlinkIdx), obj.PeakDataRate(obj.UplinkIdx)] = calculatePeakDataRate(obj,param);
            if isfield(param, 'dlBandwidth')
                obj.Bandwidth(obj.DownlinkIdx) = param.dlBandwidth;
            end
            if isfield(param, 'ulBandwidth')
                obj.Bandwidth(obj.UplinkIdx) = param.ulBandwidth;
            end

            % Create RLC visualization
            if obj.EnableRLCMetricsPlots
                if ~isempty(obj.LCHInfo)
                    addRLCVisualization(obj);
                else
                    error('nr5g:metricsVisualizer:InvalidLCHInfo', 'LCHInfo must be nonempty.');
                end
            end

            % Create Phy visualization
            if obj.EnablePhyMetricsPlots
                addPhyVisualization(obj);
            end

            % Create MAC visualization
            if obj.EnableSchedulerMetricsPlots
                addMACVisualization(obj);
            end
        end

        function addRLCVisualization(obj, varargin)
            %addRLCVisualization Create RLC visualization
            %
            % addRLCVisualization(OBJ) Create and configure RLC
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink.
            %
            % addRLCVisualization(OBJ, RLCLOGGER) Create and configure RLC
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink and also stores the RLCLogger value
            %
            % RLCLOGGER - RLC logger. It is an object of type hNRRLCLogger

            % Create the timescope
            if isempty(obj.RLCVisualization)
                obj.RLCVisualization = timescope('Name', 'RLC Metrics Visualization');
            end

            % Set RLCLogger
            if nargin == 2
                obj.RLCLogger = varargin{1};
            end

            lchNames = cell(1,1);
            dlCount = 0;
            dlUEOfInterestLCHCount = 0;
            % Create the logical channel names for legend
            for ueIdx=1:size(obj.UEInfo, 1)
                ueId = obj.UEInfo(ueIdx, 1);
                idx = find(ueId == [obj.LCHInfo.RNTI], 1);
                % Logical channels in downlink
                dlIdx = sort([find(obj.LCHInfo(idx).EntityDir == 0); find(obj.LCHInfo(idx).EntityDir == 2); find(obj.LCHInfo(idx).EntityDir == 3)]);
                dlLogicalChannels = obj.LCHInfo(idx).LCID(dlIdx);
                obj.UEInfo(ueIdx, obj.DownlinkIdx+1) = numel(dlLogicalChannels); % Number of channels
                ueOfInterestIdx = find(obj.UEOfInterestListInfo == ueId, 1);
                for lcIdx=1:numel(dlLogicalChannels)
                    dlCount = dlCount + 1;
                    obj.DLRLCMetrics(dlCount, 1) = ueId;
                    obj.DLRLCMetrics(dlCount, 2) = dlLogicalChannels(lcIdx);
                    if dlUEOfInterestLCHCount < obj.MaxRLCLCHMetrics && ismember(ueId, obj.UEOfInterestListInfo)
                        dlUEOfInterestLCHCount = dlUEOfInterestLCHCount + 1;
                        lchNames{dlUEOfInterestLCHCount, 1} = [obj.UELegend{ueOfInterestIdx} 'LCH-' num2str(dlLogicalChannels(lcIdx))];
                        obj.MaxDLRLCLCHCount = dlUEOfInterestLCHCount;
                    end
                end
            end

            ulCount = 0;
            ulUEOfInterestLCHCount = 0;
            for ueIdx=1:size(obj.UEInfo, 1)
                ueId = obj.UEInfo(ueIdx, 1);
                idx = find(ueId == [obj.LCHInfo.RNTI], 1);
                % Logical channels in uplink
                ulIdx = sort([find(obj.LCHInfo(idx).EntityDir == 1); find(obj.LCHInfo(idx).EntityDir == 2); find(obj.LCHInfo(idx).EntityDir == 3)]);
                ulLogicalChannels = obj.LCHInfo(idx).LCID(ulIdx);
                obj.UEInfo(ueIdx, obj.UplinkIdx+1) = numel(ulLogicalChannels); % Number of channels
                ueOfInterestIdx = find(obj.UEOfInterestListInfo == ueId, 1);
                for lcIdx=1:numel(ulLogicalChannels)
                    ulCount = ulCount + 1;
                    obj.ULRLCMetrics(ulCount, 1) = ueId;
                    obj.ULRLCMetrics(ulCount, 2) = ulLogicalChannels(lcIdx);
                    if ulUEOfInterestLCHCount < obj.MaxRLCLCHMetrics && ~isempty(ueOfInterestIdx)
                        ulUEOfInterestLCHCount = ulUEOfInterestLCHCount + 1;
                        lchNames{dlUEOfInterestLCHCount+ulUEOfInterestLCHCount, 1} = [obj.UELegend{ueOfInterestIdx} 'LCH-' num2str(ulLogicalChannels(lcIdx))];
                        obj.MaxULRLCLCHCount = ulUEOfInterestLCHCount;
                    end
                end
            end

            obj.DLRLCMetrics = obj.DLRLCMetrics(1:max(dlCount, ulCount), :);
            obj.ULRLCMetrics = obj.ULRLCMetrics(1:max(dlCount, ulCount), :);
            % Indices of the UEs of interest RLC metrics
            obj.DLRLCMetricsIdx = find(ismember(obj.DLRLCMetrics(:, 1), obj.UEOfInterestListInfo))';
            obj.ULRLCMetricsIdx = find(ismember(obj.ULRLCMetrics(:, 1), obj.UEOfInterestListInfo))';
            % Limit the number of channels to plot
            if numel(obj.DLRLCMetricsIdx) > obj.MaxDLRLCLCHCount
                obj.DLRLCMetricsIdx = obj.DLRLCMetricsIdx(1:obj.MaxDLRLCLCHCount);
            end
            if numel(obj.ULRLCMetricsIdx) > obj.MaxULRLCLCHCount
                obj.ULRLCMetricsIdx = obj.ULRLCMetricsIdx(1:obj.MaxULRLCLCHCount);
            end

            % Update the timescope properties
            set(obj.RLCVisualization, 'LayoutDimensions', [numel(obj.PlotIDs) 1], 'ShowLegend', true, ...
                'SampleRate', obj.NumMetricsSteps/obj.SimTime, 'TimeSpanSource', 'property','ChannelNames', lchNames, 'TimeSpan', obj.SimTime);

            % Initialize the plots
            if numel(obj.PlotIDs) == 1
                obj.RLCVisualization(zeros(1, obj.MaxDLRLCLCHCount+obj.MaxULRLCLCHCount));
            else
                obj.RLCVisualization(zeros(1, obj.MaxDLRLCLCHCount), zeros(1, obj.MaxULRLCLCHCount));
            end

            % Add the titles and legends
            for idx=1:numel(obj.PlotIDs)
                obj.RLCVisualization.ActiveDisplay = idx;
                obj.RLCVisualization.YLabel = ['Cell-' num2str(obj.CellOfInterest) ' ' obj.RLCMetricCustomLabel];
                obj.RLCVisualization.AxesScaling = 'Updates';
                obj.RLCVisualization.AxesScalingNumUpdates = 1;

                if obj.PlotIDs(idx) == obj.DownlinkIdx
                    obj.RLCVisualization.Title = 'Downlink Logical Channels (LCH)';
                else
                    obj.RLCVisualization.Title = 'Uplink Logical Channels (LCH)';
                end
            end
        end

        function addMACVisualization(obj, varargin)
            %addMACVisualization Create MAC visualization
            %
            % addMACVisualization(OBJ) Create and configure MAC
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink.
            %
            % addMACVisualization(OBJ, MACLOGGER) Create and configure MAC
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink and also set the MACLogger value
            %
            % MACLOGGER - MAC logger. It is an object of type hNRSchedulingLogger

            % Set MACLogger
            if nargin == 2
                obj.MACLogger = varargin{1};
            end

            numUEs = size(obj.UEOfInterestListInfo, 1);
            % Maximum number of node MAC metrics allowed to plot
            if numUEs > obj.MaxMACMetricNodes
                numUEs = obj.MaxMACMetricNodes;
            end
            nodeMetrics = zeros(1, numUEs);
            % Plot titles and Y-axis label prefix
            title = {'Downlink Scheduler Performance Metrics', ...
                'Uplink Scheduler Performance Metrics'};
            tag = {['Cell-' num2str(obj.CellOfInterest) ' DL '], ...
                ['Cell-' num2str(obj.CellOfInterest) ' UL ']};
            channelNames = [obj.UELegend(1:numUEs) 'Cell' 'Peak Data Rate' obj.UELegend(1:numUEs) obj.UELegend(1:numUEs) 'Cell' 'Peak Data Rate' obj.UELegend(1:numUEs)];

            % Create time scope and add labels
            for idx=1:numel(obj.PlotIDs)
                windowId = obj.PlotIDs(idx);

                if isempty(obj.MACVisualization{windowId})
                    obj.MACVisualization{windowId} = timescope('Name', title{windowId});
                end

                set(obj.MACVisualization{windowId}, 'LayoutDimensions',[2 2], 'ChannelNames', channelNames,...
                    'ActiveDisplay',1, 'YLabel',[tag{windowId} 'Throughput (Mbps)'], 'ShowLegend',true,'AxesScaling', 'Updates', ...
                    'AxesScalingNumUpdates', 1, 'TimeSpanSource', 'property', 'TimeSpan', obj.SimTime, ...
                    'ActiveDisplay',2, 'YLabel',[tag{windowId} 'Resource Share (%)'], ...
                    'ShowLegend',true, 'YLimits',[1 100],'AxesScaling', 'Updates','AxesScalingNumUpdates', 1, ...
                    'SampleRate', obj.NumMetricsSteps/obj.SimTime, 'TimeSpanSource', 'property', 'TimeSpan', obj.SimTime, ...
                    'ActiveDisplay',3, 'YLabel',[tag{windowId} 'Goodput (Mbps)'], 'ShowLegend',true,'AxesScaling', 'Updates', 'AxesScalingNumUpdates', 1, ...
                    'SampleRate', obj.NumMetricsSteps/obj.SimTime, 'TimeSpanSource', 'property', 'TimeSpan', obj.SimTime, ...
                    'ActiveDisplay',4, 'YLabel',[tag{windowId} 'Buffer Status (KB)'], 'ShowLegend',true,'AxesScaling', 'Updates', 'AxesScalingNumUpdates', 1, ...
                    'SampleRate', obj.NumMetricsSteps/obj.SimTime, 'TimeSpanSource', 'property', 'TimeSpan', obj.SimTime);
                obj.MACVisualization{windowId}([nodeMetrics 0 obj.PeakDataRate(windowId)], nodeMetrics, [nodeMetrics 0 obj.PeakDataRate(windowId)], nodeMetrics);
            end
        end

        function addPhyVisualization(obj, varargin)
            %addPhyVisualization Create Phy visualization
            %
            % addPhyVisualization(OBJ) Create and configure Phy
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink.
            %
            % addPhyVisualization(OBJ, PHYLOGGER) Create and configure Phy
            % visualization. It creates figures for visualizing metrics
            % in both downlink and uplink and also set the PhyLogger value
            %
            % PHYLOGGER - Phy logger. It is an object of type hNRPhyLogger

            % Set PhyLogger
            if nargin == 2
                obj.PhyLogger = varargin{1};
            end

            % Create and configure the timescope
            if isempty(obj.PhyVisualization)
                obj.PhyVisualization = timescope('Name', 'Block Error Rate (BLER) Visualization');
            end

            % Maximum number of node PHY metrics allowed to plot
            numUEs = size(obj.UEOfInterestListInfo, 1);
            if numUEs > obj.MaxPhyMetricNodes
                numUEs = obj.MaxPhyMetricNodes;
            end
            blerData = zeros(1, numUEs);

            set(obj.PhyVisualization, 'LayoutDimensions', [numel(obj.PlotIDs) 1], 'ShowLegend', true, ...
                'SampleRate', obj.NumMetricsSteps/obj.SimTime,'TimeSpanSource', 'property','ChannelNames', ...
                repmat(obj.UELegend(1:numUEs), [1 numel(obj.PlotIDs)]), 'TimeSpan', obj.SimTime);

            titles = {'Downlink BLER', 'Uplink BLER'};
            % Initialize the plots
            if numel(obj.PlotIDs) == 1
                obj.PhyVisualization(blerData);
            else
                obj.PhyVisualization(blerData, blerData);
            end

            % Add the titles and legends
            for idx=1:numel(obj.PlotIDs)
                obj.PhyVisualization.ActiveDisplay = idx;
                obj.PhyVisualization.YLimits = [0 1];
                obj.PhyVisualization.YLabel = ['Cell-' num2str(obj.CellOfInterest) ' BLER'];
                obj.PhyVisualization.Title = titles{obj.PlotIDs(idx)};
            end
        end

        function plotMetrics(obj, slotNum)
            %plotMetrics Updates the metric plots by querying from logs
            %
            % plotMetrics(OBJ, SLOTNUM) Updates the metrics plots
            %
            % SLOTNUM - Slot number in simulation. It is used to calculate
            % the time interval corresponding to which metrics plots have
            % to be updated

            % RLC metrics visualization
            if ~isempty(obj.RLCVisualization)
                plotRLCMetrics(obj, slotNum);
            end

            % MAC metrics visualization
            if ~isempty(obj.MACVisualization{1}) || ~isempty(obj.MACVisualization{2})
                plotMACMetrics(obj, slotNum);
            end

            % PHY metrics visualization
            if ~isempty(obj.PhyVisualization)
                plotPhyMetrics(obj, slotNum);
            end
        end

        function plotLiveMetrics(obj)
            %plotLiveMetrics Updates the metric plots by querying from nodes
            %
            % plotLiveMetrics(OBJ, SLOTNUM) Updates the metrics plots
            %
            % SLOTNUM - Slot number in simulation. It is used to calculate
            % the time interval corresponding to which metrics plots have
            % to be updated

            % RLC metrics visualization
            if ~isempty(obj.RLCVisualization)
                plotLiveRLCMetrics(obj);
            end

            % MAC metrics visualization
            if ~isempty(obj.MACVisualization{1}) || ~isempty(obj.MACVisualization{2})
                plotLiveMACMetrics(obj);
            end

            % PHY metrics visualization
            if ~isempty(obj.PhyVisualization)
                plotLivePhyMetrics(obj);
            end
        end

        function results = savePerformanceIndicators(obj)

            if obj.EnableSchedulerMetricsPlots
                if ismember(obj.UplinkIdx, obj.PlotIDs) % Uplink stats
                    ulThroughputDataRate = (obj.MACTxBytes(:, obj.UplinkIdx) .* 8) ./ (obj.SimTime * 1000 * 1000); % Mbps
                    ulGoodPutDataRate = (obj.MACNewTxBytes(:, obj.UplinkIdx) .* 8) ./ (obj.SimTime * 1000 * 1000); % Mbps
                    ulPeakSpectralEfficiency = 1e6*obj.PeakDataRate(obj.UplinkIdx)/obj.Bandwidth(obj.UplinkIdx);
                    ulAchSpectralEfficiency = 1e6*sum(ulGoodPutDataRate)/obj.Bandwidth(obj.UplinkIdx);
                end

                if ismember(obj.DownlinkIdx, obj.PlotIDs) && obj.EnableSchedulerMetricsPlots % Downlink stats
                    dlThroughputDataRate = (obj.MACTxBytes(:, obj.DownlinkIdx) .* 8) ./ (obj.SimTime * 1000 * 1000); % Mbps
                    dlGoodputDataRate = (obj.MACNewTxBytes(:, obj.DownlinkIdx) .* 8) ./ (obj.SimTime * 1000 * 1000); % Mbps
                    dlPeakSpectralEfficiency = 1e6*obj.PeakDataRate(obj.DownlinkIdx)/obj.Bandwidth(obj.DownlinkIdx);
                    dlAchSpectralEfficiency = 1e6*sum(dlGoodputDataRate)/obj.Bandwidth(obj.DownlinkIdx);
                end
            end

            if obj.EnablePhyMetricsPlots
                if ismember(obj.UplinkIdx, obj.PlotIDs) % Uplink stats
                    ulBLER = obj.ULBLERInfo(:, 1) ./ obj.ULBLERInfo(:, 2);
                end
                if ismember(obj.DownlinkIdx, obj.PlotIDs) % Downlink stats
                    dlBLER = obj.DLBLERInfo(:, 1) ./ obj.DLBLERInfo(:, 2);
                end
            end

            % Assignment
            results = struct;
            results.ueULThroughput = ulThroughputDataRate;
            results.ueULGoodput = ulGoodPutDataRate;
            results.cellULThroughput = sum(ulThroughputDataRate);
            results.cellULGoodput = sum(ulGoodPutDataRate);
            results.peakULSpectralEfficiency = ulPeakSpectralEfficiency;
            results.achievedULSpectralEfficiency = ulAchSpectralEfficiency;

            results.ueDLThroughput = dlThroughputDataRate;
            results.ueDLGoodput = dlGoodputDataRate;
            results.cellDLThroughput = sum(dlThroughputDataRate);
            results.cellDLGoodput = sum(dlGoodputDataRate);
            results.peakDLSpectralEfficiency = dlPeakSpectralEfficiency;
            results.achievedDLSpectralEfficiency = dlAchSpectralEfficiency;

            results.ueULBLER = ulBLER;
            results.ueDLBLER = dlBLER;

            obj.results = results;
        end

        function plotPerformanceIndicatorsECDF(obj)

            if obj.EnableSchedulerMetricsPlots
                if ismember(obj.UplinkIdx, obj.PlotIDs) % Uplink stats
                    ulThroughputDataRate = obj.results.ueULThroughput;
                    ulGoodPutDataRate    = obj.results.ueULGoodput;

                    figure('Name', 'ECDF of UL Throughput & Goodput')
                    ulTp = tools.plotECDF(ulThroughputDataRate, 1);
                    hold on
                    ulGp = tools.plotECDF(ulGoodPutDataRate, 1);
                    grid on
                    legend([ulTp, ulGp], {'Uplink throughput', 'Uplink goodput'})
                    title('ECDF of Uplink Throughput and Goodput')
                    xlabel('Data Rate (Mbps)')
                    ylabel('Cumulative Probability')
                end

                if ismember(obj.DownlinkIdx, obj.PlotIDs) && obj.EnableSchedulerMetricsPlots % Downlink stats
                    dlThroughputDataRate = obj.results.ueDLThroughput;
                    dlGoodputDataRate    = obj.results.ueDLGoodput;
                    
                    figure('Name', 'ECDF of DL Throughput & Goodput')
                    dlTp = tools.plotECDF(dlThroughputDataRate, 1);
                    hold on
                    dlGp = tools.plotECDF(dlGoodputDataRate, 1);
                    grid on
                    legend([dlTp, dlGp], {'Downlink throughput', 'Downlink goodput'})
                    title('ECDF of Downlink Throughput and Goodput')
                    xlabel('Data Rate (Mbps)')
                    ylabel('Cumulative Probability')
                end
            end

            if obj.EnablePhyMetricsPlots
                if ismember(obj.UplinkIdx, obj.PlotIDs) % Uplink stats
                    ulBLER = obj.results.ueULBLER;
                end
                if ismember(obj.DownlinkIdx, obj.PlotIDs) % Downlink stats
                    dlBLER = obj.results.ueDLBLER;
                end

                if ~any(isnan(ulBLER)) && ~any(isnan(dlBLER))
                    figure('Name', 'ECDF of DL & UL BLER')
                    ulbl = tools.plotECDF(ulBLER, 1);
                    hold on
                    dlbl = tools.plotECDF(dlBLER, 1);
                    grid on
                    xlim([0 1])
                    xlabel('Block Error Rate')
                    ylabel('Cumulative Probability')
                    legend([ulbl dlbl], {'Uplink BLER', 'Downlink BLER'})
                    title('ECDF of Uplink and Downlink Block Error Rates')
                end
            end
        end
   
        function [dlPeakDataRate, ulPeakDataRate] = calculatePeakDataRate(~, simParameters)
            %calculatePeakDataRate Calculate peak data rate

            % Symbol duration for the given numerology
            symbolDuration = 1e-3/(14*(simParameters.scs/15)); % Assuming normal cyclic prefix

            % Validate the number of transmitter antennas on gNB
            if ~isfield(simParameters, 'gNBTxAnts')
                simParameters.gNBTxAnts = 1;
            elseif ~ismember(simParameters.gNBTxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:metricsVisualizer:InvalidAntennaSize',...
                    'Number of gNB Tx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', simParameters.gNBTxAnts);
            end
            % Validate the number of receiver antennas on gNB
            if ~isfield(simParameters, 'gNBRxAnts')
                simParameters.gNBRxAnts = 1;
            elseif ~ismember(simParameters.gNBRxAnts, [1,2,4,8,16,32,64,128,256,512,1024])
                error('nr5g:metricsVisualizer:InvalidAntennaSize',...
                    'Number of gNB Rx antennas (%d) must be a member of [1,2,4,8,16,32,64,128,256,512,1024].', simParameters.gNBRxAnts);
            end
            if ~isfield(simParameters, 'ueTxAnts')
                simParameters.ueTxAnts = ones(simParameters.numUEs, 1);
                % Validate the number of transmitter antennas on UEs
            elseif ~ismember(simParameters.ueTxAnts, [1,2,4,8,16])
                error('nr5g:metricsVisualizer:InvalidAntennaSize',...
                    'Number of UE Rx antennas (%d) must be a member of [1,2,4,8,16].', simParameters.ueTxAnts(rnti));
            end
            if ~isfield(simParameters, 'ueRxAnts')
                simParameters.ueRxAnts = ones(simParameters.numUEs, 1);
                % Validate the number of receiver antennas on UEs
            elseif ~ismember(simParameters.ueRxAnts, [1,2,4,8,16])
                error('nr5g:metricsVisualizer:InvalidAntennaSize',...
                    'Number of UE Rx antennas (%d) must be a member of [1,2,4,8,16].', simParameters.ueRxAnts(rnti));
            end

            % Maximum number of transmission layers for each UE in DL
            numLayersDL = min(simParameters.gNBTxAnts*ones(simParameters.numUEs, 1), simParameters.ueRxAnts);
            % Maximum number of transmission layers for each UE in UL
            numLayersUL = min(simParameters.gNBRxAnts*ones(simParameters.numUEs, 1), simParameters.ueTxAnts);
            % Verify Duplex mode and update the properties
            if isfield(simParameters, 'duplexMode')
                duplexMode = simParameters.duplexMode;
            else
                duplexMode = 0; % FDD
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

            if duplexMode == 1 % TDD
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
                % Normalized scalars in the DL and UL directions are 1 for
                % FDD mode
                scaleFactorDL = 1;
                scaleFactorUL = 1;
            end

            % Calculate uplink and downlink peak data rates as per 3GPP TS
            % 37.910. The number of layers used for the peak DL or UL data
            % rate calculation is taken as the average of maximum layers
            % possible for each UE. The maximum layers possible for a UE
            % in DL direction is min(gNBTxAnts, ueRxAnts). For UL

            % direction, it is min(UETxAnts, gNBRxAnts)
            % Average of the peak DL, UL throughput values for each UE
            dlPeakDataRate = 1e-6*(sum(numLayersDL)/simParameters.numUEs)*scaleFactorDL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
            ulPeakDataRate = 1e-6*(sum(numLayersUL)/simParameters.numUEs)*scaleFactorUL*8*(948/1024)*(simParameters.numRBs*12)/symbolDuration;
        end

        function metrics = getMetrics(obj)
            %getMACMetrics Return the metrics after live visualization
            %
            % METRICS = getMetrics(OBJ) Returns the metrics corresponding
            % to the enabled metrics visualization.
            %
            % METRICS - It is a structure and returns simulation metrics
            % corresponding to the enabled visualizations. It has the
            % following fields.
            %   RLCMetrics - Metrics of RLC layer
            %   MACMetrics - Metrics of MAC layer
            %   PhyMetrics - Metrics of Phy layer

            metrics = struct('RLCMetrics',[],'MACMetrics',[],'PhyMetrics',[]);
            rntiList = obj.UEInfo(:,1);
            if obj.EnableRLCMetricsPlots
                dlRLCMetrics = table(obj.DLRLCMetrics(:,1), obj.DLRLCMetrics(:,2), obj.DLRLCMetrics(:,3));
                dlRLCMetrics.Properties.VariableNames = {'RNTI', 'LCID', obj.RLCMetricName};
                ulRLCMetrics = table(obj.ULRLCMetrics(:,1), obj.ULRLCMetrics(:,2), obj.ULRLCMetrics(:,3));
                ulRLCMetrics.Properties.VariableNames = {'RNTI', 'LCID', obj.RLCMetricName};
                metrics.RLCMetrics = struct('DL', dlRLCMetrics, 'UL', ulRLCMetrics);
            end

            if obj.EnableSchedulerMetricsPlots
                dlThroughput = obj.MACTxBytes(:, obj.DownlinkIdx);
                dlGoodput = obj.MACNewTxBytes(:, obj.DownlinkIdx);
                dlRBs = obj.ResourceShareMetrics(:, obj.DownlinkIdx);
                ulThroughput = obj.MACTxBytes(:, obj.UplinkIdx);
                ulGoodput = obj.MACNewTxBytes(:, obj.UplinkIdx);
                ulRBs = obj.ResourceShareMetrics(:, obj.UplinkIdx);
                macMetrics = table(rntiList, dlThroughput, dlGoodput, dlRBs, ...
                    ulThroughput, ulGoodput, ulRBs);
                macMetrics.Properties.VariableNames = {'RNTI', 'DL Tx Bytes', ...
                    'DL NewTx Bytes', 'DL RBs allocated', 'UL Tx Bytes', 'UL NewTx Bytes', 'UL RBs allocated'};
                metrics.MACMetrics = macMetrics;
            end

            if obj.EnablePhyMetricsPlots
                phyMetrics = table(rntiList, obj.DLBLERInfo(rntiList, 2),obj.DLBLERInfo(rntiList, 1), ...
                    obj.ULBLERInfo(rntiList, 2), obj.ULBLERInfo(rntiList, 1));
                phyMetrics.Properties.VariableNames = {'RNTI', 'Number of Packets (DL)', ...
                    'Erroneous Packets (DL)', 'Number of Packets (UL)', 'Erroneous Packets (UL)'};
                    metrics.PhyMetrics = phyMetrics;
            end
        end
    end

    methods(Access = private)
        function plotLiveRLCMetrics(obj)
            %plotLiveRLCMetrics Plots the RLC live metrics

            dlIdx = obj.DownlinkIdx+1; % DL index
            ulIdx = obj.UplinkIdx+1; % UL index
            numDLChannels = sum(obj.UEInfo(:, dlIdx));
            numULChannels = sum(obj.UEInfo(:, ulIdx));
            metricInfo = zeros(max(numULChannels, numDLChannels), 2);
            ueList = obj.Nodes.UEs;
            numUEs = numel(ueList);
            metricName = ['Stat' obj.RLCMetricName];

            if obj.VisualizationFlag ~= 0 % Uplink
                for ueIdx = 1:numUEs
                    rlcEntityList = ueList{ueIdx}.RLCEntities;
                    lchIdx = 1;
                    numRLCEntities = numel(rlcEntityList);
                    while lchIdx <= numRLCEntities && ~isempty(rlcEntityList{lchIdx})
                        metricIdx = find(rlcEntityList{lchIdx}.RNTI == obj.ULRLCMetrics(:, 1) & rlcEntityList{lchIdx}.LogicalChannelID == obj.ULRLCMetrics(:, 2));
                        if ~isempty(metricIdx)
                            metricInfo(metricIdx, obj.UplinkIdx) = rlcEntityList{lchIdx}.(metricName);
                        end
                        lchIdx = lchIdx + 1;
                    end
                end
                metricInfo(:, obj.UplinkIdx) = metricInfo(:, obj.UplinkIdx) - obj.ULRLCMetrics(:, 3);
                obj.ULRLCMetrics(:, 3) = obj.ULRLCMetrics(:, 3) + metricInfo(:, obj.UplinkIdx);
            end

            if obj.VisualizationFlag ~= 1 % Downlink
                rlcEntityList = obj.Nodes.GNB.RLCEntities;
                    for ueIdx = 1:numUEs
                        lchIdx = 1;
                        numRLCEntities = numel(rlcEntityList(ueIdx, :));
                        while lchIdx <= numRLCEntities && ~isempty(rlcEntityList{ueIdx, lchIdx})
                            metricIdx = find(rlcEntityList{ueIdx, lchIdx}.RNTI == obj.DLRLCMetrics(:,1) & rlcEntityList{ueIdx, lchIdx}.LogicalChannelID == obj.DLRLCMetrics(:,2));
                            if ~isempty(metricIdx)
                                metricInfo(metricIdx, obj.DownlinkIdx) = rlcEntityList{ueIdx, lchIdx}.(metricName);
                            end
                            lchIdx = lchIdx + 1;
                        end
                    end
                metricInfo(:, obj.DownlinkIdx) = metricInfo(:, obj.DownlinkIdx) - obj.DLRLCMetrics(:, 3);
                obj.DLRLCMetrics(:, 3) = obj.DLRLCMetrics(:, 3) + metricInfo(:, obj.DownlinkIdx);
            end

            updateRLCMetrics(obj, metricInfo');
        end

        function plotLiveMACMetrics(obj)
            %plotLiveMetrics Plots the MAC live metrics

            ueList = obj.Nodes.UEs;
            numUEs = numel(ueList);
            throughput = zeros(numUEs, 2);
            goodput = zeros(numUEs, 2);
            bufferstatus = zeros(numUEs, 2);
            resourceshare = zeros(numUEs, 2);
            cellThroughputMetrics = zeros(2, 2);
            cellGoodputMetrics = zeros(2, 2);

            if obj.VisualizationFlag ~= 0 % Uplink
                for ueIdx = 1:numUEs
                    node = ueList{ueIdx}.MACEntity;

                    % Instant metrics calculation
                    throughput(ueIdx, obj.UplinkIdx) = (node.StatTxThroughputBytes - obj.MACTxBytes(ueIdx, obj.UplinkIdx))* 8 / (obj.MetricsStepDuration * 1000);
                    goodput(ueIdx, obj.UplinkIdx) = (node.StatTxGoodputBytes - obj.MACNewTxBytes(ueIdx, obj.UplinkIdx))* 8 / (obj.MetricsStepDuration * 1000);
                    bufferstatus(ueIdx, obj.UplinkIdx) = getBufferStatus(ueList{ueIdx}) / 1000; % In KB;
                    resourceshare(ueIdx, obj.UplinkIdx) = node.StatResourceShare - obj.ResourceShareMetrics(ueIdx, obj.UplinkIdx);

                    % Save the previous metrics
                    obj.MACTxBytes(ueIdx, obj.UplinkIdx) = node.StatTxThroughputBytes;
                    obj.MACNewTxBytes(ueIdx, obj.UplinkIdx) = node.StatTxGoodputBytes;
                    obj.ResourceShareMetrics(ueIdx, obj.UplinkIdx) = node.StatResourceShare;
                end

                % Cell level metrics
                numRBScheduled = sum(resourceshare(:, obj.UplinkIdx));
                resourceshare(:, obj.UplinkIdx) = ((resourceshare(:, obj.UplinkIdx) ./ numRBScheduled) * 100); % Percent share
                cellThroughputMetrics(1, obj.UplinkIdx) = sum(throughput(:, obj.UplinkIdx)); % Cell throughput
                cellThroughputMetrics(2, obj.UplinkIdx) = obj.PeakDataRate(obj.UplinkIdx); % Peak datarate
                cellGoodputMetrics(1, obj.UplinkIdx) = sum(goodput(:, obj.UplinkIdx)); % Cell goodput
                cellGoodputMetrics(2, obj.UplinkIdx) = obj.PeakDataRate(obj.UplinkIdx); % Peak datarate
            end

            if obj.VisualizationFlag ~= 1 % Downlink
                gNBMAC = obj.Nodes.GNB.MACEntity;

                % Instant metrics calculation
                throughput(:, obj.DownlinkIdx) = (gNBMAC.StatTxThroughputBytes - obj.MACTxBytes(:, obj.DownlinkIdx))* 8 / (obj.MetricsStepDuration * 1000);
                goodput(:, obj.DownlinkIdx) = (gNBMAC.StatTxGoodputBytes - obj.MACNewTxBytes(:, obj.DownlinkIdx))* 8 / (obj.MetricsStepDuration * 1000);
                bufferstatus(:, obj.DownlinkIdx) = getBufferStatus(obj.Nodes.GNB) ./ 1000; % In KB;
                resourceshare(:, obj.DownlinkIdx) = gNBMAC.StatResourceShare - obj.ResourceShareMetrics(:, obj.DownlinkIdx);

                % Cell level metrics
                numRBScheduled = sum(resourceshare(:, obj.DownlinkIdx));
                resourceshare(:, obj.DownlinkIdx) = (resourceshare(:, obj.DownlinkIdx) ./ numRBScheduled) * 100;
                cellThroughputMetrics(1, obj.DownlinkIdx) = sum(throughput(:, obj.DownlinkIdx)); % Cell throughput
                cellThroughputMetrics(2, obj.DownlinkIdx) = obj.PeakDataRate(obj.DownlinkIdx); % Peak datarate
                cellGoodputMetrics(1, obj.DownlinkIdx) = sum(goodput(:, obj.DownlinkIdx)); % Cell goodput
                cellGoodputMetrics(2, obj.DownlinkIdx) = obj.PeakDataRate(obj.DownlinkIdx); % Peak datarate

                % Save the previous metrics
                obj.MACTxBytes(:, obj.DownlinkIdx) = gNBMAC.StatTxThroughputBytes;
                obj.MACNewTxBytes(:, obj.DownlinkIdx) = gNBMAC.StatTxGoodputBytes;
                obj.ResourceShareMetrics(:, obj.DownlinkIdx) = gNBMAC.StatResourceShare;
            end

            throughput = [throughput(obj.UEOfInterestListInfo, :); cellThroughputMetrics];
            goodput = [goodput(obj.UEOfInterestListInfo, :); cellGoodputMetrics];

           updateMACMetrics(obj, throughput', resourceshare', goodput', bufferstatus(obj.UEOfInterestListInfo, :)');
        end

        function plotLivePhyMetrics(obj)
            %plotLivePhyMetrics Plots the Phy live metrics

            ueList = obj.Nodes.UEs;
            numUEs = numel(ueList);
            blerData = zeros(2, numUEs);
            dlBLERInfo = zeros(numUEs, 2);
            count = 1;

            if obj.VisualizationFlag ~= 1 % Downlink
                for idx = 1:numUEs
                    dlBLERInfo(count, :) = ueList{idx}.PhyEntity.DLBlkErr;
                    count = count + 1;
                end
                blerData(obj.DownlinkIdx, :) = ((dlBLERInfo(:, 1) - obj.DLBLERInfo(:, 1)) ./ (dlBLERInfo(:, 2) - obj.DLBLERInfo(:, 2)))';
                obj.DLBLERInfo = dlBLERInfo;
            end

            if obj.VisualizationFlag ~= 0 % Uplink
                ulBLERInfo = obj.Nodes.GNB.PhyEntity.ULBlkErr;
                blerData(obj.UplinkIdx, :) = ((ulBLERInfo(:, 1) - obj.ULBLERInfo(:, 1)) ./ (ulBLERInfo(:, 2) - obj.ULBLERInfo(:, 2)))';
                obj.ULBLERInfo = ulBLERInfo;
            end
            blerData = blerData(:, obj.UEOfInterestListInfo');
            updatePhyMetrics(obj, blerData);
        end
        
        function plotRLCMetrics(obj, slotNum)
            %plotRLCMetrics Plots the RLC metrics
            %
            % plotRLCMetrics(OBJ, SLOTNUM) Plots the metrics of each logical
            % channel of each UE

            dlIdx = obj.DownlinkIdx+1; % DL index
            ulIdx = obj.UplinkIdx+1; % UL index
            numDLChannels = sum(obj.UEInfo(:, dlIdx));
            numULChannels = sum(obj.UEInfo(:, ulIdx));
            metricInfo = zeros(2, max(numULChannels, numDLChannels));
            dlCount = 1;
            ulCount = 1;
            [dlMetrics, ulMetrics] = getRLCMetrics(obj.RLCLogger, ...
                slotNum-obj.MetricsStepSize+1, slotNum, obj.UEInfo(:, 1), obj.RLCMetricName);

            for ueIdx=1:size(obj.UEInfo, 1)
                if ~isempty(dlMetrics)
                    metricInfo(obj.DownlinkIdx, dlCount:dlCount+obj.UEInfo(ueIdx, dlIdx)-1) = dlMetrics(ueIdx).MetricValue;
                    dlCount = dlCount+obj.UEInfo(ueIdx, dlIdx);
                end

                if ~isempty(ulMetrics)
                    metricInfo(obj.UplinkIdx, ulCount:ulCount+obj.UEInfo(ueIdx, ulIdx)-1) = ulMetrics(ueIdx).MetricValue;
                    ulCount = ulCount+obj.UEInfo(ueIdx, ulIdx);
                end
            end

            updateRLCMetrics(obj, metricInfo);
        end

        function plotMACMetrics(obj, slotNum)
            %plotMACMetrics Plot the MAC metrics
            %
            % plotMACMetrics(OBJ, SLOTNUM) Plots the metrics of each UE

            numUEs = numel(obj.UEOfInterestListInfo);
            throughput = zeros(2, numUEs+2);
            goodput = zeros(2, numUEs+2);
            bufferstatus = zeros(2, numUEs);
            resourceshare = zeros(2, numUEs);

            [dlMetrics, ulMetrics, cellMetrics] = getMACMetrics(obj.MACLogger, slotNum-obj.MetricsStepSize+1, slotNum, obj.UEOfInterestListInfo);
            if ~isempty(dlMetrics)
                throughput(obj.DownlinkIdx, 1:numUEs) = [dlMetrics.TxBytes] .* 8 ./ (obj.MetricsStepDuration * 1000);
                throughput(obj.DownlinkIdx, numUEs+1) = cellMetrics.DLTxBytes .* 8 ./ (obj.MetricsStepDuration * 1000); % Cell throughput
                throughput(obj.DownlinkIdx, numUEs+2) = obj.PeakDataRate(obj.DownlinkIdx); % Peak datarate
                goodput(obj.DownlinkIdx, 1:numUEs) = [dlMetrics.NewTxBytes] .* 8 ./ (obj.MetricsStepDuration * 1000);
                goodput(obj.DownlinkIdx, numUEs+1) = cellMetrics.DLNewTxBytes .* 8 ./ (obj.MetricsStepDuration * 1000); % Cell goodput
                goodput(obj.DownlinkIdx, numUEs+2) = obj.PeakDataRate(obj.DownlinkIdx); % Peak datarate
                bufferstatus(obj.DownlinkIdx, 1:numUEs) = [dlMetrics.BufferStatus] ./ 1000; % In KB
                resourceshare(obj.DownlinkIdx, 1:numUEs) = ([dlMetrics.AssignedRBCount] * 100) ./ cellMetrics.DLRBsScheduled; % Percent share
            end

            if ~isempty(ulMetrics)
                throughput(obj.UplinkIdx, 1:numUEs) = [ulMetrics.TxBytes] .* 8 ./ (obj.MetricsStepDuration * 1000);
                throughput(obj.UplinkIdx, numUEs+1) = cellMetrics.ULTxBytes .* 8 ./ (obj.MetricsStepDuration * 1000); % Cell throughput
                throughput(obj.UplinkIdx, numUEs+2) = obj.PeakDataRate(obj.UplinkIdx); % Peak datarate
                goodput(obj.UplinkIdx, 1:numUEs) = [ulMetrics.NewTxBytes] .* 8 ./ (obj.MetricsStepDuration * 1000);
                goodput(obj.UplinkIdx, numUEs+1) = cellMetrics.ULNewTxBytes .* 8 ./ (obj.MetricsStepDuration * 1000); % Cell goodput
                goodput(obj.UplinkIdx, numUEs+2) = obj.PeakDataRate(obj.UplinkIdx); % Peak datarate
                bufferstatus(obj.UplinkIdx, 1:numUEs) = [ulMetrics.BufferStatus] ./ 1000; % In KB
                resourceshare(obj.UplinkIdx, 1:numUEs) = ([ulMetrics.AssignedRBCount] * 100) ./ cellMetrics.ULRBsScheduled; % Percent share
            end
            updateMACMetrics(obj, throughput, resourceshare, goodput, bufferstatus);
        end

        function plotPhyMetrics(obj, slotNum)
            %plotPhyMetrics Plot the Phy metrics
            %
            % plotPhyMetrics(OBJ, SLOTNUM) Plots the metrics of each UE

            numUEs = size(obj.UEOfInterestListInfo, 1);
            blerData = zeros(2, numUEs);

            % Get Phy metrics
            [dlMetrics, ulMetrics] = getPhyMetrics(obj.PhyLogger, slotNum-obj.MetricsStepSize+1, slotNum, obj.UEOfInterestListInfo(:, 1));

            if ~isempty(dlMetrics)
                blerData(obj.DownlinkIdx, :) = [dlMetrics.ErroneousPackets] ./ [dlMetrics.TotalPackets];
            end
            if ~isempty(ulMetrics)
                blerData(obj.UplinkIdx, :) = [ulMetrics.ErroneousPackets] ./ [ulMetrics.TotalPackets];
            end
            updatePhyMetrics(obj, blerData);
        end

        function updateRLCMetrics(obj, metricInfo)
            %updateRLCMetrics Update the RLC metric plot

            metricInfo(isnan(metricInfo)) = 0; % To handle NaN

            % Update the plots
            if numel(obj.PlotIDs) == 1
                if ismember(obj.DownlinkIdx, obj.PlotIDs)
                    obj.RLCVisualization(metricInfo(obj.PlotIDs, obj.DLRLCMetricsIdx));
                else
                    obj.RLCVisualization(metricInfo(obj.PlotIDs, obj.ULRLCMetricsIdx));
                end
            else
                obj.RLCVisualization(metricInfo(obj.DownlinkIdx, obj.DLRLCMetricsIdx), metricInfo(obj.UplinkIdx, obj.ULRLCMetricsIdx));
            end
        end

        function updateMACMetrics(obj, throughput, resourceshare, goodput, bufferstatus)
            %updateMACMetrics Update the MAC metric plots

            % To handle NaN
            throughput(isnan(throughput)) = 0;
            resourceshare(isnan(resourceshare)) = 0;
            goodput(isnan(goodput)) = 0;
            bufferstatus(isnan(bufferstatus)) = 0;

            % Determine the maximum UEs to plot the metrics
            numUEs = size(bufferstatus, 2); % Number of UEs
            cellLevelMetricsIdx = [numUEs+1 numUEs+2];
            if numUEs > obj.MaxMACMetricNodes
                numUEs = obj.MaxMACMetricNodes;
            end
            cellLevelMetricsIdx = [(1:numUEs) cellLevelMetricsIdx];

            for plotIdx = 1:numel(obj.PlotIDs)
                plotId = obj.PlotIDs(plotIdx);
                obj.MACVisualization{plotId}(throughput(plotId, cellLevelMetricsIdx), resourceshare(plotId, 1:numUEs), goodput(plotId, cellLevelMetricsIdx), bufferstatus(plotId, 1:numUEs));
            end
        end

        function updatePhyMetrics(obj, blerData)
            %updatePhyMetrics Update the Phy metrics

            blerData(isnan(blerData)) = 0; % To handle NaN

            % Determine the maximum UEs to plot the metrics
            numUEs = size(blerData, 2); % Number of UEs
            if numUEs > obj.MaxPhyMetricNodes
                numUEs = obj.MaxPhyMetricNodes;
            end

            % Update the plots
            if numel(obj.PlotIDs) == 1
                obj.PhyVisualization(blerData(obj.PlotIDs, 1:numUEs));
            else
                obj.PhyVisualization(blerData(obj.DownlinkIdx, 1:numUEs), blerData(obj.UplinkIdx, 1:numUEs));
            end
        end
    end
end