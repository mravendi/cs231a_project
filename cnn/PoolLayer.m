classdef PoolLayer < Layer
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here
    %maybe have this be an interface and define specific versions separately
    %one that explicitly samples each window and applies a function,
    %another based on convolution, another based on gen func like this
    
    properties
        poolFunc;
        szIm; %should be first few dimensions of szI
        szImOut;
        nDimPool;
        nDimUnpooled;
        nLast; %number of data points in last input, should store in layernet?
        szPool;
        poolStride;
    end
    
    methods
        function self = PoolLayer(szI, szIm, szPool, poolFunc, varargin) %also allow a poolStep TODO
            nvar = length(varargin);
            if (nvar > 0)
                poolStride = varargin{1};
            else
                poolStride = szPool;
            end
            
            
            self.szI = szI;
            self.szIm = szIm;
            self.nDimPool = length(szIm);
            self.nDimUnpooled = length(szI) - self.nDimPool;
            self.poolFunc = poolFunc;
            self.poolStride = poolStride;
            self.szPool = szPool;
            self.szImOut = ceil((szIm - szPool + 1) ./ poolStride);
            self.szO = [self.szImOut, self.szI(self.nDimPool+1:end)];
            self.pNames = {};
        end
        
        function [out, dOut_dPars, dO_dI] = feedSpec(self, in, varargin)
            %would like to cache indices used for reshape stuff
            in = reshape(in, prod(self.szIm), []);
            n = size(in, 2);
            self.nLast = n;
%             out = zeros(prod(self.szO), n);
            for i = 1:n
                in_i = reshape(in(:,i), self.szIm);
                [o_i] = (self.poolFunc(in_i, self.szPool, self.poolStride));
                out(:, i) = vec(o_i);% dO_dI(:,i) = vec(do_di);
            end
%             c = mat2cell(self.szO, 1, ones(1, length(self.szO))); %hacky
            c = num2cell(self.szO);
            out = reshape(out, c{:}, []);
            dOut_dPars = []; dO_dI = []; %most derivatives of output wrt input are 0, don't store
        end
        
        function [dL_dI, gStruct] = bprop(self, dL_dOut, varargin)
            gStruct = struct();
            
            dL_dO = reshape(dL_dOut, prod(self.szImOut), []);
            bp = true;
            for i = 1:self.nLast
                dl_do = reshape(dL_dO(:, i), self.szImOut);
                tmp = self.poolFunc(dl_do, self.szPool, self.poolStride, bp);
                dl_di(:, i) = vec(tmp);
            end
            sz = size(self.lastI);
            szPool = padarray(self.szPool,[0 length(sz) - length(self.szPool)], 1, 'post'); %quick fix TODO treat sizes/reshaping
            
            szRed = sz - mod(sz, szPool);
            dL_dI = reshape(dl_di, szRed);
            dL_dI = padarray(dL_dI, sz - szRed, 0, 'post');
        end
    end
    
end

