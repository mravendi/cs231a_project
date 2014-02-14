% show the usage of LKTrackWrapper
clear
close all

%% image sequences
%{,

% Open image
fn = '../TLD_source/_input/00%2.3d.png';
imgNum = 10;
img1 = imread(sprintf(fn,1));

% Select seed bounding box
imshow(img1);
title('Drag to select seed bounding box & press ENTER');
rect = getrect;
xMin = rect(1);
yMin = rect(2);
xMax = rect(1) + rect(3);
yMax = rect(2) + rect(4);

% Construct seed pixels
res = 5;
x = [];
y = [];
for i = xMin:res:xMax
   for j = yMin:res:yMax
       x = [x;i];
       y = [y;j];
   end
end

[M N C] = size(img1);
imgseq = zeros(M,N,imgNum);
for p = 1:imgNum
	img = im2double(imread(sprintf(fn,p)));
	if C == 3, img = rgb2gray(img); end
	imgseq(:,:,p) = img;
end

LKTrackWrapper(imgseq, x, y);
%}

%% video
%{
obj = VideoReader('data\wc.wmv');
vid = obj.read;
[M N C imgNum] = size(vid);
imgNum = min(imgNum,80);
imgseq = zeros(M,N,imgNum);
for p = 1:imgNum
	img1 = im2double(vid(:,:,:,p));
	if C == 3, img1 = rgb2gray(img1); end
	imgseq(:,:,p) = img1;
end

LKTrackWrapper(imgseq);
%}

