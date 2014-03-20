classdef LayerNet < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %how can we elegantly pass multiple data points at a time? keep track
    %of the number out here? Write layers that assume just one?
    properties
        layers;
        nL; %num layers
        szI;
        szO;
        parSizes;
        parVec;
        lastGrad;
        loss;
    end
    
    methods
        function [self, pars] = LayerNet(layers, lossFun)
            self.layers = layers;
            self.nL = length(layers);
            self.szI = layers{1}.szI;
            self.szO = layers{end}.szO;
            self.parSizes = self.loopPAll(@size);
            retVec = @(arr) vec(arr);
            pars = self.loopPAll(retVec);
%             keyboard
            pars = cell2mat(vec(mycellfun(@cell2mat, pars)));
            self.parVec = pars;
            self.lastGrad = zeros(numel(pars), 1);
            if nargin < 2
                lossFun = @QuadLoss; end
%                 lossFun = @(out, target) [sum(out(:)), ones(size(out(:)))]; end %what if no loss? Then just jacobian of output? Make loss a layer?
            self.loss = lossFun; 
        end
        
        function cell2 = loopPAll(self, fun)
            %should this be a non-class util function?
            %would like to do this with structfun, but ignore some
            %fields... could do it with a 'pars' struct within layer
            f1 = @(layer, pName) fun(layer.(pName));
            f2 = @(layer) vec(mycellfun(f1, repmat({layer}, size(layer.pNames)), layer.pNames));
            
            cell2 = mycellfun(f2, self.layers);
%             for i = 1:self.nL
%                 pNames = layers{i}.pNames;
%                 for j = 1:length(pNames)
%                     parSz{i}{j} = size(layers{i}.(pNames{j}));
%                 end
%             end
        end
        
        
        function out = feed(self, in, varargin)
            for i = 1:self.nL
                in = self.layers{i}.feed(in, varargin{:});
            end
            out = in;
        end
        
        function [L, grad, out] = descend(self, in, target, varargin) %rename, there is no descent here! TODO
            if ~isempty(varargin)
                self.setPars(varargin{1}); end
            out = self.feed(in);
            [L, dL_dO] = self.loss(out, target);
            if nargout > 1
                grad = self.bprop(dL_dO); end
        end
        
        %add a 'J' like that used for gradient checking, that doesn't
        %explicitly compute gradient?
        
        function [] = setPars(self, theta)
            iT = 0;
            self.parVec = theta;
            for i = 1:self.nL
                layer = self.layers{i};
                pNames = layer.pNames;
                for j = 1:length(pNames)
                    name = pNames{j};
                    n = prod(self.parSizes{i}{j}); %store these directly? Or even store index mapping?
                    pars = theta(iT + (1:n));
%                     if i == 1 && j == 1
%                         pars(:) = inf; end
                    layer.(name)(:) = pars;
                    iT = iT + n;
                end
            end
        end
                
        function [grad] = bprop(self, dL_dO, varargin)
            grad = []; %could be a bottleneck to reshape, have class func, separate func, or use structfun/cell2mat/keep the memory allocated
            for i = fliplr(1:self.nL)
                layer = self.layers{i};
                [dL_dO, gStruct] = layer.bprop(dL_dO, varargin);
                pNames = layer.pNames;
                for j = fliplr(1:length(pNames))
                    g_ij = (gStruct.(pNames{j}));
%                     if i == 1 && j == 1
%                         g_ij(:) = inf; end
                    grad = vertcat(vec(g_ij), grad);
%                 f = @(pName) vec(gStruct.(pName));
%                 grad = vertcat(cell2mat(vec(mycellfun(f, self.layers{i}.pNames))), grad);
%                 grad = vertcat(self.struct2vec(gStruct), grad);
                end
            end
        end
        
                
        function gVec = struct2vec(~, gStruct)
            structEls = struct2cell(structfun(@vec, gStruct, 'UniformOutput', 0));
            gVec = cell2mat(structEls);
        end
    end
    
end

