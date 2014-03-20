function g = gabor(size, sigma, lambda, gamma, theta) %size of filter, scale, wavelength, aspect ratio, orientation
%see pg 114 of BIF

if length(size) < 2
    size(2) = size(1); end
bds = (size-1) / 2; %wasn't subtracting 1 before, that was the issue
x = linspace(-bds(2), bds(2), size(2));
y = linspace(-bds(1), bds(1), size(1));
[X0, Y0] = meshgrid(x,y);
X = X0*cos(theta) - Y0 * sin(theta);
Y = X0*sin(theta) + Y0*cos(theta);
t1 = exp(-(X.^2 + (gamma*Y).^2)/(2*sigma^2));
t2 = cos((2*pi / lambda)*X);
g = t1.*t2;
xnorm = (2*X) / size(2); ynorm = (2*Y) / size(1);
outside = xnorm.^2 + ynorm.^2 > 1 ;
% keyboard
% nnz(outside)
% numel(outside)
g(outside) = 0;
g = g - mean(g(:));
g = g / norm(g(:));
% end