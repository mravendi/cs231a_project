classdef NNFilter < FilterLayer
    % See 5.3.3
    % this comprises the object model M and functions to compute similarity
    % to M
    properties
        templates;
       
        nMax;
        szNorm;
        positives;
        agesp;
        negatives;
        agesn;
        lambda;
    end
    
    methods
        function self = NNFilter(patches, labels)
            self.threshold = .55;
            self.szNorm = [15 15];
%             doResize = @(patch) double(myimresize(patch, szNorm));
%             subM = @(patch) patch(:) - mean(patch(:));
%             doNorm = @(patch) patch(:)' / norm(patch(:));
%             self.fixPatch = @(patch) doNorm(subM(doResize(patch)));
            
%             nSeed = 5; %seed without checking the first few
%             seedp = patches(find(labels, nSeed));
%             seedn = patches(randsample(find(~labels), nSeed));
%             for i = 1:nSeed
%                 figure(1); subplot(1,2,1); imshow(seedp{i});
%                 subplot(1,2,2); imshow(seedn{i});
%                 pause
%             end
%             self.positives = cell2mat(mycellfun(self.fixPatch, seedp))';
%             self.negatives = cell2mat(mycellfun(self.fixPatch, seedn))';
            
            self.positives = zeros(prod(self.szNorm), 0);
            self.negatives = self.positives;
            
            self.agesp = zeros(size(self.positives, 2));
            self.agesn = zeros(size(self.negatives, 2));
            self.lambda = .1;
            self.nMax = 300;
            
            self.train({patches, labels});
        end
        
        function vec = fixPatch(self, patch)
            patch = double(myimresize(patch, self.szNorm));
            vec = patch(:) - mean(patch(:));
            vec = vec' / norm(vec);
        end
        
        function [sims, normed, sims_p, sims_n] = similarity(self, patch) %different measures?
            normed = self.fixPatch(patch);
%             size(self.negatives)
            noN = isempty(self.agesn); noP = isempty(self.agesp);
            sims_n = tern(noN, 0, .5 * (normed * self.negatives + 1));
            sims_p = tern(noP, 0, .5 * (normed * self.positives + 1));
%             keyboard
            sim_p = max(sims_p);
            sim_n = max(sims_n);
            
            sim_r = sim_p / (sim_p + sim_n);
            
            conservThresh = max(floor(.5 * length(sims_p)), 5);
            sims_pConserv = sims_p(1:min(conservThresh, end));
            sim_pConserv = max(sims_pConserv);
            sim_c = sim_pConserv / (sim_pConserv + sim_n);
            
            sims = struct('cons', sim_c, 'rel', sim_r, 'pos', sim_p, 'neg', sim_n, 'pos_cons', sim_pConserv);
            if noP && noN
                sims.rel = self.threshold;
            end
        end
        
        function [score, patch, sims] = scoreHypothesis(self, frame, hypothesis)
            
            if nargin == 2 %passed a raw patch, not the whole frame
                patch = frame;
            else
                patch = self.cropPatch(frame, hypothesis);
            end
            
            [sims, patch] = self.similarity(patch);
            score = sims.rel;
        end
        
        function [] = forget(self, n)
            names = {'positives', 'negatives'};
            anames = {'agesp', 'agesn'};
            for i = 1:length(names)
                counts(i) = size(self.(names{i}), 2); end
            nT = sum(counts);
            
            if nargin < 2
                n = nT - self.nMax; end
            
            for i = 1:length(names)
                nRemove = ceil(n * counts(i) / nT);
                indsRemove = randsample(counts(i), nRemove);
                self.(names{i})(:, indsRemove) = [];
                self.(anames{i})(indsRemove) = [];
            end
        end
            
       
        function [framePost] = preProc(self, framePre)
            self.agesp = self.agesp + 1;
            self.agesn = self.agesn + 1;
            framePost = framePre;
            %maybe also smooth the image? When should we do that?
        end
                 
        
        function trainOut = train(self, trainData) %is trainData always a frame with hypotheses?
            trainData = trainData(1:2); trainOut = [];
            [patches, labels] = deal(trainData{:}); 
            for i = randsample(length(patches), length(patches))'
                patch = patches{i}; label = labels(i);
                
                [score, patch] = self.scoreHypothesis(patch);
                margin = score - self.threshold; %also theta in the paper
                labelNames = {'negatives', 'positives'};
                anames = {'agesn', 'agesp'}; %could do this more elegantly...?
                
                label2 = 2*(label - .5); %-1 or +1
%                 'training on new patch'
%                 margin * label2
                if margin * label2 < self.lambda %error by a large margin, should add this
                    n = labelNames{label + 1};
                    self.(n) = horzcat(self.(n), patch');
                    self.(anames{label+1})(end+1) = 0;
                end
            end
        end
        
    end
    
end

