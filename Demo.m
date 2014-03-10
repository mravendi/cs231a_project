%% Test script
clear
imPath = '/home/jray/Desktop/CS231A/project/TLD_source/_input';
getIm = @(i) imread(fullfile(imPath, sprintf('%05d.png', i)));
initBox = [288,36,313,78];

%%

im = getIm(1);
g = rgb2gray(im);
hyp0 = MakeHypotheses(initBox);
patch0 = imcrop(g, BR2WH(initBox));
targetVar = var(double(patch0(:))); %for varFilter, layer 2
sz0 = size(patch0); % for windowGen, layer 1
% imshow(patch0);

% w = WindowGenerator(sz);
% profile on
% hyps = w.getWindows(g); %~1s in num2cell
% BR2WH(HypRectRounded(hyp0))
% BR2WH(HypRectRounded(hyps(end)))
% profile viewer
%%
clear variance;
%%
tic
window = WindowGenerator(sz0);
hyps = window.getWindows(g);
variance = VarianceFilter(targetVar);
[hyps2, scores] = variance.filter(hyps, [], g);
% error('err');

%%
ensemble = EnsembleFilter(sz0);
neighbors = NNFilter({}, []);
toc
%%
tic
% profile on
patchesPos = WarpHyp(g, hyp0);
isPos = ones(size(patchesPos));

isNeg = [];
gridSmall = hyps.pyramid.grids(1);
possIndsNeg = find(scores(1:gridSmall.count) > .5);
hyps = Grid2Hyps(gridSmall, possIndsNeg);
inds = randsample(length(hyps), 1000);
for i = inds(:)'
    hypNeg = hyps(i);
    if IoverU(HypRectRounded(hypNeg), HypRectRounded(hyp0)) > .25
        continue; end
    patchesNeg{i} = ensemble.warp(g, hypNeg);
    isNeg(i) = 1;
end
% profile viewer %11s, ~8 wasted in resize parchk, strsplit, strjoin, rect conversions
toc %.7 seconds

isNeg = isNeg ~= 0;
patchesNeg = patchesNeg(isNeg); 
isNeg = isNeg(isNeg);

patches = vertcat(patchesPos(:), patchesNeg(:));
labels = vertcat(isPos(:), ~isNeg(:));



%%
sample = randsample(length(labels), length(labels));
trainData = {patches(sample), logical(labels(sample))};
cd = CascadeDetector();
cd.layers = {window, variance, ensemble, neighbors};
%%
tic
cd.train(trainData); %.7 seconds
toc
error('stop');
%%
doConvNet = 1;
if doConvNet
szI = size(patches{1});
nFilt = 7;
szFilt = round(szI/5);
poolSz = round(szFilt/2);
l = {};
l{end+1} = ConvLayer(szI, nFilt, szFilt);
l{end+1} = PointwiseLayer(@mysoftsign, l{end}.szO);
l{end+1} = PoolLayer(l{end}.szO, l{end}.szO(1:2), poolSz, @MeanPool);
l{end+1} = LinearTransLayer(l{end}.szO, 3);
l{end+1} = PointwiseLayer(@mysoftsign, l{end}.szO); %the softsign seems to fix saturation issue! Except now it's overtrained
l{end+1} = LinearTransLayer(l{end}.szO, 1);
net = LayerNet(l, @LogisticLoss); %have layernet do the reshaping and sum over samples?

