function [patches] = WarpHyp(frame, hyp)
%see 5.6.1
%this is similar, but we take 9 boxes (original, and shifted neighbors);
if size(frame, 3) == 3
    frame = rgb2gray(frame); end

pars.shift = .01;
pars.scale = .01;
pars.rot = 10;
pars.noise = 5;

rect0 = BR2WH(HypRectRounded(hyp));
w = rect0(3); h = rect0(4);
dX = .1 * w;
dY = .1 * h;
offsets = combvec([-1 0 1], [-1 0 1])'; %9x2

nRects = size(offsets, 1);
nWarps = 20;

offsets = bsxfun(@times, offsets, [dX, dY]);
rectCorners = bsxfun(@plus, rect0(1:2), offsets);
rects = [rectCorners, repmat(rect0(3:4), nRects, 1)];

patches = {};
for i = 1:nRects
    rect = rects(i, :);
    [crop, rect2] = CropCentered(frame, rect);
    rect2 = round(rect2);
    for j = 1:nWarps
        w = WarpCrop(crop, pars);
        
        %         imshow(w);
%         imshow(crop);
%         pause
        p = imcrop(w, rect2);
%         if ~all(size(p) == [33 35])
%             keyboard; end
        if any(size(p) - rect2([4 3]) - 1)
            continue; end %probably at an image boundary
        patches = vertcat(patches, {p});
    end
end
end


function [crop, rect2] = CropCentered(frame, rect)
    ctr = rect(1:2) + rect(3:4) / 2;
    side = max(rect(3:4)) + min(rect(3:4)) / 3;
    cropBox = [ctr - side / 2, side, side];
    crop = imcrop(frame, cropBox);
    rect2 = [rect(1:2) - cropBox(1:2), rect(3:4)];
end


function warp = WarpCrop(crop, pars)
% warp by geometric transformations (shift 1%, scale change 1%,
% in-plane rotation 10
% ) and add them with Gaussian noise
% ( = 5) on pixels.
shiftX = rand(1) * pars.shift * size(crop, 2);
shiftY = rand(1) * pars.shift * size(crop, 1);
scale = randn(1) * pars.scale + 1;
rot = randn(1) * pars.rot;


iX = round(1:size(crop, 2) + shiftX);
iX(iX < 1 | iX > size(crop, 2)) = [];

iY = round(1:size(crop, 1) + shiftY);
iY(iY < 1 | iY > size(crop, 1)) = [];

warp = crop(iY, iX);
warp = imresize(warp, scale);
warp = imrotate(warp, rot, 'nearest', 'crop');
warp = double(warp) + randn(size(warp)) * pars.noise;
warp = uint8(warp);
end
