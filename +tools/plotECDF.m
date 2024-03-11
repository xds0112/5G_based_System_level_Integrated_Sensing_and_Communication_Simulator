function pltHandle = plotECDF(inputData, lineWidth)
%PLOTECDF plot customized empirical cumulative distribution function (ECDF)
% input:
% inputData: statistical data
% lineWideth: desired ECDF linewidth, [1x1] integer
%
% output:
% pltHandle: plot handle

    [dataCumProbabilities, dataValues] = ecdf(inputData);
    pltHandle = stairs(dataValues, dataCumProbabilities, 'Linewidth', lineWidth);

end

