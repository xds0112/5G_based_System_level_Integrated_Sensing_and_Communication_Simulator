% Plot RMSE of different reference signals and synchronization signals.
% Including DMRS,PTRS,PRS,CSI-RS,PSS,SSS.

% Author: D.S Xue, Key Laboratory of Universal Wireless Communications,
% Ministry of Education, BUPT.

%%
% clc; clear; close all

%%
load  D:\!workBUPT\!Codes_MATLAB\5G_based_ISAC_systemlevel\+tools\dmrsAdd0.mat
% load dmrsAdd2.mat
% load dmrsAdd1.mat
% load dmrsAdd0.mat

% dmrs3RngRMSE = extractfield(radarEstRMSE_dmrs3,'rRMSE');
% dmrs3VelRMSE = extractfield(radarEstRMSE_dmrs3,'vRMSE');
% dmrs2RngRMSE = extractfield(radarEstRMSE_dmrs2,'rRMSE');
% dmrs2VelRMSE = extractfield(radarEstRMSE_dmrs2,'vRMSE');
% dmrs1RngRMSE = extractfield(radarEstRMSE_dmrs1,'rRMSE');
% dmrs1VelRMSE = extractfield(radarEstRMSE_dmrs1,'vRMSE');
dmrs0RngRMSE = extractfield(dmrsAdd0,'rRMSE');
dmrs0VelRMSE = extractfield(dmrsAdd0,'vRMSE');

%% 
%
figure(1)
ecdf(dmrs0RngRMSE)
% hold on
% ecdf(dmrs1RngRMSE)
% hold on
% ecdf(dmrs2RngRMSE)
% hold on
% ecdf(dmrs3RngRMSE)

grid on
xlabel('RMSE (m)')
ylabel('Percentage')
title('ECDF of Range Estimation RMSE')
% legend('Default DMRS','DMRS Addtional 1','DMRS Addtional 2','DMRS Addtional 3','location','northwest')

%
figure(2)
ecdf(dmrs0VelRMSE)
% hold on
% ecdf(dmrs1VelRMSE)
% hold on
% ecdf(dmrs2VelRMSE)
% hold on
% ecdf(dmrs3VelRMSE)

grid on
xlabel('RMSE (m/s)')
ylabel('Percentage')
title('ECDF of Velocity Estimation RMSE')
% legend('Default DMRS','DMRS Addtional 1','DMRS Addtional 2','DMRS Addtional 3','location','northeast')

