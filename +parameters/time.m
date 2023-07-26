classdef time < tools.HiddenHandle
    % TIME parameters needed to define the timeline
    % 

    properties (Access = public)
        % number of 10 ms radio frames in the simulation
        % [1x1]integer
        numFrames
    end

    properties (Dependent = true)
        % number of slots in the simulation
        % [1x1]integer
        numSlots
    end

    methods
        function obj = time()
            %TIME creates time class
        end

        function set.numSlots(obj, numSlotsFrame)
            %SETNUMSLOTS compute number of slots in total simulation frames
            obj.numSlots = obj.numFrames * numSlotsFrame;
        end
    end
end

