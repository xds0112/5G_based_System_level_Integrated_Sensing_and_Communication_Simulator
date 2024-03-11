function plthandle = plotScatter3D(position, size, color)
% plot 3D scatter of an object
% input: position, (x,y,z) coordinates
%        size, scatter size
%        color, scatter color
%
% output: plot handle

    hold on

    plthandle = scatter3(position(1), position(2), position(3), size, color, 'filled');

    hold off
end