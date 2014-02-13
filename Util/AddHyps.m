
function hyps = AddHyps(hyps1, hyps2)
hyps = vertcat(hyps1, hyps2);  %array of struct
return;

%struct of arrays
hyps = hyps1;
fnames = fieldnames(hyps);
for i = 1:length(fnames)
    fname = fnames{i};
    hyps.(fname) = vertcat(hyps.(fname), hyps2.(fname));
end
end
