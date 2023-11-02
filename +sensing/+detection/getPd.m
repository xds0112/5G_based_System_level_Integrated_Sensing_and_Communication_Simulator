function Pd = getPd(Pfa,snrdB,nPulses)
% Calculate detection probability

% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

%%
    % Dectection probablity
    maxSNR  = snrdB(end);
    minSNR  = snrdB(1);
    nPoints = length(snrdB);
    [Pd,~]  = rocpfa(Pfa,'MaxSNR',maxSNR,'MinSNR',minSNR,'NumPoints',nPoints,'NumPulses',nPulses);

    % plot Pd
    figure('Name','Detection Probablity')
    plot(snrdB,Pd,'-')
    grid on
    ylabel('Detection Probability')
    xlabel('SNR(dB)')
    legend(strcat('Pfa: ',num2str(Pfa(:))))

end

