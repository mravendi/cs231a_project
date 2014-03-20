function [L, dL_dI, classPred] = LogisticLoss(input, target) %nclass x nsamp
[nClass, nSamp] = size(input);
expBinary = false;
if size(input, 1) == 1
    input = [input; zeros(1, nSamp)]; %prediction for positive, then negative
    expBinary = true;
    nClass = 2;
end

if numel(target) ~= numel(input)
    if any(target == 0)
        target = target + 1; end
%     keyboard
    target = accumarray([vec(target), vec(1:nSamp)], 1, size(input));
%     [rows, cols] = find(target);
%     target = rows;
end
target = logical(target);
[targetClasses, cols] = find(target);

%TODO don't account for nSamp in internal functions, instead loop over
%samples out here - should always loop over samples unless they interact
[L, dL_dI, classPred] = LogisticLoss2(input, target); 
if expBinary
    dL_dI = dL_dI(1,:); end
return;


[probs, dProbs_dI] = getProbs(input);

pTarg = probs(target);
L = -sum(log(pTarg));
dL_dPTarg = -1./pTarg;
dL_dProbs = accumarray([vec(targetClasses), vec(cols)], dL_dPTarg, [nClass nSamp]);

dL_dProbs = reshape(dL_dProbs, [1 nClass nSamp]); 
dL_dI = squeeze(sum(bsxfun(@times, dL_dProbs, dProbs_dI), 2));
% for sample 1, dL_dProbs(:,:,1) of length nClass
% and dProb_dI(:,:,1) of size(nClass x nClass) (input x prob)
% want to sum over probs
%gradient check this??
end


function [L, dL_dI, classPred] = LogisticLoss2(input, target) %nclass x nsamp
[nClass, nSamp] = size(input);
[pProbs, dpProbs] = pseudo(input); %nClassxnSamp, nClassxnClassxnSamp
[~, classPred] = max(pProbs, [], 1);
[pTarg, dpTarg] = prob(pProbs, target); %1xnSamp, nClassx1xnSamp
[L, dL_dpTarg] = logLoss(pTarg); %1x1, 1xnSamp
dL_dpProbs = chainRule(dL_dpTarg, dpTarg, [1], [1], [nClass], nSamp);  %1xnClassxnSamp
dL_dI = chainRule(dL_dpProbs, dpProbs, [1], [nClass], [nClass], nSamp);
dL_dI = reshape(dL_dI, size(input));
end

function dO_dI = chainRule(dO_dInt, dInt_dI, szO, szInt, szI, nSamp) %have a derivative be szO x szI x numSamples
%what to do if we want a compact d1_d2? Expand by tiling with kron(some
%eye)? Or figure out algorithm for compact representation (consistent way
%of representing)
%what about a generalized 'matrix' product that sums over dims1, dims2 no
%matter their ordering?

dO_dInt = reshape(dO_dInt, prod(szO), [], 1, nSamp);
dInt_dI = reshape(dInt_dI, 1, prod(szInt), [], nSamp);
dO_dI = sum(bsxfun(@times, dO_dInt, dInt_dI), 2);
sz = [szO, szI]; sz = num2cell(sz);
sz{end+1} = nSamp;

dO_dI = reshape(dO_dI, sz{:});
end

function [O, dO_dI] = pseudo(I) %n class x n samp
[nClass, nSamp] = size(I);
O = exp(I);
dO_dI = (zeros(nClass, nClass, nSamp)); %pointwise: actually 3D... but would like compact rep
%no ND sparse arrays???
[iClass, iSamp] = ind2sub(size(I), 1:numel(I));
inds = sub2ind(size(dO_dI), iClass, iClass, iSamp);
dO_dI(inds) = O(:);
end

function [O, dO_dI] = prob(I, targetMask)
[nClass, nSamp] = size(I);
sums = sum(I, 1);
ps = bsxfun(@rdivide, I, sums);
sums = sums';
O = ps(targetMask); %nSamp - output dim for 1 sample is 1, input dim for 1 sample is nClass

dO_dI = -vec(O)./vec(sums);%output first dimensions, input second, then samples last
dO_dI = repmat(reshape(dO_dI, [1 nSamp]), [nClass 1]);
dO_dI(targetMask) = vec(dO_dI(targetMask)) + vec(1./sums);
dO_dI = reshape(dO_dI, [1 nClass nSamp]);
end

function [O, dO_dI] = logLoss(probs)
O = -sum(log(probs));
dO_dI = -1./probs(:);
end

function [out, dO_dI] = getProbs(in) %num classes x num samples
[nClass, nSamp] = size(in);
pseudoProbs = exp(in);
sums = sum(pseudoProbs, 1);
probs = bsxfun(@rdivide, pseudoProbs, sums);
out = probs;
dO_dPseudo = -bsxfun(@rdivide, probs, sums);
dO_dPseudo = reshape(dO_dPseudo, nClass, 1, nSamp);
dO_dPseudo = repmat(dO_dPseudo, 1, nClass); %class in x class out x sample?
inds = sub2ind([nClass nClass], 1:nClass, 1:nClass);
for i = 1:nSamp
    dO_dPsamp = dO_dPseudo(:,:,i);
    dO_dPsamp(inds) = dO_dPsamp(inds) + 1/sums(i);
    dO_dPseudo(:,:,i) = dO_dPsamp;
end

pProbs = repmat(reshape(pseudoProbs, [nClass 1 nSamp]), 1, nClass);
dO_dI = dO_dPseudo.*pProbs;
end

