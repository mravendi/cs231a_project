function [intIm, scale] = myIntIm(image)
prevRow = zeros(1, size(image, 2));
for i = 1:size(image, 1)
    intIm(i,:) = cumsum(double(image(i,:))) + prevRow;
    prevRow = intIm(i,:);
end
end