function targetslist = setMovement(Parameters, targetslist, time)
    
    switch Parameters.userMovement.type
        case parameters.setting.UserMovementType.RandConstDirection
            ntarget = length(targetslist);
            direction = 2*pi*(rand(ntarget,1)-.5);
            direction = [sin(direction), cos(direction), zeros(ntarget,1)];
            speed = Parameters.velocity;
            t = reshape(reshape(0:time-1,10,[]),1,1,time);
            offset = repmat(direction .* speed,1,1,time) .* repmat(t,ntarget,3,1);
            for i = 1:ntarget
                targetslist{i} = targetslist{i}(:,1)+squeeze(offset(i,:,:));
            end

        case parameters.setting.UserMovementType.ConstPosition
            ntarget = length(targetslist);
            for uu = 1:ntarget
                % set position
                targetslist{uu} = repmat(targetslist{uu}(:,1), ...
                    1, time);
            end

        case parameters.setting.UserMovementType.Predefined
            % set positions
            for i = 1:length(targetslist)
                % set target position list to predefined positions
                targetslist{i} = Parameters.userMovement.positionList(:,:,i);
            end % for all targets

        otherwise
            warning('No user movment function specified!');
    end % switch for movement model
end

