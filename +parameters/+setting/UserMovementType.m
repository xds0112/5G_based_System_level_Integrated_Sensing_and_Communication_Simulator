classdef UserMovementType < uint32
    %MOVEMENTTYPE types of user movements
    % This is the enum of all possible user movement models. According to
    % the movement model the user positions per slot are generated.
    %
    % initial author: Thomas Dittrich
    %
    % see also +networkGeometry

    enumeration
        % random direction, constant speed
        RandConstDirection (1)

        % constant position - users do not move
        ConstPosition (2)

        % predefined user trace
        % The user positions set in the scenario file for each slot are
        % used.
        Predefined (3)
    end
end

