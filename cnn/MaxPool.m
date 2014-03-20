function [out] = MaxPool(array, poolSz, poolSteps, doBack)
% could use imdilate or ordfilt - would ordf work?
if nargin < 4
    doBack = false; end
if nargin < 3
    poolSteps = poolSz; end

if doBack
    unPooled = mykron(array, mask); %NYI
    out = unPooled;
else
    mask = ones((poolSz));
    maxes = imdilate(array, mask);
%     size(maxes)
    for i = 1:length(poolSz)
        gridInds{i} = 1:poolSteps(i):size(maxes, i); %defines a grid in the n-dimensional space
    end
    % indsSample = recGenInds(inds,
    szSampled = cellfun(@length, gridInds);
    
    maxes = recSampleGrid(maxes, gridInds, szSampled);
    out = maxes;
end
end
