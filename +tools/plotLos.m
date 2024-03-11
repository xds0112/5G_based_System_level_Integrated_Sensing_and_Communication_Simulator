function [ueLoSConditions, targetLoSConditions] = plotLos(simuLayout, bsPosition, ueParams ,targetParams)
% Check and plot the LoS conditions between antennas
% on the gNB and UEs within each cell

    % gNBs and UEs topology parameters
    gNBPos     = bsPosition;
    uePos      = ueParams;
    numBS      = size(bsPosition,1);
    numUEs     = ueParams{1}.numUEs;
    numTargets = length(targetParams);
    figure(1)

    ueLoSConditions = zeros(numUEs,size(gNBPos,1));
    for ii = 1:size(gNBPos,1)
        % Plot the layout, gNB/antennas, UEs and targets
        gNBPlot = tools.plotScatter3D(gNBPos(ii,:), 20, tools.colors.darkRed); % dark red
    
        % LoS conditions corresponding with UEs, 
        % [numUEs x 1] row vector
        for i = 1:numUEs
            ueP = uePos{ii}.position(i,:);
            uePlot = tools.plotScatter3D(ueP, 10, tools.colors.darkBlue); % dark blue
            % Update the LoS condition for each UE
            ueLoSConditions(i,ii) = simuLayout.checkLoS(ueP, gNBPos(ii,:));
            % Draw the LoS link
            hold on
            if ueLoSConditions(i,ii)
                losLink = tools.drawLine3D(gNBPos(ii,:), ueP, tools.colors.lightRed);
            end
            hold off
        end
    end
    % LoS conditions corresponding with targets
    targetLoSConditions = cell(numBS,numTargets);
    for n = 1:numBS
        for uu = 1:numTargets
            targetPos  = targetParams{uu}';
            targetLoSConditions{n, uu} = zeros(size(targetPos,1),1);
            for t = 1:size(targetPos,1)
                targetPlot = tools.plotScatter3D(targetPos(t,:), 10, tools.colors.darkGreen); % dark green
        
                % Update the LoS condition for each target
                targetLoSConditions{n,uu}(t) = simuLayout.checkLoS(targetPos(t,:), gNBPos(n,:));
                %targetLoSConditions{n,uu}(t) = 1;
                % Draw the LoS link
                hold on
                if targetLoSConditions{n,uu}(t)
                    losLink = tools.drawLine3D(gNBPos(n,:), targetPos(t,:), tools.colors.lightRed);
                end
                hold off
            end
        end
    end
%     % Check if there is a LoS link
%     if any(ueLoSConditions) || any(targetLoSConditions)
    legend([gNBPlot uePlot targetPlot losLink], {'gNB' 'UEs' 'Targets' 'LoS link'})
%     else % LoS path doesn't exist in both gNB-UEs links and gNB-targets links
%         legend([gNBPlot uePlot targetPlot], {'gNB' 'UEs' 'Targets'})
%         disp('Note that no LoS path exists in the simulation scenario')
%     end
end

