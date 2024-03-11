function simuLayout = generateScenario1(roi, cityParams)
    % Generate scenario
    % Invoke the constructor to create the simulation scenario
    simuLayout = networkTopology.blockages.openStreetMapCity(cityParams, roi);

    % Plot the layout and network nodes
    figure(1)
    title('Simulation Scenario')
    
    % Plot the layout
    simuLayout.plot(tools.colors.darkGrey) % light grey

    grid on

    xlim([roi.xMin roi.xMax])
    ylim([roi.yMin roi.yMax])
    xlabel('x axis (m)')
    ylabel('y axis (m)')
    zlabel('z axis (m)')

end

