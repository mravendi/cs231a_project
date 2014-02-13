function crop = myimcrop(im, rect, fast)
crop = [];
if any(rect(3:4) < 1) %don't allow subpixel tiny stuff
    return; end

if nargin < 3
    fast = false; end

if ~fast
    rect = (WH2BR(rect));
    rect(1:2) = floor(rect(1:2));
    rect(3:4) = ceil(rect(3:4));
else
    rect = round(WH2BR(rect));
end
rows = rect(2):rect(4);
cols = rect(1):rect(3);

if ~fast
    sz = size(im);
    nRows = sz(1); nCols = sz(2);
    rows(rows < 1 | rows > nRows) = [];
    cols(cols < 1 | cols > nCols) = [];
end
% keyboard
% rows
% cols
% size(im)
crop = im(rows, cols, :);

end