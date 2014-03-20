function [out] = StdPool(array, poolSz, poolSteps, doBack)
%use generalized integral image (bunch of cumsums and add/subtract 2^dim)
%or convolution?
mask = ones((poolSz)) / prod(poolSz);

if nargin < 4
    doBack = false; end
if nargin < 3
    poolSteps = poolSz; end

if doBack
    unPooled = mykron(array, mask); %NYI
    out = unPooled;
else
    
    Exp = convn(array, mask, 'same'); %what if we imdilate instead?
    Exp2 = convn(array.^2, mask, 'same');
%     size(Exp)
    for i = 1:length(poolSz)
        gridInds{i} = 1:poolSteps(i):size(Exp, i); %defines a grid in the n-dimensional space
    end
    % indsSample = recGenInds(inds,
    szSampled = cellfun(@length, gridInds);
%     keyboard
    Exp = recSampleGrid(Exp, gridInds, szSampled);
    Exp2 = recSampleGrid(Exp2, gridInds, szSampled);
    vars = Exp2 - Exp.^2;
%     keyboard
    out = sqrt(vars);
end
end
