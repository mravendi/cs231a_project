% Lucas Kanade tracker for TLD

clear all
close all

% Initialize parameters
imgPath = '../TLD_source/_input/00%2.3d.png';
numImgs = 20;           % Number of images to track
seedRes = 5;            % Pixel Resolution of seed points 
lowerPrctle = 10;       % Lower percentile to keep
upperPrctle = 90;       % Upper percentile to keep

% Display first image and select seed bounding box
img1 = imread(sprintf(imgPath,1));
[M N C] = size(img1);
imshow(img1);
title('Drag to select seed bounding box');
rect = getrect;
xMin = rect(1);
yMin = rect(2);
xMax = rect(1) + rect(3);
yMax = rect(2) + rect(4);

% Construct seed pixels
x1 = [];
y1 = [];
for i = xMin:seedRes:xMax
   for j = yMin:seedRes:yMax
       x1 = [x1;i];
       y1 = [y1;j];
   end
end

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
    [x2, y2] = LKTrackPyr( img1, img2, x1, y1 );
    
    % Show the image, and tracked points
    %if nargout == 0
        % show the points
		imshow(img1); hold on;
		plot(x1,y1,'go');
        plot(x2,y2,'ro');
        %plot([x1,x2]',[y1,y2]','m-');
        pause
	%end
    
    % Construct next bounding box
    xp = prctile(x2,[lowerPrctle upperPrctle]);
    yp = prctile(y2,[lowerPrctle upperPrctle]);
    x1 = []; y1 = [];
    for i = xp(1):seedRes:xp(2)
        for j = yp(1):seedRes:yp(2)
            x1 = [x1;i];
            y1 = [y1;j];
        end
    end
    
end
    