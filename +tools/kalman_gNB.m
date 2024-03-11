function [RMSE, x, y, z] = kalman_gNB(position,results,k,n)
%KALMAN_GNB 此处显示有关此函数的摘要
%   此处显示详细说明
    o = zeros(5,3);
    Z = zeros(5,3);
    G_K = zeros(5,3);
    gNB = k;
    SenRes = results;

    for i = 1:size(SenRes)
        o(i,:) = var(abs(SenRes{i}{1}.sensingEst-position) ,1);
        Z(i,:) = SenRes{i}{1}.sensingEst(n,:);
    end

    X_hat = [SenRes{1}{1}.sensingEst(n,1),0,0,0,0];
    Y_hat = [SenRes{1}{1}.sensingEst(n,2),0,0,0,0];
    Z_hat = [SenRes{1}{1}.sensingEst(n,3),0,0,0,0];
    
    for k = 2:gNB
        G_K(k,1) = o(k-1,1)/(o(k-1,1)+o(k,1));
        G_K(k,2) = o(k-1,2)/(o(k-1,2)+o(k,2));
        G_K(k,3) = o(k-1,3)/(o(k-1,3)+o(k,3));
    
        X_hat(k) = X_hat(k-1)+G_K(k,1)*(Z(k,1)-X_hat(k-1));
        Y_hat(k) = Y_hat(k-1)+G_K(k,2)*(Z(k,2)-Y_hat(k-1));
        Z_hat(k) = Z_hat(k-1)+G_K(k,3)*(Z(k,3)-Z_hat(k-1));
    
        o(k,1) = (1-G_K(k,1))*o(k-1,1);
        o(k,2) = (1-G_K(k,2))*o(k-1,2);
        o(k,3) = (1-G_K(k,3))*o(k-1,3);
    end
    RMSE = sqrt((position(n,1) - X_hat(gNB))^2 + (position(n,2) - Y_hat(gNB))^2 + (position(n,3) - Z_hat(gNB))^2);
    x = X_hat(gNB);
    y = Y_hat(gNB);
    z = Z_hat(gNB);
end

