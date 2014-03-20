classdef ANNFilter < FilterLayer & LayerNet
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function self = ANNFilter(layers, lossFun)
            self@LayerNet(layers, lossFun);
            self.threshold = .98; %do a train/test split to decide operating point for each iter?
        end
        
        
        function score = scoreHypothesis(self, frame, hypothesis)
            patch = self.cropPatch(frame, hypothesis);
            if numel(patch) ~= prod(self.szI)
                patch = myimresize(patch, self.szI(1:ndims(patch))); end
            score = sigmoid(self.feed(patch));
        end
        
        
        function trainOut = train(self, trainData) %is trainData always a frame with hypotheses?
            patches = cat(3,trainData{1}{:}); labels = trainData{2};
            options.epochs = 3;
            options.minibatch = 8; %was 256
            options.alpha = 1e-1;
            options.momentum = .95;
            theta0 = self.parVec;
            %             [xte, xtr, yte, ytr] = splitData(x, y', .3);
            %
            cost = @(theta, data, labels) self.descend(reshape(data, self.szI(1), self.szI(2), 1, [])/256, labels, theta);
            [thetaMin] = minFuncSGD(cost,theta0,patches,labels,options);
            self.setPars(thetaMin);
            trainOut = [];
        end
    end
    
end

