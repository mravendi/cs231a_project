
function sampled = recSampleGrid(arr, gridInds, szSampled) %probably better to convert to linear indices, or just big switch case thing

n = length(gridInds);

if n == 2
    sampled = arr(gridInds{1}, gridInds{2});
else
    % sampled = zeros(szSampled);
    sampled = [];
    subSz = size(arr); subSz(1) = []; %szSampled(2:end);
    for i = 1:szSampled(1)
        arr_i = arr(gridInds{1}(i), :);  
%         keyboard
        arr_i = reshape(arr_i, subSz);
        samp_i = recSampleGrid(arr_i, gridInds(2:end), szSampled(2:end)); %cat or turn into 1D and then reshape (known sizes)
        sampled = cat(1, sampled, reshape(samp_i, [1 size(samp_i)]));
    end
end
end