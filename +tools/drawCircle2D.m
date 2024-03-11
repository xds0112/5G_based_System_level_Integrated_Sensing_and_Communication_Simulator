function drawCircle2D(center, r, varargin)
%drawCircle2D draws a circle at center with radius r in the specified options
%
% input:
%   center:     [1x2]double position of circle
%   r:          [1x1]double radius of circle
%   varargin:   [] additional plotting options see rectangle documentation
%
% initial author: Lukas Nagel
%
% see also rectangle

    % draw circle
    rectangle('Position',[center(1)-r, center(2)-r, 2*r, 2*r],'Curvature',[1 1], varargin{:});

end

