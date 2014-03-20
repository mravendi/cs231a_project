function [ c ] = mycellfun(f, varargin )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
c = cellfun(f, varargin{:}, 'UniformOutput', 0);

end

