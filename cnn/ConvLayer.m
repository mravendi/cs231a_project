classdef ConvLayer < Layer %also like a LinearTransLayer?
    %also generalize to tensor convolution?
    %for now we assume 2D images/maps: sz(input) = [height, width, nMaps,
    %nSamples]
    properties
        nFilt;
        filtSize;
%         filtScale;
        nI; %number of input maps
        nO; %number of output maps
        b; %biases
        filts; %should each filter be applied to each input map? Probably not, at least for some layers
%         %control that explicitly or with 'blends'?
%         blends; %blend of filter outputs for num output maps
% for now we'll have separate blending layer, fully represent map/filter
% combos here
    end
    
    methods
        function self = ConvLayer(szI, nFilt, filtSize, varargin) %TODO pass nFilt etc separately?
            if length(szI) < 3
                szI(3) = 1; end
            self.szI = szI; %heightxwidthxnum maps
            szI(1:2) = szI(1:2) - filtSize + 1;
            szO = [szI, nFilt];
            self.szO = szO;
            self.nI = szI(end);
            self.nO = szO(end);
            self.nFilt = nFilt;
            self.filtSize = filtSize;
            self.filts = randn([filtSize, nFilt]);
            self.b = randn(nFilt,1)*1e-1;
%             filtScale = 1e-1; %from ufldl tutorial, makes sense why?
            filtScale = 1/prod(filtSize);
            self.filts = self.filts * filtScale;
            self.pNames = strsplit('filts b');
%             self.blends = randn([self.nO, self.nI, self.nFilt]);
        end
        
        function [O, dO_dP, dO_dI] = feedSpec(self, in, varargin)
            nData = size(in, 4);
            O = zeros([self.szO, nData]);
            for i = 1:self.nFilt
                filt = rot90(self.filts(:,:,i), 2);
                %add bias??? reshape to 4d?
                %option to do 'same' or 'full'?
                o = convn(in, filt, 'valid'); % y,x, input map, filter index, datapoint index
%                 keyboard

  
                O(:,:,:,i,:) = o + self.b(i);
                dO_dP = []; %would just be the inputs moved around... size(O) * size(filters)
                dO_dI = []; %would just be the filter moved around... size(O) * size(I)
            end
            
%             for iOut = 1:nO
%                 blend = (self.blends(i,:,:));
%                 for iIn = 1:size(blend, 2)
%                     for iFilt = 1:size(blend,3)
%                         O(:,:,iOut) = O(:,:,iOut) + self.convResults(:,:,iIn,iFilt) * blends(iOut, iIn, iFilt);
%                     end
%                 end
%             end
%             [O, dO_dP, dOut_dIn] = self.feedSpec(in, varargin{:});
%             self.lastO = O; self.lastdO_dP = dO_dP; self.lastdO_dI = dOut_dIn; %or have no return, directly assign this stuff
        end
        
        function [dL_dI, gStruct] = bprop(self, dL_dOut, varargin)
            dL_dI = zeros(size(self.lastI));
            for i = 1:self.nFilt
                filt = rot90(self.filts(:,:,i), 2); 
                
%                 O(:,:,:,i,:) = convn(in, filt, 'valid'); % y,x, input map, filter index, datapoint index
%           do I need to rotate the input or output below???
                deltOut = dL_dOut(:,:,:,i,:); 
                lastI = self.lastI;
                deltOut = squeeze(deltOut); lastI = squeeze(lastI); %hack, may not always work if dims don't line up right?
                %also supposed to rotate deltOut instead of filt
                szD = size(deltOut); szI = size(lastI);
                dL_dI(:) = dL_dI(:) + vec(convn(deltOut, filt, 'full'));
                
                for j = 1:ndims(deltOut)
                    deltOut = flipdim(deltOut, j); %flip for convolution, is this right?
                end
                delta = convn(lastI, deltOut, 'valid');
%                 keyboard
                dL_dP.filts(:,:,i) = delta;
                dL_dP.b(i) = sum(deltOut(:));
                
            end
%             keyboard
            self.lastdL_dP = dL_dP; gStruct = dL_dP;
        end
            
    end
    
end

