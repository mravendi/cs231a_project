classdef EnsembleFilter < FilterLayer
    %See section 5.3.2
    
    %NOTE: does 'self' always need to be the first argument even if unused?
    
    properties
        patchSize;
        nBase;
        nCmp;
        smoothSig;
        
        %replaces the base classifier class, can do this all in here for
        %speed
        %may be even faster to mexify?
        
        cmpInds; %generate these for each scale so we don't have to resize? nCmp x nBase x 2
        rows; %subindices versions of cmpInds, but stored as cell of 1D vectors
        cols; 
        scales; %cache rows/cols for multiple scales that we might see
        
        cmpWeights;
        cmpSetWeights;
        bv2Index;
        positives;
        negatives;
        
        baseClassifiers;
        classWeights;
    end
    
    methods
        function self = EnsembleFilter(patchSize)
            self.patchSize = patchSize;
            self.threshold = .5;
            self.nCmp = 13;
            self.nBase = 1000;
            self.smoothSig = 3; %should depend on image size maybe? Or patch size?
            self.bv2Index = 2.^(0:self.nCmp - 1);
            self.genBase();
        end
        
        function [scores, indices] = scorePatches(self, patches)
            nP = size(patches, 3);
            i1 = repmat(self.cmpInds(:,:,1), [1 1 nP]); 
            i2 = repmat(self.cmpInds(:,:,2), [1 1 nP]); 
            lhs = patches(i1); %unfinished, see if we can index into an array of patches as desired? Might require some 
            %reshaping or recalc of indices
            rhs = patches(i2);
            bitVecs = (lhs > rhs); %can also cat to a regular bit vector!
            indices = self.bv2Index * bitVecs + 1;
            np = self.positives(indices) + 1;
            nn = self.negatives(indices) + 1;
            posteriors = np ./ (np + nn);
        end
        
        function [score, indices] = scorePatch(self, patch)
            %             fun = @(baseClassifier) baseClassifier.scorePatch(patch);
            %             posteriors = arrayfun(fun, self.baseClassifiers);
%             patch = patch(:);            
            i1 = self.cmpInds(:,:,1); i2 = self.cmpInds(:,:,2);
            lhs = patch(i1);
            rhs = patch(i2);
            bitVecs = (lhs > rhs); %can also cat to a regular bit vector!
            [score, indices] = self.scoreCmpVecs(bitVecs);
        end
        
        function [score, indices] = scoreCmpVecs(self, bitVecs)
            indices = self.bv2Index * bitVecs + 1; %code for bit vector
            cols = 1:self.nBase;
            indices = my2Dsub2ind(size(self.positives), indices, cols); %need to convert to index into array
            np = self.positives(indices) + 1; %Laplace smoothing prior %for some reason 30 of these accesses takes 1ms??
            nn = self.negatives(indices) + 1;
            posteriors = np ./ (np + nn); %should we weight by the number of observations? Probably!
            %could assume 1/2, and only actually compute where np, nn
            %both have entries? Would that be faster?
            
            score = posteriors * self.classWeights;
%             score = sum(np) / sum(np + nn); %how does this do? %TODO
%             compare these two approaches
        end
        
        function [score, indices] = scoreHypothesis(self, frame, hypothesis)
            linInds = self.warpCmps(size(frame), hypothesis); %px cmps x base classifiers x left/right
            
            bitVecs = frame(linInds(:,:,1)) > frame(linInds(:,:,2)); %px cmp index x base class index
            [score, indices] = self.scoreCmpVecs(bitVecs);
        end
        
        function linInds = warpCmps(self, imageSize, hyp)
            hypSize = [hyp.y2 - hyp.y1, hyp.x2 - hyp.x1] + 1;
            scaleFactors = hypSize ./ self.patchSize;
            offset = [hyp.y1, hyp.x1] - 1; 
%             linInds = self.cmpInds;
%             if all(scaleFactors == 1) %should just crop the patch and use indices we already have
%                 linInds = self.cmpInds; 
%                 return; 
%             end
            r1 = self.rows{1}; c1 = self.cols{1}; %TODO stupid names, change
            %find if in cache
            inCache = false; %or instead of caching, if we know there's a set of scales can just have the scaleIndex be a hyp par
            for i = 1:length(self.scales)
                scale = self.scales{i};
                if all(scaleFactors == self.scales{i})
                    r1 = self.rows{i};
                    c1 = self.cols{i};
                    inCache = true;
                    break;
                end
            end
            if ~inCache
                r1 = round(r1 * scaleFactors(1));
                c1 = round(c1 * scaleFactors(2));
                if length(self.scales) < 20 %add to cache if not too many stored already?
                    %should have a smarter way to cache, write a class to
                    %do caching based on number of calls
                    self.rows{end+1} = r1; self.cols{end+1} = c1; self.scales{end+1} = scaleFactors;
                end
            end
            %this is 3x faster than doing the below version
            linInds = r1 + c1 * imageSize(1) + (offset(2) - 1) * imageSize(1) + offset(1);
            
