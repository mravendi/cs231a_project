function [test, train, ltest, ltrain, indsTest, indsTrain] = splitData(set, labels, testFrac)
%set of predictors, labels are output values, should be row vec
ndS = ndims(set); ndL = ndims(labels);
n = size(set, ndS);
inds = 1:n;
indsTest = randsample(inds, ceil(n*testFrac));
% keyboard
indsTrain = setdiff(inds, indsTest); indsTrain = randsample(indsTrain, length(indsTrain));
test = selectMultDim(set, indsTest, ndS);
train = selectMultDim(set, indsTrain, ndS);
ltest = selectMultDim(labels, indsTest, ndL);
ltrain = selectMultDim(labels, indsTrain, ndL);
end

function s = selectMultDim(data, inds, indDim)
sz = size(data);
szO = sz; szO(indDim) = length(inds);
szPre = prod(sz(1:indDim-1)); szPre = max(szPre, 1);
szPost = prod(sz(indDim+1:end)); szPost = max(szPost, 1);
% keyboard
data = reshape(data, szPre, [], szPost);

s = data(:,inds,:);
s = reshape(s, szO);
end