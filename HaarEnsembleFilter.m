classdef HaarEnsembleFilter < EnsembleFilter
    % we just need to compute means over a rectangle with BR or TL corners at the points
    % - the below facilitates this
    
    properties
    end
    
    methods
        function sums = getSums(self, frame, hypothesis)
            [linInds, rows, cols] = self.warpCmps(size(frame), hypothesis); %px cmps x base classifiers x left/right
            %also need areas to get means
            rect = HypRectRounded(hypothesis);
            corner1 = cat(4, rows, cols);
            corner4 = tern(self.fromTL, rect(1:2), rect(3:4)); %need to make sure tern can expand these appropriately
            corner2 = corner1; corner3 = corner1; %could calc these in the loop so they aren't all stored... TODO?
            corner2(:,:,:,2) = corner4(:,:,:,2);
            corner3(:,:,:,1) = corner4(:,:,:,1);
            corners = {corner1, corner2, corner3, corner4};
            signs = [1 -1 -1 1]; %to get rect
            sums = 0;
            for i = 1:4
                lin{i} = corners{i}(:,:,:,1) + (corners{i}(:,:,:,2) - 1) * frameSz(1);
                sums = sums + frame(lin{i}) * signs(i);
            end
            sums = abs(sums);
        end
        
        function [score, indices] = scoreHypothesis(self, frame, hypothesis)
            
            sums = self.getSums(frame, hypothesis);
            means = sums; means(:,:,2) = means(:,:,2) * self.aratio;
            %really a scaled version of means, but we just need to compare
            %them
            bitVecs = means(:,:,1) > means(:,:,2);
            [score, indices] = self.scoreCmpVecs(bitVecs);
        end
        
        function [framePost] = preProc(self, framePre)
            framePost = myIntIm(double(framePre) / max(double(framePre(:))));
        end
        
        function [] = genBase(self)
            genBase@EnsembleFilter(self);
            fromTL = randn(self.nCmp, self.nBase, 2) > 0; %whether we start a haar feature
            
            % at the top left or bottom right of the patch
            % kind of hacky - could rewrite EnsembleFilter to be more
            % general
            deltay = tern(fromTL, 0, patchSize(1));
            deltax = tern(fromTL, 0, patchSize(2));
            widths = abs(self.cols{1} - deltay);
            heights = abs(self.rows{1} - deltax);
            areas = widths .* heights;
            aratio = areas(:,:,1) ./ areas(:,:,2);
            self.fromTL = fromTL;
            self.aratio = aratio;
            
        end
    end
    
    
end

