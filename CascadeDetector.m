classdef CascadeDetector < handle
    
    
    properties
        layers;
        preProc;
        lastFrame;
        %other stuff?
    end
    
    methods
        function [hypotheses, scores] = detect(self, currFrame)
%             [frameProc, hyp0] = self.preProc.proc(currFrame);
            frameProc = currFrame; hyp0.hyps = MakeHypotheses(); %tmp
            
            hyp = {hyp0}; score = {1}; frame = {frameProc};
            
            for i = 1:length(self.layers)
                %should a layer also get the processed frames from previous
                %layers? No, because then they are all interdependent? How
                %tightly coupled do we want them (amount of shared data +
                %compute)
                ts = tic;
                layer = self.layers{i};
                
                %eventually want to use a DetHyps, don't delete the hyps
                %explicitly, just signal to a layer to ignore them
                [h,s,f, indsGood] = layer.filter(hyp{i}, score{i}, frameProc); times(i+1) = toc(ts);
                
                if ~isempty(h.hyps)
%                     keyboard
                    h.hyps = h.hyps(indsGood); end
                hyp{i+1} = h; score{i+1} = s(indsGood); frame{i+1} = f;
            end
%             keyboard
            f = @(h) numel(h.hyps);
            counts = cellfun(f, hyp);
            nRemoved = -diff(counts(2:end))
            tTot = sum(times)
            times
            cand = find(counts, 1, 'last');
            if cand > 1
               figure(1); imshow(DrawHighScores(currFrame, hyp{cand}.hyps, score{cand}, 3));
               title(class(self.layers{cand-1}));
               pause(.1);
            end
%             keyboard
            hypotheses = hyp{end}.hyps;
            scores = score{end};
            self.lastFrame = currFrame;
        end
        function [trainOut] = train(self, trainData)
            for i = 1:length(self.layers)
                trainOut{i} = self.layers{i}.train(trainData);
            end
        end
        
    end
    
end

