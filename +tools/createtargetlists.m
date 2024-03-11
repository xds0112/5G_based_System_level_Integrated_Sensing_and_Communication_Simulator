function targetsposition = createtargetlists(targetParams, time)
    n = numel(targetParams);
    targetsposition = [];
    for uu = 1:n
        targetParameter = targetParams(uu);
        targetslist = cell(1, targetParameter.numTargets);
        % this automatically uses the function predifined in the
        % userParams class to generate the desired user type
        ntarget = size(targetParameter.position, 1);
        for i = 1:ntarget
            targetslist{i} = zeros(3,time);
            targetslist{i}(:, 1) = [targetParameter.position(i, 1); targetParameter.position(i, 2); targetParameter.position(i, 3)];
        end
        targetslist = tools.setMovement(targetParameter, targetslist, time);

        % add targets to user targetslist
        targetsposition = [targetsposition, targetslist];

    end % for all different targets types
end

