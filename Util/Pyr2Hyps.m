function hyps = Pyr2Hyps(p, indsGood)
if islogical(indsGood)
    indsGood = find(indsGood); end
countMin = 1;
hyps = MakeHypotheses();
for i = 1:length(p.grids)
    grid = p.grids(i);
    countMax = countMin + grid.count - 1;
    i2 = find(indsGood <= countMax & indsGood >= countMin);
    inds = indsGood(i2) - countMin + 1;
    hypsi = Grid2Hyps(grid, inds);
%     keyboard
    hyps = vertcat(hyps, hypsi(:));
    countMin = countMax + 1;
end
end