%% get images
clear
% im = randn(60);
addpath(genpath('/home/jray/Desktop/Work/Age'));
%%
load FGN_Filedata
nIm = length(imfnames);


DRAW = 0;
%% setup parameters
sigs = [2 2.8 3.6 4.5 5.4 6.3 7.3 8.2 9.2 10.2 11.3 12.3 13.4 14.6 15.8 17];
sizes = 5:2:35;
nBand = length(sizes)/2;
sigs = reshape(sigs, 2, []); sizes = reshape(sizes, 2, []);
lambdas = sigs * 1.25;

band_delts = 3:10;
band_szPools = 6:2:20;
nOr = 4;
thetas = pi*linspace(0,1,nOr+1); thetas(end) = [];
gamma = .3; %why such high aspect? basically just looking for lines at different scales...

%%
if DRAW
    for i = 1:1000
        subplot(1,2,1); imshow(im1{i}, []);
        subplot(1,2,2); imshow(im2{i}, []);
        title(ages(i));
        pause
    end
end
%% Loop
%loop over bands, orientations later
% iTh = 1;
% band = 7;
feats = [];

gsAll = {};
cls = {};
pls = {};
gamma = .3;
for band = 1:nBand
    sigBand = sigs(:, band); szBand = sizes(:, band); lambBand = lambdas(:, band);
    clear gs;
    ip = 1;
    
    
    for iTh = 1:nOr
        for j = 1:2
            
            g = gabor(szBand(j), sigBand(j), lambBand(j), gamma, thetas(iTh));
            padding = repmat(max(szBand) - szBand(j), 1, 2) / 2;
            g = padarray(g, padding);
            gs(:,:,j,iTh) = g;
            if DRAW subplot(4,2,ip); imagesc(g); ip = ip+1; end
        end
    end
    if DRAW figure(1); pause; end


gs = reshape(gs, size(g,1), size(g,2), []);
gsAll{band} = gs;
cls{band} = ConvLayer(size(im), 2*nOr, repmat(max(szBand),1,2));
cls{band}.filts = gs;
cl = cls{band};

if DRAW
    filtered = abs(squeeze(cl.feed(im)));
    % imshow(filtered(:,:,8), [])
    ip = 1;
    for row = 1:4
        for col = 1:2
            subplot(4,2,ip);
            imshow(filtered(:,:,ip), []); ip = ip+1;
        end
    end
    figure(1);
    pause
end
end


%%
if DRAW
    close all
    [c1, s1] = C1(im, filters, fSiz, c1SpaceSS,c1ScaleSS,c1OL,1);
    theirs = s1{4}{1}{2};
    imshow(theirs, [])
    mine = abs(imfilter(im, gs(:,:,1,4)));
    figure; imshow(abs(mine), []);
    figure; imshow(mine./theirs, []);
end
%%
for iIm = 1:nIm
    im = imread(imfnames{iIm});
    ptx = ptsx{iIm}; pty = ptsy{iIm};
    pts = [ptx, pty];
    bounds = [min(pts), max(pts)];
    im = imcrop(im, [bounds(1:2), bounds(3:4)-bounds(1:2)]);
    im = imresize(im, [60, 60]);
    if size(im,3) == 3
        im = double(rgb2gray(im)); end
    ims1{iIm} = im;
    im2 = double(adapthisteq(im));
    ims2{iIm} = im2;
    %     imshow(im, []); title(ages(iIm)); %pause;
    feat = [];
    % end
    %%
    for band = 1:nBand
        cl = cls{band};
        filtered = abs(squeeze(cl.feed(im))); %TODO do we need abs?
        % imshow(filtered(:,:,8), [])
        if DRAW
            ip = 1;
            for row = 1:4
                for col = 1:2
                    subplot(4,2,ip);
                    imshow(filtered(:,:,ip), []); ip = ip+1;
                end
            end
        end
        %%
        sz = size(filtered);
        szOrig = [sz(1), sz(2), 2, nOr];
        filtered = reshape(filtered, szOrig);
        szIm = szOrig(1:3);
        szPool = band_szPools(band);
        poolStride = [szPool/2 szPool/2 2];
        szPool = [szPool szPool 2];
        % maxPool = PoolLayer(szOrig, szIm, szPool, @MaxPool);
        % stdPool = PoolLayer(szOrig, szIm, szPool, @StdPool);
        %%
        maxes = MaxPool(filtered, [szPool 1], [poolStride 1]); %need to test to make sure this is working
        stds = StdPool(filtered, [szPool 1], [poolStride 1]);
        dims(band) = numel(stds);
        feat = vertcat(feat, vec(maxes), vec(stds)); %or keep as maps for further CNN?
        % size(maxes)
        % size(stds)
        
    end
    iIm
    feats(:,iIm) = feat;
end
error('stop'); %before this we are transforming data into features
% size(feats) %size discrepancy, paper claims 6976 - how do they treat borders?
% dims
% can we normalize the feature by skin tone? Use max(abs) instead of max?
%should we set filter response to 0 outside the hull of the face?
%am I supposed to be using an abs filter?


