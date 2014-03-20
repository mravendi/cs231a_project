classdef Layer < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % abbreviations: I = Input to this layer, O = output of this layer, P =
    % pars of this layer, L = loss of network 
    % TODO help make it generalize to multiple input samples, for now just
    % works on one - will that speed it up???
    % or we can define layers by the way they change dimensionality (szI to
    % szO)
    %strategy for reshaping to appropriate size? Each layer does its own?
    %Assume they'll just be the right size?
    properties
        szI;
        szO;
        pNames;
        %want to keep these pars to preserve memory, avoid lots of
        %reallocation of same size - but does it work? TODO
        %add bias par? is this always useful?
        lastI; %get rid of 'last'?
        lastO;
        lastdO_dI;
        lastdO_dP;
        lastdL_dP;
    end
    
    methods
        %TODO look into tools for input parsing and validation
%         function self = Layer(szIn, szOut)
%             self.szI = szIn;
%             self.szO = szOut;
%         end
        %have these do general parsing (varargin might replace lastIn/out,
        %etc) and set things that always need to be set, but then we need
        %more specific methods to be called by them that will be customized
        %TODO don't calc or return derivatives if we pass a flag not to
        %also should call special functions for reshaping input? Or just a
        %'storeResults' func somewhere with optional flags
        function [out, dOut_dPars] = feed(self, in, varargin)
            self.lastI = in;
            [out, dOut_dPars, dOut_dIn] = self.feedSpec(in, varargin{:});
            self.lastO = out; self.lastdO_dP = dOut_dPars; self.lastdO_dI = dOut_dIn; %or have no return, directly assign this stuff
        end
        
        function [dL_dI, gStruct] = bprop(self, dL_dOut, varargin)
            %TODO make sure the dL etc are the right shape for chain rule
            for name = self.pNames
                %expect dX_dY has size [size(Y), size(X)]
                self.lastdL_dP.name = self.lastdO_dP * dL_dOut;
            end
            gStruct = self.lastdL_dP;
%             keyboard
            dL_dI = self.lastdO_dI * dL_dOut;
%             [gStruct, dOut_dIn] = self.bpropSpec(gradOut, varargin{:});
%             self.lastGrad = gStruct;
        end
        
    end
    
end

