
function rect = BR2WH(rect)
wh = rect(3:4) - rect(1:2);
rect(3:4) = wh;
% mat = eye(4);
% mat(3, 1) = -1;
% mat(4, 2) = -1;
end