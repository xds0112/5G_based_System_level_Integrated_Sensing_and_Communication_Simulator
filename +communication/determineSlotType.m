function [slotType, nSymbolsDL] = determineSlotType(tddPattern, specialSlot, slotIdx)
%DETERMINESLOTTYPE 
%   
    % Determine the current slot type and the number of downlink OFDM
    % symbols
    slotType = tddPattern(mod(slotIdx, numel(tddPattern)) + 1);

    if (slotType == 'D')
        nSymbolsDL = 14; % Assume normal CP
    elseif (slotType == 'S')
        nSymbolsDL = specialSlot(1);
    else % slotType=="U"
        nSymbolsDL = 0;
    end
end

