classdef VarianceFilter < FilterLayer
    %See 5.3.1
    
    properties
        targetVar;
        intIm;
        intIm2;
    end
    
    methods
        function self = VarianceFilter(targetVar, threshold) %could have a min and max variance?
            self.threshold = 2/3;
            self.targetVar = targetVar;
        end
        
        function [hyps, scores, framePost, indsGood] = filter(self, hyps, scores, framePre)
            framePost = self.preProc(framePre);
            if isfield(hyps, 'pyramid')
                p = hyps.pyramid;
%                 f = @(gR, gC, sS) self.varUniformGrid(gR, gC, sS);
                
                vars = arrayfun(@self.varGrid, p.grids, 'UniformOutput', false);
                
                vars = cell2mat(vars(:));
            else
                f = @(h) self.scoreHypothesis([], h);
                vars = arrayfun(f, hyps.hyps);
            end
            scores = vars * 255^2 / self.targetVar;
            scores = min(scores, 1./scores);
            indsGood = scores > self.threshold;
            if isfield(hyps, 'pyramid') && isempty(hyps.hyps)
                hyps.hyps = Pyr2Hyps(p, indsGood);
                indsGood = 1:nnz(indsGood);
            end
        end
        
        function E = expOnRow(self, imName, rowBot, rowTop, cols) %should be sumOnRow, or better name...
%             rowBot
            E = self.(imName)(rowBot, cols);
            if rowTop > 0
                E = E - self.(imName)(rowTop, cols); end
            
        end
        
        function sums = sumsOnRow(self, imName, grid, rowIndex)
            sumBand = self.(imName)(grid.rowsBot(rowIndex), :);
            offset = 0;
            rT = grid.rowsTop(rowIndex);
            if rT > 1
                offset = self.(imName)(rT-1,:); end
            sumBand = sumBand - offset;
            sums = sumBand(grid.colsRight) - sumBand(grid.colsLeft);
        end
        
        function vars = varGrid(self, grid)
            for i = 1:length(grid.rowsTop)
                EI = self.sumsOnRow('intIm', grid, i) / grid.area;
                EI2 = self.sumsOnRow('intIm2', grid, i) / grid.area;
                varRow = EI2 - EI.^2;
                if any(varRow < 0) 
                    keyboard; end
                vars(i, :) = varRow;
            end
            vars = vars(:);
        end
        
        function vars = varUniformGrid(self, gridRows, gridCols, stepSize)
            w = diff(round(gridCols([1, stepSize + 1]))) + 1;
            h = diff(round(gridRows([1, stepSize + 1]))) + 1;
            gridRows
            gridCols
            area = w*h;
%             getRow = @(intIm, i) intIm(gridRows(i), :) - tern(i <= stepSize + 1, 0, intIm(gridRows(max(i - stepSize - 1,1), :))); %eww
            
%             vars = zeros(length(gridRows), length(gridCols));
            for i = stepSize+1:length(gridRows)
%                 rowB = gridRows(i);
%                 rowT = gridRows(i - stepSize);
                %score column
                Irow = self.expOnRow('intIm', gridRows(i), gridRows(i - stepSize) - 1, gridCols) / area; 
%                 Irow = getRow(self.intIm, i) / area; Irow = Irow(gridCols);
                EI = diff([0, Irow], stepSize); %need the extra 0 so that the first box doesn't get an offset
                I2row = self.expOnRow('intIm2', gridRows(i), gridRows(i - stepSize) - 1, gridCols) / area; 
%                 I2row = getRow(self.intIm2, i) / area; I2row = I2row(gridCols);
                EI2 = diff([0, I2row], stepSize); 
                varRow = EI2 - EI.^2;
%                 keyboard
                vars(i-stepSize, :) = varRow;
            end
            keyboard
            vars = vars(:);
        end
        
        function score = scoreHypothesis(self, ~, hypothesis)   
            %can speed further by precalculating rect, area, 1/area,
            %rowwise progression
            
            %TODO precalc area, adjust appropriately
            
            rect = round([hypothesis.x1, hypothesis.y1, hypothesis.x2, hypothesis.y2]);
            a = diff(rect([2,4])) * diff(rect([1 3]));
            x1 = rect(1); y1 = rect(2); x2 = rect(3); y2 = rect(4);
            sumIntensity = self.intIm(y2, x2) + self.intIm(y1, x1) - self.intIm(y1, x2) - self.intIm(y2, x1);
            sumI2 = self.intIm2(y2, x2) + self.intIm2(y1, x1) - self.intIm2(y1, x2) - self.intIm2(y2, x1);
%             rect = HypRectRounded(hypothesis); %these are general, but
%             slow because they redo same computation many times
%             a = RectArea(rect);
%             sumIntensity = RectSum(self.intIm, rect);
%             sumI2 = RectSum(self.intIm2, rect);
            
            varHyp = sumI2 / a - (sumIntensity / a)^2;
            score = (varHyp * 255^2) / self.targetVar;
            score = min(score, 1/score);
        end
        
        %TODO try filter with builtin integral image filtering code
        %or other low-level filtering stages - edge/gradient, color,
        %optical flow, grid-based variance (only 2 add/sub per rect)
        
        function [framePost] = preProc(self, framePre)
            
            framePost = double(framePre) / 255;
            self.intIm = myIntIm(framePost);
            self.intIm2 = myIntIm(framePost.^2);
        end
        
        
        function trainOut = train(self, trainData) %is trainData always a set of patches with labels? Make it a class or struct? Parser to get the frame, hypotheses, patches?
            frames = trainData{1}(trainData{2}); trainOut = [];
            getVar = @(frame) var(double(frame(:))); %mean(uint32(frame(:)).^2) - mean(frame(:))^2;
            vars = cellfun(getVar, frames);
            self.targetVar = min([vars(:); self.targetVar]);
        end
          
    end
    
end