%             r1 = r1 + offset(1); c1 = c1 + offset(2); 
%             
%             linInds = my2Dsub2ind(imageSize, r1, c1);
% %             linInds = r1 + (c1 - 1) * imageSize(1); %my fast sub2ind
% %             linInds = sub2ind(imageSize, r1, c1);
%             linInds = reshape(linInds, size(self.cmpInds));
        end
        
        function [score, indices] = scoreHypothesisOld(self, frame, hypothesis)
            %assumes frame has been smoothed!
            patch = self.warp(frame, hypothesis);
            [score, indices] = self.scorePatch(patch);
        end
        
        function [framePost] = preProc(self, framePre)
            
            framePost = self.smooth(framePre, self.smoothSig);
        end
        
        function trainOut = train(self, trainData) %is trainData always a set of patches with labels? Make it a class or struct? Parser to get the frame, hypotheses, patches?
            trainData = trainData(1:2);
            [patches, isPos] = deal(trainData{:}); 
            for i = 1:length(patches)
                patch = patches{i};
%                 patch = self.smooth(patch, self.smoothSig); %might be slow to do this every time...?
                if ~all(size(patch) == self.patchSize)
                    patch = self.resize(patch); end
                
%                 for j = 1:self.nBase
%                     trainOut(i) = self.baseClassifiers(j).train(patch, isPos(i)); %or arrayfun?
%                 end

                [~, indices] = self.scorePatch(patch);
                if isPos(i)
                    self.positives(indices) = self.positives(indices) + 1;
                else
                    self.negatives(indices) = self.negatives(indices) + 1;
                end
                %adjust weights somehow?
                
            end
            trainOut = [];
        end
        
        function smoothed = smooth(~, image, sigma) %default sigma is 3
            g = fspecial('gaussian', [1 round(sigma*6)], sigma);
            smoothed = imfilter(image, g);
            smoothed = imfilter(smoothed, g');
        end
        
        function resized = resize(self, patch)
            resized = patch;
            sz = size(resized);
            delta = sz - self.patchSize;
            if any(delta < 0 | delta > 2) %can tolerate patch being 2px too big?
                sampr = round(linspace(1, sz(1), self.patchSize(1)));
                sampc = round(linspace(1, sz(2), self.patchSize(2)));
                resized = resized(sampr, sampc);
%                 resized = imresize(resized, self.patchSize);
            end
        end
        
        function patchWarped = warp(self, frame, hyp)
            patchWarped = self.cropPatch(frame, hyp);
            
            patchWarped = self.resize(patchWarped);
            
        end
        
        function [] = genBase(self) %TODO kind of hard to read, make this simpler and don't gen all cmps (might be huge for large image)
            xv = 1:self.patchSize(2);
            yv = 1:self.patchSize(1);
            [X1, Y1, X2, Y2] = self.genPxCmps(xv, yv);
            
            linInds1 = sub2ind(self.patchSize, Y1(:), X1(:));
            linInds2 = sub2ind(self.patchSize, Y2(:), X2(:));
            linIndsVert = [linInds1, linInds2];
            
            [Y1, X1, Y2, X2] = self.genPxCmps(yv, xv);
            
            linInds1 = sub2ind(self.patchSize, Y1(:), X1(:));
            linInds2 = sub2ind(self.patchSize, Y2(:), X2(:));
            linIndsHorz = [linInds1, linInds2];
            linInds = [linIndsVert; linIndsHorz];
            
            
            nCmpTot = size(linInds, 1);
            nBase = min(floor(nCmpTot / self.nCmp), self.nBase); %don't want more than 1000 base classifiers?
            nSamp = self.nCmp * nBase; %#ok<*PROP>
            indSamp = randsample(nCmpTot, nSamp);
            linInds = linInds(indSamp, :);
            
            self.nBase = nBase;
            self.classWeights = ones(nBase, 1) / nBase;
            l1 = reshape(linInds(:, 1), self.nCmp, nBase);
            l2 = reshape(linInds(:, 2), self.nCmp, nBase);
%             self.cmpInds = linInds;
            self.cmpInds = cat(3, l1, l2);
            [r, c] = ind2sub(self.patchSize, self.cmpInds);%vec(self.cmpInds(:,:,1)));
            self.rows = {r}; self.cols = {c}; self.scales = {[1 1]};
%             self.cmpWeights = ones(nSamp, 1) / nSamp;
            self.cmpWeights = ones(self.nCmp, nBase) / nSamp;
            %much faster with full representation vs. sparse - not sparse
            %enough? Takes too long to change the sparsity?
            self.positives = zeros(2^self.nCmp, nBase); %sparse(2^self.nCmp, nBase);
            self.negatives = self.positives;
            
            return %not using separate base class anymore
            
%             self.baseClassifiers = BasePixelCmpClassifier.empty(1,0);
%             for i = 1:nBase
%                 self.baseClassifiers(i) = BasePixelCmpClassifier(linInds((1:self.nCmp) + (i-1)*self.nCmp, :));
%             end
            
        end
        
        function [same1, change1, same2, change2] = genPxCmps(~, dimSame, dimChange) %could instead do all within some disc (i.e. distance can't be too big)
            %or even log radial with several thetas, just sample a
            %consistent mask relative to a given pixel (if in bounds)
            pairs = combvec(dimChange(:)', dimChange(:)');
            pairs(:, pairs(1,:) == pairs(2,:)) = []; %other pairs that might not be interesting and we should omit...?
            
            nChange = size(pairs, 2);
            nSame = length(dimSame);
            same1 = repmat(dimSame(:), 1, nChange);
            same2 = same1;
            change1 = repmat(pairs(1,:), nSame, 1);
            change2 = repmat(pairs(2,:), nSame, 1);
        end
            
        
    end
    
end

