%% Convolution Neural Network Exercise

%  Instructions
%  ------------
% 
%  This file contains code that helps you get started in building a single.
%  layer convolutional nerual network. In this exercise, you will only
%  need to modify cnnCost.m and cnnminFuncSGD.m. You will not need to 
%  modify this file.

%%======================================================================
%% STEP 0: Initialize Parameters and Load Data
%  Here we initialize some parameters used for the exercise.

% Configuration
imageDim = 28;
numClasses = 10;  % Number of classes (MNIST images fall into 10 classes)
filterDim = 9;    % Filter size for conv layer
numFilters = 20;   % Number of filters for conv layer
poolDim = 2;      % Pooling dimension, (should divide imageDim-filterDim+1)

% Load MNIST Train
addpath ../common/;
images = loadMNISTImages('../common/train-images-idx3-ubyte');
images = reshape(images,imageDim,imageDim,[]);
labels = loadMNISTLabels('../common/train-labels-idx1-ubyte');
labels(labels==0) = 10; % Remap 0 to 10

% Initialize Parameters
theta = cnnInitParams(imageDim,filterDim,numFilters,poolDim,numClasses);

%%======================================================================
%% STEP 1: Implement convNet Objective
%  Implement the function cnnCost.m.

%%======================================================================
%% STEP 2: Gradient Check
%  Use the file computeNumericalGradient.m to check the gradient
%  calculation for your cnnCost.m function.  You may need to add the
%  appropriate path or copy the file to this directory.

DEBUG=true;  % set this to true to check gradient
if DEBUG
    % To speed up gradient checking, we will use a reduced network and
    % a debugging data set
    db_numFilters = 2;
    db_filterDim = 9;
    db_poolDim = 5;
%     db_filterDim = 2;
%     db_poolDim = 9;
    nIm = 5;
    db_images = images(:,:,1:nIm);
    db_labels = labels(1:nIm);
    db_theta = cnnInitParams(imageDim,db_filterDim,db_numFilters,...
                db_poolDim,numClasses);
    %%
    layers = {};
    layers{end+1} = ConvLayer([imageDim imageDim], db_numFilters, [db_filterDim db_filterDim]);
    layers{end+1} = PointwiseLayer(@sigmoid, layers{end}.szO);
    layers{end+1} = PoolLayer(layers{end}.szO, layers{end}.szO(1:2), [db_poolDim db_poolDim], @MeanPool);
    layers{end+1} = LinearTransLayer(layers{end}.szO, 10);
    net = LayerNet(layers, @LogisticLoss);
    %%
    imsReshaped = reshape(db_images, 28, 28, 1, []);
    J = @(theta) net.descend(imsReshaped, db_labels, theta);
    profile on
    [mycost, mygrad] = J(db_theta);
    tic
    mynumGrad = computeNumericalGradient(J, db_theta);
       toc     
       profile viewer
    doOld = 1;
    if doOld
       
    [cost grad] = cnnCost(db_theta,db_images,db_labels,numClasses,...
                                db_filterDim,db_numFilters,db_poolDim);
    

    % Check gradients
    tic
    profile on
    numGrad = computeNumericalGradient( @(x) cnnCost(x,db_images,...
                                db_labels,numClasses,db_filterDim,...
                                db_numFilters,db_poolDim), db_theta);
                            profile viewer %ok so we're slow... mostly in pooling?
                            toc %2/3 the time of mine :(
    end
 
    % Use this to visually compare the gradients side by side
    grads = ([mynumGrad mygrad, numGrad grad]);
    figure(1); plot(grads);
    legend('mynum', 'myg', 'num', 'g');
%     figure(2); plot(numGrad./grad);
    
    diff = norm(numGrad-grad)/norm(numGrad+grad);
    % Should be small. In our implementation, these values are usually 
    % less than 1e-9.
    disp(diff); 
 
    assert(diff < 1e-9,...
        'Difference too large. Check your gradient computation again');
    
end;

%%======================================================================
%% STEP 3: Learn Parameters
%  Implement minFuncSGD.m, then train the model.
tic
options.epochs = 3;
options.minibatch = 256;
options.alpha = 1e-1;
options.momentum = .95;

opttheta = minFuncSGD(@(x,y,z) cnnCost(x,y,z,numClasses,filterDim,...
    numFilters,poolDim),theta,images,labels,options);
toc %662s, 3 epochs, 702 iters
%%
tic
layers = {};
layers{end+1} = ConvLayer([imageDim imageDim], numFilters, [filterDim filterDim]);
layers{end+1} = PointwiseLayer(@sigmoid, layers{end}.szO);
layers{end+1} = PoolLayer(layers{end}.szO, layers{end}.szO(1:2), [poolDim poolDim], @MeanPool);
layers{end+1} = LinearTransLayer(layers{end}.szO, 10);
net = LayerNet(layers, @LogisticLoss);

J = @(theta, data, labels) net.descend(reshape(data, 28, 28, 1, []), labels, theta);
myopttheta = minFuncSGD(J,theta,images,labels,options);
toc %1302s
%tomorrow: test on Einstein, look at faces, 
%%======================================================================
%% STEP 4: Test
%  Test the performance of the trained model using the MNIST test set. Your
%  accuracy should be above 97% after 3 epochs of training

testImages = loadMNISTImages('../common/t10k-images-idx3-ubyte');
testImages = reshape(testImages,imageDim,imageDim,[]);
testLabels = loadMNISTLabels('../common/t10k-labels-idx1-ubyte');
testLabels(testLabels==0) = 10; % Remap 0 to 10

[~,cost,preds]=cnnCost(myopttheta,testImages,testLabels,numClasses,...
                filterDim,numFilters,poolDim,true);

acc = sum(preds==testLabels)/length(preds);

% Accuracy should be around 97.4% after 3 epochs
fprintf('Accuracy is %f\n',acc); %97.22 with theirs... same with mine although slightly different theta
