function printCopyright
%PRINTCOPYRIGHT
%   print copyright for the simulator

    currentTime = datetime('now');

    fprintf('5G-based System-level Integrated Sensing and Communication Simulator\n')
    fprintf('\n')
    fprintf('Copyright (C) 2023 Beijing University of Posts and Telecommunications\n')
    fprintf('All rights reserved.\n')
    fprintf('\n')
    fprintf('Authors: Dongsheng Xue, et.al\n')
    fprintf('Key Laboratory of Universal Wireless Communications, Ministry of Education\n')
    fprintf('Date: %s\n', char(currentTime))
    fprintf('\n')

end

