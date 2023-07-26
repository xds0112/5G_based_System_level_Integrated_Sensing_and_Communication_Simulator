classdef roundRobin < communication.scheduling.schedulerEntity
    %roundRobin Implements round-robin scheduler

    %   Copyright 2020 The MathWorks, Inc.

    methods
        function obj = roundRobin(simParameters)
            %roundRobin Construct an instance of this class

            % Invoke the super class constructor to initialize the properties
            obj = obj@communication.scheduling.schedulerEntity(simParameters);
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

            %   Copyright 2019 The MathWorks, Inc.

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
end
