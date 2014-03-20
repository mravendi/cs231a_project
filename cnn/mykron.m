function prod = mykron(Y,X)
ndX = ndims(X); ndY = ndims(Y);
% if ndX <= 2 && ndY <= 2
%     prod = kron(X,Y); return;
% end
nD = max(ndX, ndY); nDm = min(ndX, ndY);
szX = size(X); szY = size(Y); 
if szX < nD
    szX(end+1:nD) = 1; end
if szY < nD
    szY(end+1:nD) = 1; end
szP = szX.*szY;

szX = vec(vertcat(szX, ones(1, nD)));
szY = vec(vertcat(ones(1, nD), szY));
X = reshape(X, szX'); Y = reshape(Y, szY');
K = bsxfun(@times, X, Y);
prod = reshape(K, szP);


% prod = zeros(szP);
% prod = X(:) * Y(:)';
% prod = reshape(prod, szP);
end