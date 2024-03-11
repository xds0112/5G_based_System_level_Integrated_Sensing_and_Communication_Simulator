function plotComMetricsECDF(results)
%PLOTCOMMETRICSECDF plot downlink throughput ECDF
    numCells = numel(results);
    for n = 1:numCells
        cellstr = ['cell-' num2str(n)];
        figure('Name', 'ECDF of DL Throughput')
        dlThroughputDataRate = results{n}.ueDLThroughput;
        dlTp = tools.plotECDF(dlThroughputDataRate, 1);
        legend(dlTp, ['Downlink throughput of ' cellstr])
        grid on
        title('ECDF of Downlink Throughput')
        xlabel('Data Rate (Mbps)')
        ylabel('Cumulative Probability')
    end
end

