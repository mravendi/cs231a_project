Z = mykron(X, Y);
szZ = size(Z)
inds = [7 14 3 5];
szX = padarray(size(X), [0, ndims(Z) - ndims(X)], 1, 'post');
szY = padarray(size(Y), [0, ndims(Z) - ndims(Y)], 1, 'post');

indsX = ceil(inds ./ szY);
indsY = inds - ((indsX - 1) .* szY);
%%
at(Z, inds)
at(X, indsX) * at(Y, indsY)