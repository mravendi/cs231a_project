
function rect = HypRectRounded(hypothesis, varargin)
% fields = strsplit('x1 y1 x2 y2'); %strsplit is slow
%HACK for hypothesis that is basically just a rectangle
rect = round(struct2array(hypothesis));
return

fields = {'x1 y1 x2 y2'};
index = 1;
if ~isempty(varargin)
    index = varargin{1}; end

for i = 1:length(fields)
    rect(i) = hypothesis.(fields{i})(index);
end
rect = round(rect);
end

