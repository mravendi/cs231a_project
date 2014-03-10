function [ rect2 ] = LKTracker( img1, img2, rect)
    % img1 and img2 are separated by a small delta time
    % Bounding box rect = [XCoord1, YCoord1, XCoord2, YCoord2]
    % flowThresh is the median flow threshold
    
    seedRes = 5;            % Pixel Resolution of seed points 
    lPtle = 25;       % Lower percentile to keep
    uPtle = 75;       % Upper percentile to keep
    flowThresh = 20;        % Threshold for median flow failure

    % Construct seed pixels
    xMin = rect(1);
    yMin = rect(2);
    xMax = rect(3);
    yMax = rect(4);
    vecX = xMin:seedRes:xMax;
    vecY = yMin:seedRes:yMax;
    [p,q] = meshgrid(vecX, vecY);
    pairs = [p(:) q(:)];
    x1 = pairs(:,1);
    y1 = pairs(:,2);

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
    medianFlow = median(flow)
    if (norm(medianFlow) < flowThresh)
        rect2 = [rect(1)+medianFlow(1),rect(2)+medianFlow(2),rect(3)+medianFlow(1),rect(4)+medianFlow(2)];
    else
        display('Tracker uncertain, median flow above threshold');
        rect2 = [0,0,0,0];
    end
        


end