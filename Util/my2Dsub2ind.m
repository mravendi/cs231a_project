function inds = my2Dsub2ind(sz, rows, cols)
inds = rows + (cols-1) * sz(1);
end