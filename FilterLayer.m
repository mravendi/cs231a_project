classdef FilterLayer < handle
   
    properties
        threshold;
    end
    
    methods
        
        function score = scoreHypothesis(self, frame, hypothesis)
            error('You must override scoreHypothesis or filter');
        end
        
        function [hypData, scores, framePost, indsGood] = filter(self, hypData, scores, framePre)
            %note, the results for hypotheses may not be independent, if so
            %need to override this
            framePost = self.preProc(framePre);
            hyps = hypData.hyps; %don't use pyramid by default?
            scores = zeros(length(hyps), 1);
            
            for i = 1:length(hyps) %parfor?
                scores(i) = self.scoreHypothesis(framePost, hyps(i));
            end
%             [scores, i] = sort(scores, 'descend'); %should we just return all, outsource this to an external call?
            indsGood = scores > self.threshold;
        end
        
        function patch = cropPatch(self, frame, hyp)
            patch = myimcrop(frame, BR2WH(HypRectRounded(hyp)), true); %my own quick imcrop
            %can make even faster by not doing the rounding, br2wh?
            
            %or should we sample / interp2??
%             size(patchWarped)
        end
        
        function [framePost] = preProc(self, framePre)
            framePost = framePre;
        end
        
        function trainOut = train(self, trainData) %is trainData always a frame with hypotheses?
            trainOut = 'UNTRAINABLE';
        end
    end
    
end

