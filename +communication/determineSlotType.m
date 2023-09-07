function slotType = determineSlotType(tddPattern, slotIdx)
%DETERMINESLOTTYPE 
%   
    % Determine the current slot type
    % symbols
    slotType = tddPattern(mod(slotIdx, numel(tddPattern)) + 1);

end

