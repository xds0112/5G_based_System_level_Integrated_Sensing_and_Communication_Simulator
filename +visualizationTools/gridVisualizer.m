classdef gridVisualizer < handle
    %gridVisualizer Scheduler log visualization
    %   The class implements visualization of logs by querying from the
    %   logger (schedulingLogger object).
    %   The following two types of visualizations are shown:
    %    (i) Display of CQI values for UEs over the bandwidth
    %   (ii) Display of resource grid assignment to UEs. This 2D time-frequency
    %        grid shows the RB allocation to the UEs in the previous slot for
    %        symbol based scheduling and previous frame for slot based
    %        scheduling. HARQ process for the assignments is also shown
    %        alongside the UE's RNTI
    %
    %   gridVisualizer methods:
    %
    %   plotRBGrids         - Plot RB grid visualization
    %   plotCQIRBGrids      - Plot the CQI grid visualization
    %   plotPostSimRBGrids  - Plot post-simulation grid visualization
    %
    %   gridVisualizer Name-Value pairs:
    %
    %   CellOfInterest    - Cell ID to which the visualization object belongs
    %   MACLogger         - MAC logger handle object
    %   VisualizationFlag - Flag to indicate the plots to visualize
    %   IsLogReplay       - Flag to decide the type of post-simulation visualization

    %   Copyright 2021 The MathWorks, Inc.

    properties
        %CellOfInterest Cell ID to which the visualization object belongs
        CellOfInterest (1, 1) {mustBeInteger, mustBeInRange(CellOfInterest, 0, 1007)} = 1;

        %MACLogger MAC logger handle object
        MACLogger

        %VisualizationFlag  Indicates the plots to visualize
        % It takes the values 0, 1, 2 and represent downlink, uplink, and both
        % respectively. Default value is 2.
        VisualizationFlag (1, 1) {mustBeInteger, mustBeInRange(VisualizationFlag, 0, 2)} = 2;

        %IsLogReplay Flag to decide the type of post-simulation visualization
        % whether to show plain replay of the resource assignment during
        % simulation or of the selected slot (or frame). During the
        % post-simulation visualization, setting the value to 1 just
        % replays the resource assignment of the simulation frame-by-frame
        % (or slot-by-slot). Setting value to 0 gives the option to select
        % a particular frame (or slot) to see the way resources are
        % assigned in the chosen frame (or slot)
        IsLogReplay
    end

    properties(Hidden)
        % EnableResourceGridVisualization Switch to turn on/off the resource grid visualization (resource-grid occupancy)
        EnableResourceGridVisualization = false;

        %RGMaxRBsToDisplay Max number of RBs displayed in resource grid visualization
        RGMaxRBsToDisplay = 20

        %RGMaxSlotsToDisplay Max number of slots displayed in resource grid visualization
        RGMaxSlotsToDisplay = 10

        %EnableCQIGridVisualization Switch to turn on/off the CQI grid visualization
        EnableCQIGridVisualization = false;

        %CVMaxRBsToDisplay Max number of RBs to be displayed in CQI visualization
        CVMaxRBsToDisplay = 20

        %CVMaxUEsToDisplay Max number of UEs to be displayed in CQI visualization
        CVMaxUEsToDisplay = 10

        %CQIVisualizationFigHandle Handle of the CQI visualization
        CQIVisualizationFigHandle

        %RGVisualizationFigHandle Handle of the resource grid visualization
        RGVisualizationFigHandle
    end

    properties (Constant)
        %NumSym Number of symbols in a slot
        NumSym = 14;

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

        %ColorCoding Mapping of a range of CQI values to particular color
        ColorCoding = [0.85 0.32 0.09 ; 0.85 0.32 0.09; 0.88 0.50 0.09; 0.88 0.50 0.09; ...
            0.93 0.69 0.13; 0.93 0.69 0.13; 0.98 0.75 0.26; 0.98 0.75 0.26; ...
            0.98 0.82 0.14; 0.98 0.82 0.14; 0.8 0.81 0.16; 0.8 0.81 0.16; ...
            0.68 0.71 0.18; 0.68 0.71 0.18; 0.46 0.67 0.18; 0.46 0.67 0.18];
    end

    properties (Access = private)
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

        %NumRBs Number of resource blocks
        % A vector of two elements. First element represents number of
        % PDSCH RBs and second element represents number of PUSCH RBs
        NumRBs = zeros(2, 1);

        %NumSlotsFrame Number of slots in 10ms time frame
        NumSlotsFrame

        %CurrFrame Current frame number
        CurrFrame

        %CurrSlot Current slot in the frame
        CurrSlot

        %NumLogs Number of logs to be created based on number of links
        NumLogs = 2;

        %SymSlotInfo Information about how each symbol/slot (UL/DL/Guard) is allocated
        SymSlotInfo

        %PlotIds IDs of the plots
        PlotIds

        %RBItemsList Items List for RBs drop down for DL and UL
        RBItemsList = cell(2, 1);

        %Resource grid information related properties
        % ResourceGrid In FDD mode first element contains downlink resource
        % grid allocation status and second element contains uplink
        % resource grid allocation status. In TDD mode first element
        % contains resource grid allocation status for downlink and uplink.
        % Each element is a 2D resource grid of N-by-P matrix where 'N' is
        % the number of slot or symbols and 'P' is the number of RBs in the
        % bandwidth to store how UEs are assigned different time-frequency
        % resources.
        ResourceGrid = cell(2, 1);

        %ResourceGridReTxInfo First element contains transmission status
        % in downlink and second element contains transmission status in
        % uplink for FDD mode. In TDD mode first element contains
        % transmission status for both downlink and uplink. Each element is
        % a 2D resource grid of N-by-P matrix where 'N' is the number of
        % slot or symbols and 'P' is the number of RBs in the bandwidth to
        % store type:new-transmission or retransmission.
        ResourceGridReTxInfo = cell(2, 1);

        %ResourceGridHarqInfo In FDD mode first element contains downlink
        % HARQ information and second element contains uplink HARQ
        % information. In TDD mode first element contains HARQ information
        % for downlink and uplink. Each element is a 2D resource grid of
        % N-by-P matrix where 'N' is the number of slot or symbols and 'P'
        % is the number of RBs in the bandwidth to store the HARQ process
        ResourceGridHarqInfo

        %ResourceGridTextHandles Text handles to display of the RNTI for the RBs
        ResourceGridTextHandles

        %ResourceGridInfo Text information for ResourceGridTextHandles.
        % First element contains text related to downlink and second
        % element contains text related to uplink for FDD mode. In TDD mode
        % first element contains text related to both downlink and uplink.
        ResourceGridInfo = cell(2, 1)

        %RVCurrView Type of scheduler scheduling information displayed in
        % CQI Visualization. Value 1 represents downlink and value 2
        % represents uplink
        RVCurrView = 1

        %RGTxtHandle UI control handle to display the frame number in resource grid visualization
        RGTxtHandle

        %RGSlotTxtHandle UI control handle to display the slot number in resource grid visualization
        RGSlotTxtHandle

        %RGLowerRBIndex Index of the first RB displayed in resource grid visualization
        RGLowerRBIndex = 0

        %RGUpperRBIndex Index of the last RB displayed in resource grid visualization
        RGUpperRBIndex

        %RGLowerSlotIndex Index of the first slot displayed in resource grid visualization
        RGLowerSlotIndex = 0

        %RGUpperSlotIndex Index of the last slot displayed in resource grid visualization
        RGUpperSlotIndex

        % CQI information related properties
        %CQIInfo First element contains downlink CQI information and
        % second element contains uplink CQI information. Each element is
        % a N-by-P matrix where 'N' is the number of UEs and 'P' is the
        % number of RBs in the bandwidth. A matrix element at position (i,
        % j) corresponds to CQI value for UE with RNTI 'i' at RB 'j'
        CQIInfo = cell(2, 1);

        %CQIVisualizationGridHandles Handles to display UE CQIs on the RBs of the bandwidth
        CQIVisualizationGridHandles

        %CQIMapHandle Handle of the CQI heat map
        CQIMapHandle

        %CVCurrView Type of channel quality displayed in CQI
        % Visualization. Value 1 represents downlink and value 2 represents
        % uplink
        CVCurrView = 1

        %CVLowerUEIndex Index of the first UE to be displayed in CQI visualization
        CVLowerUEIndex = 0

        %CVUpperUEIndex Index of the last UE to be displayed in CQI visualization
        CVUpperUEIndex

        %CVLowerRBIndex Index of the first RB to be displayed in CQI visualization
        CVLowerRBIndex = 0

        %CVUpperRBIndex Index of the last RB to be displayed in CQI visualization
        CVUpperRBIndex

        %CVTxtHandle UI control handle to display the frame number in CQI visualization
        CVTxtHandle
    end

    properties(Hidden)
        %IsAppVisualization Flag to control the GUI elements on the grid
        IsAppVisualization = false;
    end

    methods
        function obj = gridVisualizer(simParameters,  varargin)
            %gridVisualizer Construct scheduling log visualization object
            %
            % OBJ = hNRGridVisualizer(SIMPARAMETERS) Create grid
            % visualization object. It creates figures for visualizing both
            % downlink and uplink information.
            %
            % OBJ = hNRGridVisualizer(SIMPARAMETERS, ISLOGANALYSIS) Create
            % grid visualization object.
            %
            % SIMPARAMETERS - It is a structure and contain simulation
            % configuration information.
            %
            % NumFramesSim      - Simulation time in terms of number of 10 ms frames
            % NumUEs            - Number of UEs
            % DuplexMode        - Duplexing mode (FDD or TDD)
            % SchedulingType    - Slot-based or symbol-based scheduling
            % NumHARQ           - Number of HARQ processes
            % NumRBs            - Number of resource blocks in PUSCH and PDSCH bandwidth
            % SCS               - Subcarrier spacing
            % TTIGranularity    - Minimum TTI granularity in terms of
            %                     number of symbols (for symbol-based scheduling)
            %
            % If FLAG = 0, Visualize downlink information.
            % If FLAG = 1, Visualize uplink information.
            % If FLAG = 2, Visualize  downlink and uplink information.
            %
            % ISLOGANALYSIS = true Gives the option to select a particular frame
            % (or slot) to see the way resources are assigned in the chosen
            % frame (or slot).
            % ISLOGANALYSIS = false Replays the resource assignment of the simulation
            % frame-by-frame (or slot-by-slot).

            % Initialize the properties
            for idx = 1:2:numel(varargin)
                obj.(varargin{idx}) = varargin{idx+1};
            end

            % Validate number of frames in simulation
            validateattributes(simParameters.numFrames, {'numeric'}, {'nonempty', 'integer', 'scalar', 'finite', '>', 0}, 'simParameters.NumFramesSim', 'NumFramesSim');
            obj.NumFrames = simParameters.numFrames;

            obj.NumUEs = simParameters.numUEs;
            if isfield(simParameters, 'NumHARQ')
                obj.NumHARQ = simParameters.NumHARQ;
            end
            if isfield(simParameters, 'schedulingType')
                obj.SchedulingType = simParameters.schedulingType;
            end
            obj.NumSlotsFrame = (10 * simParameters.scs) / 15; % Number of slots in a 10 ms frame

            % Verify Duplex mode and update the properties
            if isfield(simParameters, 'duplexMode')
                obj.DuplexMode = simParameters.duplexMode;
            end
            if obj.DuplexMode == obj.TDDDuplexMode % TDD
                obj.NumLogs = 1;
                obj.RVCurrView = 1; % Only one view for resource grid
            end

            % Determine the plots
            % Downlink & Uplink
            obj.PlotIds = [obj.DownlinkIdx obj.UplinkIdx];
            % Show the enabled visualization as current view
            if obj.VisualizationFlag ~= 2
                obj.PlotIds = obj.VisualizationFlag+1;
                obj.RVCurrView = obj.PlotIds;
                obj.CVCurrView = obj.PlotIds;
            end

            % Initialize number of RBs, CQI and metrics properties
            for idx = 1: numel(obj.PlotIds)
                logIdx = obj.PlotIds(idx);
                obj.NumRBs(logIdx) = simParameters.numRBs; % Number of RBs in DL/UL
                obj.CQIInfo{logIdx} = zeros(obj.NumUEs, obj.NumRBs(logIdx)); % DL/UL channel quality
            end

            if obj.SchedulingType % Symbol based scheduling
                gridLength = obj.NumSym;
            else % Slot based scheduling
                gridLength = obj.NumSlotsFrame;
            end

            % Initialize the scheduling logs and resources grid related
            % properties
            for idx=1:min(obj.NumLogs,numel(obj.PlotIds))
                plotId = obj.PlotIds(idx);
                if obj.DuplexMode == obj.FDDDuplexMode
                    logIdx = plotId; % FDD
                else
                    logIdx = idx; % TDD
                end
                % Construct the log format
                obj.ResourceGrid{logIdx} = zeros(gridLength, obj.NumRBs(plotId));
                obj.ResourceGridReTxInfo{logIdx} = zeros(gridLength, obj.NumRBs(plotId));
                obj.ResourceGridHarqInfo{logIdx} = zeros(gridLength, obj.NumRBs(plotId));
                obj.ResourceGridInfo{logIdx} = strings(gridLength, obj.NumRBs(plotId));
            end

            if ~obj.IsAppVisualization
                setupGUI(obj, simParameters);
            end
        end

        function plotCQIRBGrids(obj, varargin)
            %plotCQIRBGrids Updates the CQI grid visualization
            %
            % plotCQIRBGrids(OBJ, SIMSLOTNUM) To update the CQI
            % grid and CQI visualization in live visualization
            %
            % SIMSLOTNUM - Cumulative slot number in the simulation

            % Update frame number in the figure (in live visualization)
            if isempty(obj.IsLogReplay)
                slotNum = varargin{1};
                obj.CurrFrame = floor(slotNum / obj.NumSlotsFrame)-1;
                obj.CurrSlot = mod(slotNum-1, obj.NumSlotsFrame);
            end
            updateCQIVisualization(obj);
            drawnow;
        end

        function plotRBGrids(obj, varargin)
            %plotRBGrids Updates the resource grid visualization
            %
            % plotRBGrids(OBJ) To update the resource
            % grid and CQI visualization in post-simulation visualization
            %
            % plotRBGrids(OBJ, SIMSLOTNUM) To update the resource
            % grid and CQI visualization in live visualization
            %
            % SIMSLOTNUM - Cumulative slot number in the simulation

            % Check if the figure handle is valid
            if isempty(obj.RGVisualizationFigHandle) || ~ishghandle(obj.RGVisualizationFigHandle)
                return;
            end

            % Update frame number in the figure (in live visualization)
            if isempty(obj.IsLogReplay)
                slotNum = varargin{1};
                obj.CurrFrame = floor((slotNum-1) / obj.NumSlotsFrame);
                if obj.CurrFrame < 0
                    obj.CurrFrame = 0;
                end
                obj.CurrSlot = mod(slotNum-1, obj.NumSlotsFrame);
            end

            if isempty(obj.CurrFrame)
                return;
            end
            if obj.DuplexMode == obj.TDDDuplexMode
                [obj.ResourceGrid, obj.ResourceGridReTxInfo, obj.ResourceGridHarqInfo, obj.SymSlotInfo] = obj.MACLogger.getRBGridsInfo(obj.CurrFrame, obj.CurrSlot);
            else
                [obj.ResourceGrid, obj.ResourceGridReTxInfo, obj.ResourceGridHarqInfo] = obj.MACLogger.getRBGridsInfo(obj.CurrFrame, obj.CurrSlot);
            end
            for idx = 1:min(obj.NumLogs, numel(obj.PlotIds))
                plotId = obj.PlotIds(idx);
                if obj.DuplexMode == obj.FDDDuplexMode
                    logIdx = obj.PlotIds(idx);
                else
                    logIdx = 1;
                end

                slIdx = size(obj.ResourceGrid{logIdx}, 1);
                for p = 1:slIdx
                    for q = 1 : obj.NumRBs(plotId)
                        if(obj.ResourceGrid{logIdx}(p, q) == 0)
                            % Clear the previously plotted text in the resource grid
                            obj.ResourceGridInfo{logIdx}(p, q)  = '';
                        else
                            % Create the text to be plotted in the resource
                            % grid
                            obj.ResourceGridInfo{logIdx}(p, q) = strcat('UE-', num2str(obj.ResourceGrid{logIdx}(p, q)), ...
                                '( ', num2str(obj.ResourceGridHarqInfo{logIdx}(p, q)), ')');
                        end
                    end
                end
            end
            updateResourceGridVisualization(obj);
        end

        function constructCQIGridVisualization(obj, varargin)
            %constructCQIGridVisualization Construct CQI grid visualization
            %
            % constructCQIGridVisualization(OBJ, GLOBJ) Construct CQI grid visualization
            %
            % GLOBJ - Grid layout object

            if nargin == 2
                g = varargin{1};
            else
                g = uigridlayout(obj.CQIVisualizationFigHandle);
                g.ColumnWidth = {100,100,600,'1x'};
                g.RowHeight = {22,22,22,22,22,22,22,'1x'};
            end

            if obj.VisualizationFlag == 2
                lb1 = uilabel(g,'Text','Select Link');
                lb1.Layout.Row = 3;
                lb1.Layout.Column = 1;

                % Link direction
                dd1 = uidropdown(g,'Items',{'Downlink','Uplink'}, 'ItemsData', obj.PlotIds, 'ValueChangedFcn', @(dd, event) cbSelectedLinkType(obj, dd.Value));
                dd1.Layout.Row = 3;
                dd1.Layout.Column = 2;
                compCounter = dd1.Layout.Row;
            else
                compCounter = 2;
            end
            maxRBs = max(obj.NumRBs(obj.PlotIds));
            if obj.CVMaxRBsToDisplay <= maxRBs
                compCounter = compCounter + 1;
                obj.CVUpperRBIndex = obj.CVMaxRBsToDisplay;
                lb2 = uilabel(g,'Text','Select RB Range');
                lb2.Layout.Row = compCounter;
                lb2.Layout.Column = 1;
                [items, itemsData] = constructRBItemList(obj, obj.NumRBs(obj.CVCurrView));
                dd2 = uidropdown(g,'Items',items, 'ItemsData', itemsData, 'ValueChangedFcn', @(dd, event) cbSelectedRBRange(obj, dd.Value));
                dd2.Layout.Row = compCounter;
                dd2.Layout.Column = 2;
            else
                obj.CVUpperRBIndex = maxRBs;
            end

            % Number of UEs to be displayed in the default view of CQI visualization
            if obj.NumUEs >= obj.CVMaxUEsToDisplay
                compCounter = compCounter + 1;
                obj.CVUpperUEIndex = obj.CVMaxUEsToDisplay;
                obj.CVUpperRBIndex = obj.CVMaxRBsToDisplay;
                lb2 = uilabel(g,'Text','Select UE Range');
                lb2.Layout.Row = compCounter;
                lb2.Layout.Column = 1;
                [items, itemsData] = cvDropDownForUERange(obj);
                dd2 = uidropdown(g,'Items',items, 'ItemsData', itemsData, 'ValueChangedFcn', @(dd, event) cbSelectedUERange(obj, dd.Value));
                dd2.Layout.Row = compCounter;
                dd2.Layout.Column = 2;
            else
                obj.CVUpperUEIndex = obj.NumUEs;
            end

            % If post simulation log analysis enabled
            if isempty(obj.IsLogReplay) || obj.IsLogReplay
                % Create label for frame number
                compCounter = compCounter + 1;
                lb3 = uilabel(g, 'Text', 'Frame Number: ');
                lb3.Layout.Row = compCounter;
                lb3.Layout.Column = 1;
                obj.CVTxtHandle = uilabel(g, 'Text', ' ');
                obj.CVTxtHandle.Layout.Row = compCounter;
                obj.CVTxtHandle.Layout.Column = 2;
            else
                if obj.IsAppVisualization
                    compCounter = compCounter + 1;
                    lb3 = uilabel(g, 'Text', 'Total Frames: ');
                    lb3.Layout.Row = compCounter;
                    lb3.Layout.Column = 1;
                    lb3 = uilabel(g, 'Text', num2str(obj.NumFrames));
                    lb3.Layout.Row = compCounter;
                    lb3.Layout.Column = 2;
                end
                compCounter = compCounter + 1;
                lb4  = uilabel(g, 'Text','Frame number');
                lb4.Layout.Row = compCounter;
                lb4.Layout.Column = 1;
                if obj.IsAppVisualization
                    obj.CVTxtHandle = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', @(dd, event) showFrame(obj, dd.Value));
                else
                    obj.CVTxtHandle = uilabel(g, 'Text', ' ');
                end
                obj.CVTxtHandle.Layout.Row = compCounter;
                obj.CVTxtHandle.Layout.Column = 2;
            end

            % Construct the CQI map
            numRBsToDisplay = obj.CVUpperRBIndex - obj.CVLowerRBIndex;
            numUEsToDisplay = obj.CVUpperUEIndex - obj.CVLowerUEIndex;
            obj.CQIMapHandle = heatmap(g, zeros(numRBsToDisplay, numUEsToDisplay), ...
                'CellLabelColor', 'none', 'Colormap', obj.ColorCoding, 'XLabel', 'UEs', 'YLabel', ...
                'Resource Blocks', 'ColorLimits', [0 15], 'Title', ['Channel  Quality Visualization for Cell ID - '  num2str(obj.CellOfInterest)]);

            % Set CQI-visualization axis label
            updateCQIMapProperties(obj);

            % Set the layout
            obj.CQIMapHandle.Layout.Row = [1 8];
            obj.CQIMapHandle.Layout.Column = [3 4];
        end

        function constructResourceGridVisualization(obj, varargin)
            %constructResourceGridVisualization Construct resource grid visualization
            %
            % constructResourceGridVisualization(OBJ, GLOBJ) Construct resource grid visualization
            %
            % GLOBJ - Grid layout object

            if nargin == 2
                compCounter = 3;
                g = varargin{1};
            else
                compCounter = 3;
                g = uigridlayout(obj.RGVisualizationFigHandle);
                g.ColumnWidth = {100,100,'1x'};
                g.RowHeight = {22,22,22,22,22,22,22,22,22,22,22,22,22,'1x'};
            end
            lb1 = uilabel(g,'Text','UE-x(n) : Transmission');
            lb1.Layout.Row = compCounter;
            compCounter = compCounter + 1;
            lb1.Layout.Column = [1 2];
            lb1 = uilabel(g,'Text','UE-x(n) : Retransmission','FontColor','blue');
            lb1.Layout.Row = compCounter;
            compCounter = compCounter + 1;
            lb1.Layout.Column = [1 2];
            lb1 = uilabel(g,'Text','x : UE RNTI');
            lb1.Layout.Row = compCounter;
            compCounter = compCounter + 1;
            lb1.Layout.Column = [1 2];
            lb1 = uilabel(g,'Text', 'n : HARQ Process ID');
            lb1.Layout.Row = compCounter;
            compCounter = compCounter + 1;
            lb1.Layout.Column = [1 2];
            hAx = uiaxes(g, 'Clipping','on');

            % Create drop-down for link type
            if min(obj.NumLogs, numel(obj.PlotIds))== 2
                compCounter = compCounter + 1;
                lb1 = uilabel(g,'Text','Select Link');
                lb1.Layout.Row = compCounter;
                lb1.Layout.Column = 1;
                dd1 = uidropdown(g,'Items',{'Downlink','Uplink'}, 'ItemsData', obj.PlotIds, 'ValueChangedFcn', @(dd, event) rbSelectedLinkType(obj, dd.Value, hAx));
                dd1.Layout.Row = compCounter;
                dd1.Layout.Column = 2;
            end

            % Number of RBs to be displayed in the default view of resource grid visualization
            maxRBs = max(obj.NumRBs(obj.PlotIds));
            if obj.RGMaxRBsToDisplay <= maxRBs
                compCounter = compCounter + 1;
                obj.RGUpperRBIndex = obj.RGMaxRBsToDisplay;
                lb2 = uilabel(g,'Text','Select RB Range');
                lb2.Layout.Row = compCounter;
                lb2.Layout.Column = 1;
                [items, itemsData] = constructRBItemList(obj, obj.NumRBs(obj.RVCurrView));
                dd2 = uidropdown(g,'Items',items, 'ItemsData', itemsData, 'ValueChangedFcn', @(dd, event) rgSelectedRBRange(obj, dd.Value, hAx));
                dd2.Layout.Row = compCounter;
                dd2.Layout.Column = 2;
            else
                obj.RGUpperRBIndex = maxRBs;
            end

            % Number of slots to be displayed in the default view of resource grid visualization
            if obj.NumSlotsFrame >= obj.RGMaxSlotsToDisplay
                obj.RGUpperSlotIndex = obj.RGMaxSlotsToDisplay;
            else
                obj.RGUpperSlotIndex = obj.NumSlotsFrame;
            end

            % Construct the drop-down item list
            for idx = 1:min(obj.NumLogs, numel(obj.PlotIds))
                if obj.DuplexMode == obj.FDDDuplexMode
                    plotId = obj.PlotIds(idx);
                else
                    plotId = idx;
                end
                % Construct the drop down based on number of RBs
                if obj.RGMaxRBsToDisplay < obj.NumRBs(plotId)
                    [obj.RBItemsList{plotId}, ~] = constructRBItemList(obj, obj.NumRBs(plotId));
                end
            end

            if ~obj.IsAppVisualization
                lb5 = uilabel(g, 'Text', ['Resource Grid Allocation for Cell ID - '  num2str(obj.CellOfInterest)],  ...
                    'FontSize', 15, 'FontWeight', 'bold', 'WordWrap', 'on');
                lb5.Layout.Row = [2 3];
                lb5.Layout.Column = 5;
            end
            % Set axis properties
            hAx.Layout.Column = [3 7];
            hAx.Layout.Row = [4 14];
            drawnow;
            obj.ResourceGridTextHandles  = gobjects(obj.NumSlotsFrame, maxRBs);

            % If post simulation log analysis enabled
            if isempty(obj.IsLogReplay) || obj.IsLogReplay
                compCounter = compCounter + 1;
                % Create label for frame number
                lb3 = uilabel(g, 'Text', 'Frame Number ');
                lb3.Layout.Row = compCounter;
                lb3.Layout.Column = 1;
                obj.RGTxtHandle  = uilabel(g, 'Text', '');
                obj.RGTxtHandle.Layout.Row = compCounter;
                obj.RGTxtHandle.Layout.Column = 2;
                if obj.SchedulingType % Symbol based scheduling
                    compCounter = compCounter + 1;
                    % Create label for slot number
                    lb3 = uilabel(g, 'Text', 'Slot Number ');
                    lb3.Layout.Row = compCounter;
                    lb3.Layout.Column = 1;
                    obj.RGSlotTxtHandle = uilabel(g, 'Text', '');
                    obj.RGSlotTxtHandle.Layout.Row = compCounter;
                    obj.RGSlotTxtHandle.Layout.Column = 2;
                end
            else
                compCounter = compCounter + 1;
                lb3 = uilabel(g, 'Text', 'Total Frames: ');
                lb3.Layout.Row = compCounter;
                lb3.Layout.Column = 1;
                lb3 = uilabel(g, 'Text', num2str(obj.NumFrames));
                lb3.Layout.Row = compCounter;
                lb3.Layout.Column = 2;
                compCounter = compCounter + 1;
                lb4  = uilabel(g, 'Text','Frame number');
                lb4.Layout.Row = compCounter;
                lb4.Layout.Column = 1;
                obj.RGTxtHandle = uieditfield(g, 'numeric', 'Value' , 0, 'ValueChangedFcn', @(dd, event) showFrame(obj, dd.Value));
                obj.RGTxtHandle.Layout.Row = compCounter;
                obj.RGTxtHandle.Layout.Column = 2;
                if obj.SchedulingType % Symbol based scheduling
                    compCounter = compCounter + 1;
                    lb4  = uilabel(g, 'Text','Enter Slot number');
                    lb4.Layout.Row = compCounter;
                    lb4.Layout.Column = 1;
                    obj.RGTxtHandle = uieditfield(g, 'numeric', 'Value' , 0, 'ValueChangedFcn', @(dd, event) showSlot(obj, dd.Value));
                    obj.RGTxtHandle.Layout.Row = compCounter;
                    obj.RGTxtHandle.Layout.Column = 2;
                    obj.CurrFrame  = 0;
                    obj.CurrSlot = 0;
                end
            end

            if obj.SchedulingType
                % Initialize the symbol pattern in a slot
                for sidx =1:obj.NumSym
                    obj.SymSlotInfo{sidx} = strcat("Symbol-", num2str(sidx-1));
                end
            else
                % Initialize the slot pattern in a frame
                for sidx =1:obj.NumSlotsFrame
                    obj.SymSlotInfo{sidx} = strcat("Slot-", num2str(sidx-1));
                end
            end

            % Set resource-grid visualization axis label
            replotResourceGrid(obj, hAx, 'XAxis');
            if obj.SchedulingType
                xlabel(hAx, 'Symbols in Slot');
            else
                xlabel(hAx, 'Slots in 10 ms Frame');
            end
            replotResourceGrid(obj, hAx, 'YAxis');
            ylabel(hAx, 'Resource Blocks');
            hAx.TickDir = 'out';
            if obj.SchedulingType == obj.SlotBased && obj.RGMaxSlotsToDisplay < obj.NumSlotsFrame
                compCounter = compCounter + 1;
                % Create drop-down for Slot range
                lb2 = uilabel(g,'Text','Slot Range');
                lb2.Layout.Row = compCounter;
                lb2.Layout.Column = 1;
                [items, itemsData] = rgDropDownForSlotRange(obj);
                dd2 = uidropdown(g,'Items',items, 'ItemsData', itemsData, 'ValueChangedFcn', @(dd, event) rgSelectedSlotRange(obj, dd.Value, hAx));
                dd2.Layout.Row = compCounter;
                dd2.Layout.Column = 2;
            end
            drawnow;
        end

        function updateCQIVisualization(obj)
            %updateCQIVisualization Update the CQI map

            if isempty(obj.CurrFrame)
                return;
            end

            % Check if the figure handle is valid
            if isempty(obj.CQIVisualizationFigHandle) || ~ishghandle(obj.CQIVisualizationFigHandle)
                return;
            end

            if obj.SchedulingType == obj.SlotBased
                obj.CurrSlot = obj.NumSlotsFrame - 1;
            end

            if ~obj.IsAppVisualization
                obj.CVTxtHandle.Text = num2str(obj.CurrFrame);
            end

            % Get the CQI information
            [obj.CQIInfo{1}, obj.CQIInfo{2}] = obj.MACLogger.getCQIRBGridsInfo(obj.CurrFrame, obj.CurrSlot);
            % Make the CQI Map grid structure similar to RBG map
            obj.CQIMapHandle.ColorData = flipud(obj.CQIInfo{obj.CVCurrView}(obj.CVLowerUEIndex+1:obj.CVUpperUEIndex, obj.CVLowerRBIndex+1:obj.CVUpperRBIndex)');
            drawnow;
        end

        function updateResourceGridVisualization(obj)
            %updateResourceGridVisualization Update the resource grid visualization

            if isempty(obj.IsLogReplay) || obj.IsLogReplay == 1
                obj.RGTxtHandle.Text = num2str(obj.CurrFrame); % Update the frame number
            end
            if obj.SchedulingType % For symbol based scheduling
                lowLogIdx = 0;
                uppLogIdx = obj.NumSym;
                % Update the axis
                obj.RGVisualizationFigHandle.CurrentAxes.XTickLabel = obj.SymSlotInfo;
                if isempty(obj.IsLogReplay) || obj.IsLogReplay == 1
                    obj.RGSlotTxtHandle.Text = num2str(obj.CurrSlot); % Update the slot number
                end
            else % For slot based scheduling
                lowLogIdx = obj.RGLowerSlotIndex;
                uppLogIdx = obj.RGUpperSlotIndex;
                % Update the axis
                obj.RGVisualizationFigHandle.CurrentAxes.XTickLabel = obj.SymSlotInfo(obj.RGLowerSlotIndex+1 : obj.RGUpperSlotIndex);
            end
            for n = lowLogIdx+1 : uppLogIdx
                for p = obj.RGLowerRBIndex + 1 : obj.RGUpperRBIndex
                    obj.ResourceGridTextHandles(n, p).String = obj.ResourceGridInfo{obj.RVCurrView}(n, p);
                    if(obj.ResourceGridReTxInfo{obj.RVCurrView}(n, p) == 2) % Re-Tx
                        obj.ResourceGridTextHandles(n, p).Color = 'blue';
                    else
                        obj.ResourceGridTextHandles(n, p).Color = 'black';
                    end
                end
            end
            drawnow;
        end

        function plotPostSimRBGrids(obj, simSlotNum)
            %plotPostSimRBGrids Post simulation log visualization
            %
            % plotPostSimRBGrids(OBJ, SIMSLOTNUM) To update the resource
            % grid and CQI visualization based on the post simulation logs.
            %
            % SIMSLOTNUM - Cumulative slot number in the simulation

            % Update slot number
            if obj.SchedulingType % Symbol based scheduling
                obj.CurrSlot = mod(simSlotNum-1, obj.NumSlotsFrame);
                if obj.CurrSlot == 0
                    obj.CurrFrame = floor(simSlotNum/obj.NumSlotsFrame);
                end
            else % Slot based scheduling
                obj.CurrSlot = obj.NumSlotsFrame - 1;
                obj.CurrFrame = floor(simSlotNum/obj.NumSlotsFrame) - 1;
            end

            % Update grid information at slot boundary (for symbol based
            % scheduling) and frame boundary (for slot based scheduling)
            % Update resource grid visualization
            plotRBGrids(obj);
            % Update CQI visualization
            plotCQIRBGrids(obj);
        end
        function showFrame(obj, frameNumber)
            %showFrame Handle the event when user enters a
            % number to visualize a particular frame number in the
            % simulation

            % Update the resource grid and CQI grid visualization
            if frameNumber >= obj.NumFrames || frameNumber < 0
                msg = strcat("Frame number must be in between 0 and ", num2str(obj.NumFrames - 1));
                warndlg(msg,'Warning');
                return;
            end
            obj.CurrFrame = frameNumber;
            if obj.EnableCQIGridVisualization
                updateCQIVisualization(obj);
            end
            if obj.EnableResourceGridVisualization
                plotRBGrids(obj);
            end
        end

        function showSlot(obj, slotNumber)
            %showFrame Handle the event when user enters a
            % number to visualize a particular slot number in the
            % simulation

            if slotNumber >= obj.NumSlotsFrame || slotNumber < 0
                msg = strcat("Slot number must be in between 0 and ", num2str(obj.NumSlotsFrame - 1));
                warndlg(msg,'Warning');
                return;
            end
            obj.CurrSlot = slotNumber;
            % Update the resource grid and CQI grid visualization
            if obj.EnableResourceGridVisualization
                plotRBGrids(obj);
            end
        end
    end

    methods( Access = private)
        function [itemList, itemData] = constructRBItemList(obj, numRBs)
            %constructRBItemList Create the items for the drop-down component

            % Create the items for the drop-down component
            numItems = floor(numRBs / obj.RGMaxRBsToDisplay);
            itemList = cell(numItems, 1);
            itemData = zeros(ceil(numRBs / obj.RGMaxRBsToDisplay), 1);
            for i = 1 : numItems
                itemData(i) = (i - 1) * obj.RGMaxRBsToDisplay;
                itemList{i} = ['RB ', num2str(itemData(i)) '-' num2str(itemData(i) + obj.RGMaxRBsToDisplay - 1)];
            end
            if (mod(numRBs,obj.RGMaxRBsToDisplay) > 0)
                itemData(i+1) = i * obj.RGMaxRBsToDisplay;
                itemList{i+1} = ['RB ', num2str(itemData(i+1)) '-' num2str(numRBs - 1)];
            end
        end

        function [itemList, itemData] = rgDropDownForSlotRange(obj)
            %rgDropDownForSlotRange Construct drop-down component for selecting slot range

            % Create the items for the drop-down component
            numItems = floor(obj.NumSlotsFrame / obj.RGMaxSlotsToDisplay);
            itemData = zeros(ceil(obj.NumSlotsFrame / obj.RGMaxSlotsToDisplay), 1);
            itemList = cell(numItems, 1);
            for i = 1 : numItems
                itemData(i) = (i-1) * obj.RGMaxSlotsToDisplay ;
                itemList{i} = ['Slot ', num2str(itemData(i)) '-' num2str(itemData(i) + obj.RGMaxSlotsToDisplay - 1)];
            end
            if (mod(obj.NumSlotsFrame, obj.RGMaxSlotsToDisplay) > 0)
                itemData(i+1) = i * obj.RGMaxSlotsToDisplay + 1;
                itemList{i+1} = ['Slot ', num2str(itemData(i+1) - 1) '-' num2str(obj.NumSlotsFrame - 1)];
            end
        end

        function [itemList, itemData] = cvDropDownForUERange(obj)
            %cvDropDownForUERange Construct drop-down component for selecting UEs

            % Create the items for the drop-down component
            numItems = floor(obj.NumUEs / obj.CVMaxUEsToDisplay);
            itemData = zeros(ceil(obj.NumUEs / obj.CVMaxUEsToDisplay), 1);
            itemList = cell(numItems, 1);
            for i = 1 : numItems
                itemData(i) = (i - 1) * obj.CVMaxUEsToDisplay;
                itemList{i} = ['UE ', num2str(itemData(i) + 1) '-' num2str(itemData(i) + obj.CVMaxUEsToDisplay)];
            end
            if (mod(obj.NumUEs,obj.CVMaxUEsToDisplay) > 0)
                itemData(i+1) = i * obj.CVMaxUEsToDisplay;
                itemList{i+1} = ['UE ', num2str(itemData(i+1)+1) '-' num2str(itemData(i+1) + mod(obj.NumUEs, obj.CVMaxUEsToDisplay))];
            end
        end

        function rgSelectedRBRange(obj, lowerRBIndex, hAx)
            %rgSelectedRBRange Handle the event when user selects RB range in resource grid visualization

            obj.RGLowerRBIndex = lowerRBIndex;
            obj.RGUpperRBIndex = obj.RGLowerRBIndex + obj.RGMaxRBsToDisplay;
            if obj.RGUpperRBIndex > obj.NumRBs(obj.RVCurrView)
                obj.RGUpperRBIndex = obj.NumRBs(obj.RVCurrView);
            end
            % Update the Y-Axis of the resource grid visualization with
            % selected RB range
            replotResourceGrid(obj, hAx, 'YAxis');
        end

        function rgSelectedSlotRange(obj, lowerSlotIndex, hAx)
            %rgSelectedSlotRange Handle the event when user selects slot range in resource grid visualization

            obj.RGLowerSlotIndex = lowerSlotIndex;
            obj.RGUpperSlotIndex = obj.RGLowerSlotIndex + obj.RGMaxSlotsToDisplay;
            if obj.RGUpperSlotIndex > obj.NumSlotsFrame
                obj.RGUpperSlotIndex = obj.NumSlotsFrame;
            end
            % Update the X-Axis of the resource grid visualization with
            % selected slot range
            replotResourceGrid(obj, hAx, 'XAxis');
        end

        function rbSelectedLinkType(obj, plotIdx, hAx)
            %rbSelectedLinkType Handle the event when user selects link type in resource grid visualization

            % Update the resource grid visualization with selected link type
            if numel(obj.PlotIds) == 2
                obj.RVCurrView = plotIdx;
            end
            replotResourceGrid(obj, hAx, 'YAxis');
            drawnow;
        end

        function replotResourceGrid(obj, hAx, coordinate)
            %replotResourceGrid Update the resource grid along X-axis or Y-axis w.r.t to the given input parameters.

            cla(hAx);
            numRBsToDisplay = obj.RGUpperRBIndex - obj.RGLowerRBIndex;
            if obj.SchedulingType % For symbol based scheduling
                lowLogIdx = 0;
                numUnitsToDisplay = obj.NumSym; % Display information of 14 symbols in a slot
            else % For slot based scheduling
                lowLogIdx = obj.RGLowerSlotIndex;
                numUnitsToDisplay = obj.RGUpperSlotIndex - obj.RGLowerSlotIndex;
            end
            [X1, Y1] = meshgrid(0:numUnitsToDisplay, 0 : numRBsToDisplay);
            [X2, Y2] = meshgrid(0:numRBsToDisplay, 0 : numUnitsToDisplay);
            x = linspace(1, numUnitsToDisplay, numUnitsToDisplay);
            y = linspace(1, numRBsToDisplay, numRBsToDisplay);
            for n=1:numUnitsToDisplay
                i = lowLogIdx + n;
                for p = 1 : numRBsToDisplay
                    j = obj.RGLowerRBIndex + p;
                    obj.ResourceGridTextHandles(i, j) = text(hAx, x(n) - .5, y(p) - .5, ' ', 'HorizontalAlignment', 'center', 'Clipping', 'on');
                end
            end
            hold(hAx, 'on');
            plot(hAx, X1, Y1, 'k', 'Color', 'black', 'LineWidth', 0.1);
            plot(hAx, Y2, X2, 'k', 'Color', 'black', 'LineWidth', 0.1);
            if strcmpi('XAxis', coordinate) == 1
                % Updates X-Axis
                xticks(hAx, (1 : numUnitsToDisplay) - 0.5);
                if obj.SchedulingType % Symbol based scheduling
                    xticklabels(hAx, obj.SymSlotInfo);
                else
                    xticklabels(hAx, obj.SymSlotInfo(obj.RGLowerSlotIndex+1 : obj.RGUpperSlotIndex));
                end
            else
                % Updates Y-Axis
                yticks(hAx, (1 : numRBsToDisplay) - 0.5);
                yTicksLabel = cell(1, 0);
                for i = 1 : numRBsToDisplay
                    yTicksLabel{i} = strcat('    RB- ', num2str(obj.RGLowerRBIndex + i - 1));
                end
                yticklabels(hAx, yTicksLabel);
            end

            % Update the resource grid visualization
            updateResourceGridVisualization(obj);
        end

        function cbSelectedRBRange(obj, lowerRBIndex)
            %cbSelectedRBRange Handle the event when user selects RB range in CQI grid visualization

            obj.CVLowerRBIndex = lowerRBIndex;
            obj.CVUpperRBIndex = obj.CVLowerRBIndex + obj.CVMaxRBsToDisplay;
            if obj.CVUpperRBIndex > obj.NumRBs(obj.CVCurrView)
                obj.CVUpperRBIndex = obj.NumRBs(obj.CVCurrView);
            end
            % Update the Y-Axis limits of the CQI grid visualization with
            % selected RB range
            updateCQIMapProperties(obj);
        end

        function cbSelectedUERange(obj, lowerUEIndex)
            %cbSelectedUERange Handle the event when user selects UE range in CQI grid visualization

            obj.CVLowerUEIndex = lowerUEIndex;
            obj.CVUpperUEIndex = obj.CVLowerUEIndex + obj.CVMaxUEsToDisplay;
            if obj.CVUpperUEIndex  > obj.NumUEs
                obj.CVUpperUEIndex = obj.NumUEs;
            end
            % Update the X-Axis limits of the CQI grid visualization with
            % selected UE range
            updateCQIMapProperties(obj)
        end

        function cbSelectedLinkType(obj, plotIdx)
            %cbSelectedLinkType Handle the event when user selects link type in CQI grid visualization

            % Update the CQI grid visualization with selected link type
            if numel(obj.PlotIds) == 2
                obj.CVCurrView = plotIdx;
            end
            % Update the Y-Axis limits of the CQI grid visualization with
            % selected RB range
            updateCQIMapProperties(obj);
        end

        function updateCQIMapProperties(obj)
            %updateCQIMapProperties Update the CQI grid along X-axis or Y-axis w.r.t to the given input parameters

            numRBsToDisplay = obj.CVUpperRBIndex - obj.CVLowerRBIndex;
            numUEsToDisplay = obj.CVUpperUEIndex - obj.CVLowerUEIndex;
            obj.CQIMapHandle.ColorData = zeros(numRBsToDisplay, numUEsToDisplay);
            % Update X-Axis
            xTicksLabel = cell(numUEsToDisplay, 0);
            for i = 1  : numUEsToDisplay
                xTicksLabel{i} = strcat('UE- ', num2str(obj.CVLowerUEIndex + i ));
            end
            obj.CQIMapHandle.XDisplayLabels = xTicksLabel;

            % Update Y-Axis
            yTicksLabel = cell(numRBsToDisplay, 0);
            for i = 1 : numRBsToDisplay
                yTicksLabel{i} = strcat('    RB- ', num2str(obj.CVLowerRBIndex + i - 1));
            end
            obj.CQIMapHandle.YDisplayLabels = flip(yTicksLabel);
            updateCQIVisualization(obj);
        end

        function setupGUI(obj, simParameters)
            %setupGUI Create the visualization for cell of interest

            % Validate the RB visualization flag
            if isfield(simParameters, 'rbVisualization')
                if islogical(simParameters.rbVisualization)
                    % To support true/false
                    validateattributes(simParameters.rbVisualization, {'logical'}, {'nonempty', 'scalar'}, 'simParameters.rbVisualization', 'rbVisualization');
                else
                    % To support 0/1
                    validateattributes(simParameters.rbVisualization, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 0, '<=', 1}, 'simParameters.rbVisualization', 'rbVisualization');
                end
                obj.EnableResourceGridVisualization = simParameters.rbVisualization;
            end

            % Validate the CQI visualization
            if isfield(simParameters, 'cqiVisualization')
                if islogical(simParameters.cqiVisualization)
                    % To support true/false
                    validateattributes(simParameters.cqiVisualization, {'logical'}, {'nonempty', 'scalar'}, 'simParameters.CQIVisualization', 'CQIVisualization');
                else
                    % To support 0/1
                    validateattributes(simParameters.cqiVisualization, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 0, '<=', 1}, 'simParameters.cqiVisualization', 'cqiVisualization');
                end
                obj.EnableCQIGridVisualization = simParameters.cqiVisualization;
            end

            % Using the screen width and height, calculate the figure width
            % and height
            resolution = get(0, 'ScreenSize');
            screenWidth = resolution(3);
            screenHeight = resolution(4);
            figureWidth = screenWidth * 0.90;
            figureHeight = screenHeight * 0.85;

            if(obj.EnableCQIGridVisualization) % Create CQI visualization
                obj.CQIVisualizationFigHandle = uifigure('Name', 'Channel Quality Visualization', 'Position', [screenWidth * 0.05 screenHeight * 0.05 figureWidth figureHeight], 'HandleVisibility', 'on');
                constructCQIGridVisualization(obj);
                if ~isempty(obj.MACLogger)
                    addDepEvent(obj.MACLogger, @obj.plotCQIRBGrids, obj.NumSlotsFrame); % Invoke for every frame
                end
            end

            if(obj.EnableResourceGridVisualization) % Create resource grid visualization
                obj.RGVisualizationFigHandle = uifigure('Name', 'Resource Grid Allocation', 'Position', [screenWidth * 0.05 screenHeight * 0.05 figureWidth figureHeight], 'HandleVisibility', 'on');
                constructResourceGridVisualization(obj);
                if ~isempty(obj.MACLogger)
                    if obj.SchedulingType == obj.SymbolBased
                        addDepEvent(obj.MACLogger, @obj.plotRBGrids, 1); % Invoke for every slot
                    else
                        addDepEvent(obj.MACLogger, @obj.plotRBGrids, obj.NumSlotsFrame); % Invoke for every frame
                    end
                end
            end
        end
    end
end