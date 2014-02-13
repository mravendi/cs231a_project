classdef WindowGenerator < FilterLayer
    %based on 5.3 - scanning window grid
    properties
        baseSize;
        stepSize;
        scaleStep;
        horzStep;
        vertStep;
        minSide;
        hypList;
        lastHyps;
        lastFrameSize;
    end
    
    methods
        
        function self = WindowGenerator(baseSize) 
            %TODO pass a hyp instead, watch out for off by 1 size changes
            %esp with imcrop
            minSide = 35;
            if nargin > 0
                self.baseSize = baseSize;
            else
                self.baseSize = [minSide minSide];
            end
            
            self.scaleStep = 1.2;
            self.stepSize = 10; %how many times a window overlaps other windows in each direction (# of shifts to get to no overlap)
            %or should it be in units of pixels?
            self.horzStep = self.baseSize(2) / self.stepSize;
            self.vertStep = self.baseSize(1) / self.stepSize;
            self.minSide = min([self.baseSize, minSide]);
            self.hypList = MakeHypotheses();
            self.lastHyps = self.hypList;
            self.lastFrameSize = [];            
        end
        
        function [hypData, scores, framePost, indsGood] = filter(self, hyps, scores, framePre)
            hypData = self.getWindows(framePre);
            scores = []; 
            framePost = framePre;
            indsGood = [];
        end
        
        function hypData = getWindows(self, frame) %array of structs or struct of arrays?
            frameSz = size(frame); 
            [m, minDim] = min(self.baseSize);
            relScale = self.minSide / m;
            pow0 = floor(log(relScale) / log(self.scaleStep));
            
            scaleCurr = self.scaleStep ^ pow0;
            
            gridPars = [self.baseSize, self.vertStep, self.horzStep] * scaleCurr;
                        
            hyps = MakeHypotheses();
%             pyramid = struct('gridRows', {{}}, 'gridCols', {{}}, 'stepSize', [], 'counts', []);
            pyramid = struct();
            i = 1;
            while all(gridPars(1:2) < frameSz)
                rowsBot = round(gridPars(1):gridPars(3):frameSz(1));
                rowsTop = rowsBot - round(gridPars(1) - 1);
                colsRight = round(gridPars(2):gridPars(4):frameSz(2));
                colsLeft = colsRight - round(gridPars(2) - 1);
                grid = struct('rowsBot', rowsBot, 'rowsTop', rowsTop, 'colsRight', colsRight,...
                    'colsLeft', colsLeft, 'gridPars', gridPars, 'count', length(rowsTop)*length(colsLeft),...
                    'area', prod(round(gridPars(1:2))));
                pyramid.grids(i) = grid;
                
%                 rows = round(1:gridPars(3):frameSz(1));
%                 cols = round(1:gridPars(4):frameSz(2));
%                 
%                 [x1, y1] = meshgrid(xs, ys); x1 = x1(:); y1 = y1(:);
%                 x2 = x1 + round(gridPars(2));
%                 y2 = y1 + round(gridPars(1));
%                 hypsCurr = MakeHypotheses(x1, y1, x2, y2);
%                 hyps = AddHyps(hypsCurr, hyps);
                
                
%                 gC = round(1:gridPars(4):frameSz(2));
%                 gR = round(1:gridPars(3):frameSz(1));
%                 pyramid.gridCols{i} = gC;
%                 pyramid.gridRows{i} = gR;
%                 pyramid.stepSize{i} = self.stepSize; %can write pyramid / grid class to convert this to list of hyps?
%                 pyramid.counts(i) = length(hypsCurr);
                
                gridPars = gridPars * self.scaleStep; i = i+1;
            end
            
            hypData = struct('hyps', hyps, 'pyramid', pyramid);
            
        end
        
    end
    
end

    