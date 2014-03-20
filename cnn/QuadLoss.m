function [ L, dL_dO ] = QuadLoss(out, target ) %could be weighted?
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
% keyboard
r = (out - target);
L = sum(vec(r.^2));
dL_dO = 2*r;

end

