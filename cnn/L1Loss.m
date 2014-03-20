function [ L, dL_dO ] = L1Loss(out, target ) %could be weighted?
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
% keyboard
r = (out - target);
L = sum(vec(abs(r)));
dL_dO = sign(r);

end