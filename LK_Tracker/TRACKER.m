% Lucas Kanade tracker for TLD

clear all
close all

% Initialize parameters
imgPath = '../TLD_source/_input/00%2.3d.png';
numImgs = 20;           % Number of images to track
seedRes = 5;            % Pixel Resolution of seed points 
lPtle = 10;       % Lower percentile to keep
uPtle = 90;       % Upper percentile to keep
flowThresh = 20;        % Threshold for median flow failure

% Display first image and select seed bounding box
img1 = imread(sprintf(imgPath,1));
[M N C] = size(img1);
imshow(img1);
title('Drag to select seed bounding box');
rect1 = getrect;

% Tracking loop
for i = 1:numImgs-1
    % Read the images, and convert to grayscale if color
    img1 = im2double(imread(sprintf(imgPath,i)));
    img2 = im2double(imread(sprintf(imgPath,i+1)));
    if C == 3 
        img1 = rgb2gray(img1); 
        img2 = rgb2gray(img2); 
    end
    
    % Track
    [ rect2 ] = LKTracker( img1, img2, rect1, flowThresh, seedRes, lPtle, uPtle);
    imshow(img1); hold on;
    rectangle('position',rect1, 'LineWidth',1, 'EdgeColor','g');
    rectangle('position',rect2, 'LineWidth',1, 'EdgeColor','r');   
    pause;
    rect1 = rect2;    
    
end
    