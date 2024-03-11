function slotType = determineSlotType(tddPattern, slotIdx)
%DETERMINESLOTTYPE 
%   
    % Determine the current slot type
    slotType = tddPattern(mod(slotIdx, numel(tddPattern)) + 1);

end

