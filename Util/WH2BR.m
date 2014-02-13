

function br = WH2BR(rect)
br = rect;
br(3:4) = br(3:4) + br(1:2);
end