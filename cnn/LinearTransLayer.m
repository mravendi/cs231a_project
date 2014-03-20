classdef LinearTransLayer < Layer
    %can actually combine with the convolution layer, same idea except
    %each kernel/filter is the same size as the input
    properties
        W; %transformation matrix, TODO generalize to tensor with weights for input layers?
        b; %bias
    end
    
    methods
        function self = LinearTransLayer(szI, szO)
            self.szI = szI; self.szO = szO;
            
            self.W = (rand([prod(szO), prod(szI)]) * 2 - 1);
            scaleW = sqrt(6) / sqrt(sum(size(self.W))); scaleB = 0;%from ufldl tutorial - why start with 0 bias?
            self.W = self.W * scaleW;
            
            self.b = randn(prod(szO), 1) * scaleB;
            
            self.pNames = {'W', 'b'};
        end
        
        function [O, dO_dP, dO_dI] = feedSpec(self, in, varargin)
            
            I = reshape(in, prod(self.szI), []);
            O = bsxfun(@plus, self.W * I, self.b);
            dO_dI = self.W';
            dO_dP = struct(); %don't need to store these, redundant
            
        end
        
        function [dL_dI, gStruct] = bprop(self, dL_dO, varargin)
            dL_dO = reshape(dL_dO, prod(self.szO), []);
            
            lastI = reshape(self.lastI, prod(self.szI), []);
%             keyboard
            self.lastdL_dP.W = dL_dO * lastI';
            self.lastdL_dP.b = sum(dL_dO, 2); %sum or mean for this and above?
            gStruct = self.lastdL_dP;
            dL_dI = self.W' * dL_dO;
%             [gStruct, dOut_dIn] = self.bpropSpec(gradOut, varargin{:});
%             self.lastGrad = gStruct;
        end
    end
    
end

