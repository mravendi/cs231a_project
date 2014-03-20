classdef PointwiseLayer < Layer
    
    properties
        ptwiseFunc;
    end
    
    methods
        function self = PointwiseLayer(func, szIn, varargin)
            self.szI = szIn; szOut = szIn;
            if nargin > 2
                szOut = varargin{1}; end
            self.szO = szOut;
            self.ptwiseFunc = func; %TODO check that func has right in/out?
            %TODO how to pass a function that has parameters we can modify?
            self.pNames = {};
        end
        
        function [out, dO_dP, dO_dI] = feedSpec(self, in, varargin)
            [out, dO_dP, dO_dI] = self.ptwiseFunc(in);
        end
        
        function [dL_dI, gStruct] = bprop(self, dL_dOut, varargin)
            self.lastdL_dP = struct(); %NYI parameters
            gStruct = self.lastdL_dP;
%             keyboard
            dL_dI = self.lastdO_dI .* dL_dOut;
%             [gStruct, dOut_dIn] = self.bpropSpec(gradOut, varargin{:});
%             self.lastGrad = gStruct;
        end
%         
%         function [dOut_dIn, gStruct] = bprop(self, gradOut, varargin) %NYI par update
%             gStruct = struct();                       
%             dOut_dIn = self.lastdOut;
%         end
    end
    
end

