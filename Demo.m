%% Test script
clear
imPath = 'TLD_source/_input';
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
doConvNet = 0;
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
    ann = ANNFilter(l, @LogisticLoss);
    
    
    cd.layers = {window, variance, ensemble, ann};
else
    cd.layers = {window, variance, ensemble, neighbors};
end
% error('err');

%%
cd.train(trainData);
g = rgb2gray(im);
hDet = hyp0;
will_track = 0;
hPrev_tracker = []; hPrev_tracker = HypRectRounded(hyp0)
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
hPrev_tracker = [];
for i = 1:1:50
    strcat('Frame:', num2str(i))
    %ensemble filter can currently look at ~2 hypotheses per ms
    im2 = getIm(i);
    gPrev = g;
    hPrev = hDet;
    g = rgb2gray(im2);
    clf;
    imshow(g, []);
    hold on;
    
    [hDet, scoreDet, cascadeCandidates] = cd.detect(g);
    if doConvNet
            for j = 1:length(hDet)
                patch = imresize(ensemble.cropPatch(g, hDet(j)), l{1}.szI(1:2));
                prob(j) = sigmoid(-net.feed(patch));
            end
        prob(:)'
        scoreDet(:)'
    end
    % SKELETON CODE FOR INTEGRATION/LEARNING
    hTrack = [];
    hPrev_tracker
    if sum(hPrev_tracker) ~= 0
        hTrack = LKTracker(gPrev, g, hPrev_tracker);
        hDisplay_prev = [hPrev_tracker(1:2) (hPrev_tracker(3:4)-hPrev_tracker(1:2))];
        rectangle('Position', hDisplay_prev, 'EdgeColor', 'green');
        hPrev_tracker = hTrack;

        if sum(hTrack) ~= 0
            hDisplay = [hTrack(1:2) (hTrack(3:4)-hTrack(1:2))];
            rectangle('Position', hDisplay, 'EdgeColor', 'blue');
        else
          	text(50, 50,'OBJECT NOT DETECTED', 'FontSize', 30, 'Color', 'red')
        end
    end

    bestScore = 0;
    idx = 0;
    if sum(hTrack) ~= 0 && ~isempty(hDet)
        [hBestBox, bestScore, idx] = Integrate(hDet, hTrack);
    elseif ~isempty(hDet)
        hDet_end = hDet(end);
        hBestBox = [hDet_end.x1 hDet_end.y1 hDet_end.x2 hDet_end.y2];
    elseif sum(hTrack) ~= 0
        % since detector does not give back any results
        hBestBox = hTrack;
    end
    
    if sum(hBestBox) ~= 0
        if idx ~= 0
           box = hDet(idx);
           box = [box.x1 box.y1 box.x2 box.y2];
           rectangle('Position', BR2WH(box), 'EdgeColor', 'magenta'); 
        end
        
        hDisplayBestBox = [hBestBox(1:2) (hBestBox(3:4)-hBestBox(1:2))];
        rectangle('Position', hDisplayBestBox, 'EdgeColor', 'yellow');
        hPrev_tracker = hBestBox;
    else
        text(50, 50,'OBJECT NOT DETECTED', 'FontSize', 30, 'Color', 'red')
    end

    hBestBox
    bestScore

    thresh = 0.64;

    reliable = false;
    if (bestScore > thresh)
        reliable = true; end
    if all(hTrack == 0)
        reliable = false; end

    if reliable        
        text(50, 50,'LEARNS', 'FontSize', 30, 'Color', 'blue')

        hyp_best = MakeHypotheses(hBestBox);
        patches = WarpHyp(g, hyp_best);

        pos_patches = {};
        neg_patches = {};
        for jj=1:length(patches)
            [sims, normed, sims_p, sims_n] = neighbors.similarity(patches{jj});
            if sims.cons >= 0.5
                pos_patches{end+1} = patches{jj};
            %else
                neg_patches{end+1} = patches{jj};
            end
        end

        % P-Expert
        is_pos = ones(size(neg_patches));

        % N-Expert
        [n_expert_patches] = N_Expert(g, cascadeCandidates, hBestBox);
        is_neg = ones(size(n_expert_patches));

        train_data = {vertcat(pos_patches', n_expert_patches'), logical(vertcat(is_pos', ~is_neg'))};
        cd.train(train_data);
    end
    pause(0.01);
end
% profile viewer
% boost ensemble, add features for NN, add ANN, integrator finds occlusion,
% out of frame, frame change, reliability score
error('Done with demo');
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
