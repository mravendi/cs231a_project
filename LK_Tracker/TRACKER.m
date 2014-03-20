% Lucas Kanade tracker for TLD

clear all
close all

% Initialize parameters
imgPath = '../TLD_source/_input/00%2.3d.png';
numImgs = 20;           % Number of images to track

% Display first image and select seed bounding box
img1 = imread(sprintf(imgPath,1));
[M N C] = size(img1);
imshow(img1);
title('Drag to select seed bounding box');
rect = getrect;
rect1 = [rect(1), rect(2), rect(1) + rect(3), rect(2) + rect(4)];

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
    [ rect2 ] = LKTracker( img1, img2, rect1); pause;
    if (all(rect2) == 0)
        break;
    end
    display(i);
    figure(1);
    imshow(img1); hold on;
    r1 = [rect1(1), rect1(2), rect1(3)-rect1(1), rect1(4)-rect1(2)];
    r2 = [rect2(1), rect2(2), rect2(3)-rect2(1), rect2(4)-rect2(2)];
    rectangle('position',r1, 'LineWidth',1, 'EdgeColor','g');
    rectangle('position',r2, 'LineWidth',1, 'EdgeColor','r');   
    pause;
    rect1 = rect2;    
    
end
    