%% PCA on raw feats - should we scale by std? sphere to norm 1?
stds = std(feats, [], 2);
% stds = 1;
featsScaled = bsxfun(@rdivide, feats, stds);
[coeffs, scores, latent] = pca(featsScaled');
nDim = 600;
reduced = scores(:,1:nDim)';

stds2 = std(reduced, [], 2);
stds2(:) = max(stds2);
reduced = bsxfun(@rdivide, reduced, stds2);
testFrac = .25;
[xte, xtr, ltest, ltrain, ite, itr] = splitData(reduced, ages, testFrac);
ageThresh = 16;
lte = (ltest > ageThresh) + 1;
ltr = (ltrain > ageThresh) + 1;
%%
%do svm or neural net - let's try it with a net!

sizes = [nDim 4 1];
ls = {};
for i = 2:length(sizes)
    ls{end+1} = LinearTransLayer(sizes(i-1), sizes(i));
    ls{end+1} = PointwiseLayer(@sigmoid, sizes(i));
end
ls{end+1} = LinearTransLayer(1,1);

net = LayerNet(ls, @QuadLoss);

%% for classification
ls(end-1:end) = [];
net = LayerNet(ls, @LogisticLoss);

%%
cost = @(theta) net.descend(xtr, ltr, theta);
theta = randn(size(net.lastGrad)) * 1e-3;
%%


[c,g] = cost(theta);
numGrad = computeNumericalGradient(cost, theta);
norm(g-numGrad)
plot(g)

%% STEP 3: Learn Parameters
%  Implement minFuncSGD.m, then train the model.
tic
for j = 1:10
    
    
    cost2 = @(theta, data, labels) net.descend(reshape(data, nDim, []), labels, theta);
    trainIms = reshape(xtr, size(xtr,1), 1, size(xtr,2));
    theta =randn(size(theta))*1e-1;
    scale = 1/50;
    
    options.epochs = 50;
    options.minibatch = 128; %was 256
    options.alpha = 1e-1;
    options.momentum = .95;
    
    options.method = 'lbfgs';
%     [thetaMin, pars] = minFuncSGD(cost2,theta,trainIms,ltr,options);
%     [thetaMin, pars] = minFuncSGD(cost2,theta,trainIms,ltrain*scale,options);
    [thetaMin, pars] = minFunc(cost2,theta,options,trainIms,ltr);
    net.setPars(thetaMin);
    pred = net.feed(xte);
    aTr(j) = mean((net.feed(xtr) > 0) ~= ltr');
    aTe(j) = mean((pred > 0) ~= lte');
    %     pars(:,i) = theta;
%     errs(j) = mean(net.feed(xte) ~= lte');
%     mads(j) = mean(abs(net.feed(xte) / scale - ltest));
end
toc

%%
%try a feedforwardnet?
agesPred = net.feed(xte);
median(agesPred)
median(ltest*scale)
r = (agesPred/scale) - ltest;
clear mad madtr
for i = 1:size(pars, 2)
    net.setPars(pars(:,i));
    mad(i) = mean(abs(net.feed(xte) - ltest*scale)) / scale;
    madtr(i) = mean(abs(net.feed(xtr) - ltrain*scale)) / scale;
end
madBase = mean(abs(ltest-median(ltest)))
figure; plot([mad(:), madtr(:)]); legend('test err', 'train err');
%%
X = [ones(length(ltrain), 1), xtr'];
beta = inv(X'*X)*X'*ltrain(:);
Xte = [ones(length(lte), 1), xte'];
pred = Xte*beta;
pred(pred < 0) = 0;
pred(pred > 60) = 60;
r = ltest'-pred;
mean(r.^2)
var(ltest)
%% LIBLINEAR
addpath(genpath('~/Desktop/CS231A/PS4'));
%%
% xtr= train; xte = test; clear train test
lte = double(vec(ltest > ageThresh));
ltr = double(vec(ltrain > ageThresh));
%%
C = 5e-2; solver = 2; bias = 1; %85% for scaled inputs/outputs
svm_options = sprintf('-c %f -s %d -B %d', C, solver, bias);

model = train(ltr, sparse(xtr'), svm_options);
[predTr, accTr] = predict(ltr, sparse(xtr'), model);
[predicted_labels, accuracy] = predict(lte, sparse(xte'), model);
%%
errs = (predicted_labels ~= lte');
iOrig = ite(errs);
failed = ages(iOrig);
hist(failed, 20); pause
for i = 1:length(failed)
    imshow(ims1{iOrig(i)}, []);
    title(failed(i));
    figure(1);
    pause;
end
%% MATLAB SVM
C = 2e-3; %smaller leads to more sv's, more training error, smaller alpha, but also worse test error - so it's the relative weight of error (vs alpha)
%can do a little better with full (non-PCA) features?
%Saturating/overfitting...
svmstruct = svmtrain(xtr', vec(ltr), 'boxconstraint', C);

pTr = svmclassify(svmstruct, xtr');
pTe = svmclassify(svmstruct, xte');
%
accTr = mean(pTr == ltr)
accTe = mean(pTe == lte)
alpha = svmstruct.Alpha;% nSV = length(svmstruct.Alpha)
sum(abs(alpha))
%%
for i = 1:size(pars, 2)
    net.setPars(pars(:,i));
    outs = net.feed(test);
    outs2 = sigmoid(outs);
    t = mean(outs2);
    %     MyErr(i) = mean(abs(predictions - ltest));
    predictions = (outs2 > t) + 1;
    MyErr(i) = mean(predictions ~= ltestC);
end
BaseErr = mean(abs(median(ltest)-ltest))
%%======================================================================
%% STEP 4: Test
n = 10;
p = 100;
in = randn(p,n);
target = randsample(p,n,true); target = target(:)'
[L, g] = LogisticLoss(in, target);
J = @(theta) LogisticLoss(reshape(theta, p, n), target);
numG = reshape(computeNumericalGradient(J, in(:)), p, n);



%% Do gabor filters need some size normalization?
% imshow(stds(:,:,1,1), [])
% o = maxPool.feed(filtered);