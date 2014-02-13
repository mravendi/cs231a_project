function [hypotheses] = MakeHypotheses(varargin) %x1, y1, x2, y2, masks
nvar = length(varargin);

noMask = {[]};
if nvar == 0
    x1 = []; y1 = []; x2 = []; y2 = []; masks = noMask;
end
if nvar == 1
    boxes = varargin{1};
    x1 = boxes(:, 1); y1 = boxes(:, 2); x2 = boxes(:, 3); y2 = boxes(:, 4);
    masks = repmat(noMask, size(x1));
end
if nvar == 4
    [x1, y1, x2, y2] = deal(varargin{:});
    masks = repmat(noMask, size(x1));
end
if nvar == 5
    [x1, y1, x2, y2, masks] = deal(varargin{:});
end

%struct of arrays
% hypotheses = struct('x1', x1, 'y1', y1, 'x2', x2, 'y2', y2, 'masks', {masks});        
%array of structs
hypotheses = struct('x1', num2cell(x1), 'y1', num2cell(y1), 'x2', num2cell(x2), 'y2', num2cell(y2), 'masks', masks);        

end

