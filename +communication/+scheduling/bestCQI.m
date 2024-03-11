classdef bestCQI < communication.scheduling.schedulerEntity
    %bestCQI Implements best CQI scheduler

    %   Copyright 2020 The MathWorks, Inc.

    methods
        function obj = bestCQI(simParameters)
            %bestCQI Construct an instance of this class

            % Invoke the super class constructor to initialize the properties
            obj = obj@communication.scheduling.schedulerEntity(simParameters);
        end

        function [selectedUE, mcsIndex] = runSchedulingStrategy(~, schedulerInput)
            %runSchedulingStrategy Implements the best CQI scheduling
            %
            %   [SELECTEDUE, MCSINDEX] = runSchedulingStrategy(~, SCHEDULERINPUT)
            %   runs the best cqi algorithm and returns the UE (among the eligible ones)
            %   which wins this particular resource block group (RBG), along with the
            %   suitable MCS index based on the channel conditions. This function gets
            %   called for selecting a UE for each RBG to be used for new transmission
            %   i.e. once for each of the remaining RBGs after assignment for
            %   retransmissions is completed. All the eligible UEs are evaluated and
            %   the one with maximum value of CQI for this RBG gets it.
            %
            %   SCHEDULERINPUT structure contains the following fields which scheduler
            %   would use (not necessarily all the information) for selecting the UE to
            %   which RBG would be assigned.
            %
            %       eligibleUEs    - RNTI of the eligible UEs contending for the RBG
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
            mcsIndex = -1;
            bestAvgCQI = 0;
            for i = 1:length(schedulerInput.eligibleUEs)
                bufferStatus = schedulerInput.bufferStatus(i);
                if(bufferStatus > 0) % Check if UE has any data pending
                    % Get CQI values for the RBs of the resource block
                    % group and calculate average CQI for the whole RBG.
                    % MCS is selected according to average CQI of the RBs
                    % of RBG
                    cqiRBG = schedulerInput.cqiRBG(i, :);
                    cqiAvg = floor(mean(cqiRBG));
                    if(cqiAvg > bestAvgCQI)
                        % Update the best CQI value till now.
                        bestAvgCQI = cqiAvg;
                        selectedUE = schedulerInput.eligibleUEs(i);
                        mcsIndex = schedulerInput.mcsRBG(i, 1);
                    end
                end
            end
        end
    end
end