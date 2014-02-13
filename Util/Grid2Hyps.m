function hyps = Grid2Hyps(grid, inds)
[rInds, cInds] = ind2sub([length(grid.rowsBot), length(grid.colsRight)], inds);
y1 = grid.rowsTop(rInds); y2 = grid.rowsBot(rInds);
x1 = grid.colsLeft(cInds); x2 = grid.colsRight(cInds);
hyps = MakeHypotheses(x1, y1, x2, y2);

end