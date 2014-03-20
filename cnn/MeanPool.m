function [out] = MeanPool(array, poolSz, poolSteps, doBack)
mask = ones((poolSz)) / prod(poolSz);
if nargin < 4
    doBack = false; end
if nargin < 3
    poolSteps = poolSz; end

if doBack
    unPooled = mykron(array, mask);
    out = unPooled;
else
    
    means = convn(array, mask, 'valid');
    for i = 1:length(poolSz)
        gridInds{i} = 1:poolSteps(i):size(means, i); %defines a grid in the n-dimensional space
    end
    % indsSample = recGenInds(inds,
    szSampled = cellfun(@length, gridInds);
    
    means = recSampleGrid(means, gridInds, szSampled);
    out = means;
end
