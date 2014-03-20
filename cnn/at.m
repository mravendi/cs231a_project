function vals = at(arr, inds)
for i = 1:size(inds, 2)
    subs{i} = inds(:, i);
end
% keyboard;
inds = sub2ind(size(arr), subs{:});
vals = arr(inds);
end