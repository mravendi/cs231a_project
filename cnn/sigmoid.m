function [out, dO_dP, dO_dI] = sigmoid(in)
out = 1./(1+exp(-in));
dO_dI = out.*(1-out);
dO_dP = []; %could have parameters at some point... or tanh has pars
end