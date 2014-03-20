function [O, dO_dP, dO_dI] = mysoftsign(I)
t1 = I;
t2 = 1./(1+abs(I));
O = t1.*t2;
dO_dP = [];
dO_dI = t2 + (-t1 .* t2.^2 .* sign(I));
end