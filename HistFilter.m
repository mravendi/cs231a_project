classdef HistFilter < FilterLayer
    %Could actually calculate the histograms (color?) for each window, or
    %consider k means or GMM of object patches, then look over whole image
    %and integrate the effectiveness of approximating any patch with those
    %means or gaussians (likelihood) - later stage could even have a GMM
    %including position (but harder to slide that one)
    
    properties
        bins;
        hists;
    end
    
    methods
        function self = HistFilter(thresh)
            self.threshold = thresh;
            self.nBins = 50; %should probably depend on minimum patch size            
            self.bins = linspace(0, 256, self.nBins + 1); %could choose bins more effectively for fine description of object color (based on initial distribution)
            self.hists = ones(self.nBins, 1) / self.nBins; %or zeros?
        end
        
        function [score, h] = scorePatch(self, patch)
            %for now (inspired by color models) use hue weighted by inverse
            %saturation, but could also just use value
            %instead of weighted entry, could have the weight determine the
            %spread of a gaussian (fuzzier histogramming)
            vals = patch(:,:,1);
            weights = 1./patch(:,:,2);
            [~, ibin] = histc(vals(:), self.bins);
            h = accumarray(ibin, weights(:), [self.nBins, 1]);
            h = h / sum(h);
            scores = [];
            for j = 1:size(self.hists, 2)
                hGood = self.hists(:, j);
                scores(j) = self.histSim(h, hGood);
            end
            score = max(scores);
        end
        
        function score = scoreHypothesis(self, frame, hypothesis)
            for i = 1:3
                patch(:,:,i) = self.cropPatch(frame(:,:,i), hypothesis); end
            score = self.scorePatch(patch);
            
        end
        
        function sim = histSim(self, h1, h2) %bhattacharya + chi2 inspired by http://web.mit.edu/naik/www/tracking/naik_icetet_09.pdf
            sB = sum(sqrt(h1.*h2));
            dC = .5 * sum((h1 - h2).^2 / (h1 + h2)); %chi squared distance
            sC = 1 / dC;
            sim = sB * sC; %how to combine these? They are filtering first with sB then sC
        end
        
        function [framePost] = preProc(self, framePre)
            framePost = rgb2hsv(framePre);
        end
        
        function trainOut = train(self, trainData) 
            [patches, isPos] = deal(trainData{:}); 
            patches = patches(isPos);
            for i = 1:length(patches)
                scores(i) = self.scoreHypothesis(patches{i});
            end
            [~, iWorst] = min(scores);
            [~, hWorst] = self.scoreHypothesis(patches{iWorst});
            self.hists = horzcat(self.hists, hWorst);
            
        end
        
        
    end
end
