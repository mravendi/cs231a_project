function resized = myimresize(patch, szOut, tolerances)
if nargin < 3
    tolerances = [0 0]; end
resized = patch;
sz = size(resized); sz = sz(1:2);
delta = sz - szOut;
if any(delta < tolerances(1) | delta > tolerances(2))
    sampr = round(linspace(1, sz(1), szOut(1)));
    sampc = round(linspace(1, sz(2), szOut(2)));
    resized = resized(sampr, sampc, :);
    %                 resized = imresize(resized, self.patchSize);
end
end