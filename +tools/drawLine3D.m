function plthandle = drawLine3D(pos1, pos2, color)
% draws a line in a 3D figure starting at pos1 and ending at pos2 in color color
%
% input:
%   pos1:   [1x3]double starting position of line
%   pos2:   [1x3]double ending position of line
%   color:  [1x3]double RGB triplet of the color or matlab color option
%
% inital author: Lukas Nagel

    % draw line
    plthandle = plot3([pos1(1), pos2(1)], [pos1(2), pos2(2)], [pos1(3), pos2(3)], 'Color', color);

end