%%
options.epochs = 3;
options.minibatch = 8; %was 256
options.alpha = 1e-1;
options.momentum = .95;
theta0 = net.parVec;
x = cat(4,trainData{1}{:}); y = trainData{2};
[xte, xtr, yte, ytr] = splitData(x, y', .3);
size(yte)
size(ytr)
%%
cost = @(theta, data, labels) net.descend(reshape(data, szI(1), szI(2), 1, [])/256, labels, theta);
[thetaMin, pars] = minFuncSGD(cost,theta0,xtr,ytr,options);
%%
clear ctr cte
inds = 1:20:size(pars,2);
for i = inds
    theta = pars(:, i);
    [ctr(i), ~, out] = cost(theta, xtr, ytr); ctr(i) = ctr(i) / length(ytr); %should I change LogLoss to mean instead of sum?
    atr(i) = mean(ytr == (out < 0));
    [cte(i), ~, out] = cost(theta, xte, yte); cte(i) = cte(i) / length(yte);
    ate(i) = mean(yte == (out < 0));
end
%% Plot training curves
% ctr = ctr*length(ytr); cte = cte*length(yte);
plot([ctr(inds)', cte(inds)']); title('loss'); legend('train', 'test'); %wow this takes a long time
figure; plot([atr(inds)', ate(inds)']); title('acc'); legend('train', 'test'); %wow this takes a long time
%% ROC for NN and trained CNet
patchTr = mat2cell(xtr, 43, 26, 1, ones(size(xtr, 4),1));
NN2 = NNFilter(patchTr(:), ytr);
minGood = inf;
maxBad = -inf;
for i = 1:length(yte)
    patch = xte(:,:,:,i);
%     score = NN2.scoreHypothesis(patch);
    score = -net.feed(patch);
    NNScore(i) = score; 
    doShow = false;
    if yte(i) && score < minGood
        minGood = score;
        doShow = true;
    end
    if ~yte(i) && score > maxBad
        maxBad = score;
        doShow = true;
    end
    if doShow imshow(patch, []); title(sprintf('IsPos: %d   score: %2.2f', yte(i), NNScore(i))); pause; end
end
%%
CNScore = out;
nTe = length(yte);
plotroc(yte, -CNScore(:)');
figure; plotroc(yte, NNScore(:)');
% targets = accumarray([yte(:)+1, (1:nTe)'], 1);
% plotroc(targets, vertcat(CNScore(:)', -CNScore(:)'));
% figure; plotroc(targets, vertcat(-NNScore(:)', NNScore(:)'));
% [FP1, TP1] = ROC(
%%
n = 8;
il = 6;
figure(1); subplot(1,3,1); imagesc(reshape(l{il}.lastI, [], n)); title('input');
subplot(1,3,2); imagesc(reshape(l{il}.lastO, [], n)); title('output');
subplot(1,3,3); imagesc(l{il}.W); title('pars');
end
%%
variance.targetVar
plot(ensemble.positives ./ ensemble.negatives);
show = @(arr, i) imshow(imresize(reshape(arr(:, i), [15 15]), [75 75]), []);
figure; show(neighbors.positives, 20);
figure; show(neighbors.negatives, 20);
% error('err');
%%

% to speed up - replace var filter with variance on grid
% use optical flow, gradient magnitude, quadtree or something to preprune
% Warp EF indices to set frame sizes?
% window generator store history
% EF indexing, maybe my own sub2ind?
% should have a class for set of hypotheses (pyramid?)
% or a class for pyramid sampling of image, then we can just keep the same
% grid, areas, etc.
% Yeah we need a DetHyps class with grid, pyramid, specific hyps, masks,
% frame that is persistent
% Don't use continuous pixel values (need to be careful about
% over-generalizing!)
% profile on
g = im;
hDet = hyp0;
for i = 1:5:50
    %ensemble filter can currently look at ~2 hypotheses per ms
im2 = getIm(i);
gPrev = g;
hPrev = hDet;
g = rgb2gray(im2);

[hDet, scoreDet, cascadeCandidates] = cd.detect(g);
if doConvNet
for i = 1:length(hDet)
    patch = imresize(ensemble.cropPatch(g, hDet(i)), l{1}.szI(1:2));
    prob(i) = sigmoid(-net.feed(patch));
end
prob(:)'
scoreDet(:)'
pause
end
continue;
% SKELETON CODE FOR INTEGRATION/LEARNING
hTrack = LKTracker(g, gPrev, hPrev);

boxes = vertcat(hDet, hTrack);
[bestBox, bestScore] = Integrate(boxes, objectModel);
if (bestScore > thresh)
    reliable = true; end
if all(hTrack == 0)
    reliable = false; end
if reliable
    positives = SamplePositive(frame, bestBox);
    negatives = SampleNegative(frame, bestBox, cascadeCandidates); %get candidates from cascade detector
    labelPos = ones(size(positives)); labelNeg = zeros(size(negatives));
    trainData = {vertcat(positives, negatives), vertcat(labelPos, labelNeg)};
    cd.train(trainData);
end
if bestBox
    drawBox(frame, bestBox);
end
end
% profile viewer
% boost ensemble, add features for NN, add ANN, integrator finds occlusion,
% out of frame, frame change, reliability score
% error('stop');
%%
tic
v = VarianceFilter(targetVar);
% profile on
[hyps2, s2, f2] = v.filter(hyps, [], g); %wastes 1/2 of time calculating rect (rounded), area for each
% profile viewer %~1.5s
toc
%%
im2 = DrawHighScores(g, hyps2, s2);
figure(2);
imshow(im2);


%%
% pars = num2cell(initBox);
clear ef;

ef = EnsembleFilter(size(patchesPos{1}));
tic
profile on
ef.train({patchesPos, isPos}); %way too slow to have array of BaseClassifiers, need to consolidate this too :(
toc
profile viewer


%%
tic
% profile on
ef.train({patchesNeg, ~isNeg});
% profile viewer
toc

%%
% profile on
tic
[hyps3, s3] = ef.filter(hyps2, s2, g);
toc
figure(3);
imshow(DrawHighScores(g, hyps3, s3, 10));
% profile viewer
%current bottleneck seems to be imresize used in warp
%slower than nnf?
%they stretch comparisons to patch instead of resizing patch
error('end');

%%
clear nnf;


nnf = NNFilter(patches, labels);
%%
tic
% profile on
[hyps4, s4] = nnf.filter(hyps2, [], g);
% profile viewer %more than half of time in fixPatch
toc

% imshow(DrawHighScores(g, hyps4, s4(1:length(hyps4))));
% imshow(DrawHighScores(g, hyps3, s3, 200));
%%
show = @(arr, i) imshow(imresize(reshape(arr(:, i), [15 15]), [100 100]), []);
show(nnf.positives, 1);
%%
for i = find(~labels)'
    imshow(patches{i});
    pause(.05);
end
%% Testing why we calculate the variance wrong...?
h = hyps2(randsample(length(hyps2), 1));
r = HypRectRounded(h);
r2 = BR2WH(r);
crp = double(imcrop(g, r2)) / 255;
varExp = var(crp(:));
a = numel(crp);
i1 = integralImage(crp);
i2 = integralImage(crp.^2);
d = 0;
var2 = (i2(end-d, end-d) / a) - (i1(end-d, end-d) / a)^2;
[~, score] = v.filter(h, [], g);
var3 = score * v.targetVar / (255^2);
[varExp, var2, var3]
