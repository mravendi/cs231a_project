%% Demo script

%% Test layer/network classes, basic (try with tensors?)
szI =100;
n = 10;
szO = 1;
x = randn(szI, n);
W = randn(szO, szI);
b = randn(szO);
y = bsxfun(@plus, W*x, b);
%%
clear LT N
%%
LT = LinearTransLayer(szI, szO);
N = LayerNet({LT}, @QuadLoss);
cost = @(theta) N.descend(x, y, theta);
%%

theta = randn(size(N.lastGrad));
[c,g] = cost(theta);
numGrad = computeNumericalGradient(cost, theta);
norm(g-numGrad)





%%
clear

%% Test layer/network classes with multiple layers, nonlinearity
sizes = [100 10 20 5];
% sizes = [10 10 10];
n = 500;

x = randn(sizes(1), n);

l = {};
for i = 2:length(sizes)
    l{end+1} = LinearTransLayer(sizes(i-1), sizes(i));
    l{end+1} = PointwiseLayer(@sigmoid, sizes(i));
end
N = LayerNet(l, @QuadLoss); theta0 = N.parVec;
y = N.feed(x);
cost = @(theta) N.descend(x, y, theta);
theta = randn(size(theta0)).*theta0;
%%
[c,g] = cost(theta);
numGrad = computeNumericalGradient(cost, theta);
norm(g-numGrad)
%%
plot([(g), (numGrad)])
[gs, gi] = sort(g);
[ns, ni] = sort(numGrad);
% plot([gi, ni]);


%% Test layer/network classes with multiple layers, nonlinearity
sizes = [100 10 20 5];
% sizes = [10 10 10];
n = 1;
szI = [20 20]; nFilt = 2; filtSize = 5; szPool = [3 3];
x = randn([szI, n]);
x = convImages;
n = size(x, 3);
szI = size(x(:,:,1));
l = {};
% l{end+1} = ConvLayer(szI, nFilt, filtSize);
% l{end+1} = PointwiseLayer(@sigmoid, l{end}.szO);
% l{end+1} = ConvLayer(l{end}.szO, nFilt, filtSize);
szPool = [2 2];
l{end+1} = PoolLayer(szI, szI, szPool, @MeanPool);
N = LayerNet(l, @QuadLoss); theta0 = N.parVec;
y = N.feed(x);
cost = @(theta) N.descend(x, y, theta);
theta = randn(size(theta0)).*theta0;
%%
imagesc(x(:,:,1)); figure; imagesc(y(:,:,1));

%%
im = rgb2gray(imdata);
imshow(im);
l = PoolLayer(size(im), size(im), [2 2], @MeanPool);
imp = l.feed(double(im));
figure; imshow(imp,[]);
imUp = l.bprop(imp);
figure; imshow(imUp, []);
%%
[c,g] = cost(theta);
numGrad = computeNumericalGradient(cost, theta);
norm(g-numGrad)
%%
plot([(g), (numGrad)])
[gs, gi] = sort(g);
[ns, ni] = sort(numGrad);
% plot([gi, ni]);