function prb = determinePRB(fc, bandwidth, scs)
%Determine Physical RB Numbers.

% Author: D.S.Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

    %% TS 38.101 Table 5.3.2-1 & Table 5.3.2-2

    bandwidth = bandwidth./1e6; % Convert to MHz

    if (fc <= 6.00e9) && (fc > .450e6)        % sub-6G/FR1 band, from 450MHz to 6GHz
        freq = 'FR1';
    elseif (fc <= 52.00e9) && (fc >= 24.00e9) % mmWave/FR2 band, from 24GHz to 52GHz
        freq = 'FR2';
    else
        error('Carrier frequency does not fit 5G NR standards')
    end

    persistent prb_table_FR1 prb_table_FR2

    if isempty(prb_table_FR1)
        prb_table_FR1        = containers.Map('KeyType','char','ValueType','any');
        prb_table_FR1('5')   = containers.Map({'15','30'},[25,11]);
        prb_table_FR1('10')  = containers.Map({'15','30','60'},[52,24,11]);
        prb_table_FR1('15')  = containers.Map({'15','30','60'},[79,38,18]);
        prb_table_FR1('20')  = containers.Map({'15','30','60'},[106,51,24]);
        prb_table_FR1('25')  = containers.Map({'15','30','60'},[133,65,31]);
        prb_table_FR1('30')  = containers.Map({'15','30','60'},[160,78,38]);
        prb_table_FR1('40')  = containers.Map({'15','30','60'},[216,106,51]);
        prb_table_FR1('50')  = containers.Map({'15','30','60'},[270,133,65]);
        prb_table_FR1('60')  = containers.Map({'30','60'},[162,79]);
        prb_table_FR1('70')  = containers.Map({'30','60'},[189,93]);
        prb_table_FR1('80')  = containers.Map({'30','60'},[217,107]);
        prb_table_FR1('90')  = containers.Map({'30','60'},[245,121]);
        prb_table_FR1('100') = containers.Map({'30','60'},[273,135]);
    
        prb_table_FR2        = containers.Map('KeyType','char','ValueType','any');
        prb_table_FR2('50')  = containers.Map({'60','120'},[66,32]);
        prb_table_FR2('100') = containers.Map({'60','120'},[132,66]);
        prb_table_FR2('200') = containers.Map({'60','120'},[264,132]);
        prb_table_FR2('400') = containers.Map({'120'},264);
    end

    if ~isKey(prb_table_FR1,num2str(bandwidth)) && ~isKey(prb_table_FR2,num2str(bandwidth))
        error('The input bandwidth is out of range for this function')
    end

    if strcmp(freq, 'FR1') && scs == 60 && bandwidth == 5
        error('60KHz SCS is not supported in 5MHz bandwidth')
    elseif strcmp(freq, 'FR2') && scs == 60 && bandwidth == 400
        error('60KHz SCS is not supported in 400MHz bandwidth')
    end

    if strcmp(freq, 'FR1') && isKey(prb_table_FR1, num2str(bandwidth))
        prbs = prb_table_FR1(num2str(bandwidth));
        if isKey(prbs,num2str(scs))
            prb = prbs(num2str(scs));
        else
            error(['The input subcarrier spacing ' num2str(scs) ' is not supported'])
        end
    elseif strcmp(freq, 'FR2') && isKey(prb_table_FR2, num2str(bandwidth))
        prbs = prb_table_FR2(num2str(bandwidth));
        if isKey(prbs,num2str(scs))
            prb = prbs(num2str(scs));
        else
            error(['The input subcarrier spacing ' num2str(scs) ' is not supported'])
        end
    else
        error(['The input bandwidth ' num2str(bandwidth) ' is not supported'])
    end

end
