function ratio = IoverU(rect1, rect2)
ri = BR2WH( IntRects(rect1, rect2));
% ru = BR2WH( UnRects(rect1, rect2));
rect1 = BR2WH(rect1); rect2 = BR2WH(rect2);
area = @(r) prod(r(3:4));

ai = max(area(ri), 0);
au = area(rect1) + area(rect2) - ai;
ratio = ai / au; 
end

function rect = IntRects(rect1, rect2)
funcs = {@max, @max, @min, @min};
for i = 1:4
    rect(i) = funcs{i}(rect1(i), rect2(i));
end
end