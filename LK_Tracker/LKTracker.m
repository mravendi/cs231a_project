function [ rect2 ] = LKTracker( img1, img2, rect)
    % img1 and img2 are separated by a small delta time
    % Bounding box rect = [XCoord1, YCoord1, XCoord2, YCoord2]
    % flowThresh is the median flow threshold


    seedRes = 10;           % Pixel Resolution of seed points 
    lPtle = 25;             % Lower percentile to keep
    uPtle = 75;             % Upper percentile to keep
    flowThresh = 30;        % Threshold for median flow failure
    maxPtsNum = 200;         % max num corners to find
    borderTh = 10;          % Border size

    xMin = rect(1);
    yMin = rect(2);
    xMax = rect(3);
    yMax = rect(4);
    
    % Construct seed pixels
    %{
    vecX = xMin:seedRes:xMax;
    vecY = yMin:seedRes:yMax;
    [p,q] = meshgrid(vecX, vecY);
    pairs = [p(:) q(:)];
    x1 = pairs(:,1);
    y1 = pairs(:,2);
    %}
    
    % Detect Corners
    %{,
    [y1 x1] = corner_ST(img1,maxPtsNum);
    [N M] = size(img1);
	discard = y1<yMin | y1>yMax |x1<xMin | x1>xMax; % points in box
	y1 = y1(~discard);
	x1 = x1(~discard);
    %figure(1);
    %scatter(x1,y1);
    %}

    [x2, y2] = LKTrackPyr( img1, img2, x1, y1 );
    
    % Failure detection
    flow = [x2-x1, y2-y1];
    
    % Remove pixels that moved too much
    %{
    in = sqrt(sum(flow.^2,2));
    x2 = x2(in < flowThresh);
    y2 = y2(in < flowThresh);
    x1 = x1(in < flowThresh);
    y1 = y1(in < flowThresh);
    flow = [x2-x1, y2-y1];
    %}
    
    %scatter(x1,y1,'g')
    %scatter(x2,y2,'r')
    
    % Create next bounding box
    medianFlow = median(flow).*2;
    if (norm(medianFlow) < flowThresh)
        rect2 = [rect(1)+medianFlow(1),rect(2)+medianFlow(2),rect(3)+medianFlow(1),rect(4)+medianFlow(2)];
    else
        display('Tracker uncertain, median flow above threshold');
        rect2 = [0,0,0,0];
    end
        


end