function rmse = least_square_a(position, results, K)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
    realpos = position';
    SenRes = results;
    gNB1 = K(1);
    gNB2 = K(2);

    X = zeros(3,9);
    rmse = zeros(1,9);

    fus = @(r, a, b)[cos(a/180*pi)*cos(b/180*pi),-r*sin(a/180*pi)*cos(b/180*pi),-r*sin(b/180*pi)*cos(a/180*pi);...
        cos(a/180*pi)*sin(b/180*pi),-r*sin(a/180*pi)*sin(b/180*pi),r*cos(a/180*pi)*cos(b/180*pi);...
        sin(a/180*pi),r*cos(a/180*pi),0];

    for ii = 1:size(SenRes{1}{1}.rngEst,2)
        A1 = fus(SenRes{gNB1}{1}.rngEst(ii),SenRes{gNB1}{1}.eleEst(ii),SenRes{gNB1}{1}.aziEst(ii));
        A2 = fus(SenRes{gNB2}{1}.rngEst(ii),SenRes{gNB2}{1}.eleEst(ii),SenRes{gNB2}{1}.aziEst(ii));

        x  = [SenRes{gNB1}{1}.sensingEst(ii,:),SenRes{gNB2}{1}.sensingEst(ii,:)]';

        B11 = [mean(SenRes{gNB1}{1}.rangeRMSE),0,0;0,mean(SenRes{gNB1}{1}.eleRMSE)*0.001,0;0,0,mean(SenRes{gNB1}{1}.aziRMSE)*0.001];
        B22 = [mean(SenRes{gNB2}{1}.rangeRMSE),0,0;0,mean(SenRes{gNB2}{1}.eleRMSE)*0.001,0;0,0,mean(SenRes{gNB2}{1}.aziRMSE)*0.001];
    %     B11 = [var(SenRes{1}{1}.rangeRMSE),0,0;0,var(SenRes{1}{1}.eleRMSE),0;0,0,var(SenRes{1}{1}.aziRMSE)];
    %     B22 = [var(SenRes{2}{1}.rangeRMSE),0,0;0,var(SenRes{2}{1}.eleRMSE),0;0,0,var(SenRes{2}{1}.aziRMSE)];
        B12 = zeros(3);
        B21 = zeros(3);

        H = [eye(3);eye(3)];
        R = [A1*B11*A1',A1*B12*A2';A2*B21*A1',A2*B22*A2'];
        X(:,ii) = inv(H'*inv(R)*H)*H'*inv(R)*x;
        
        rmse(ii) = sqrt((realpos(1,ii)-X(1,ii))^2 + (realpos(2,ii)-X(2,ii))^2 + (realpos(3,ii)-X(3,ii))^2);
    end

end

