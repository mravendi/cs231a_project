
function rectSum = RectSum(intIm, rect)
%assumed x1 y1 x2 y2
x1 = rect(1); y1 = rect(2); x2 = rect(3); y2 = rect(4);
rectSum = intIm(y2, x2) + intIm(y1, x1) - intIm(y1, x2) - intIm(y2, x1);
end