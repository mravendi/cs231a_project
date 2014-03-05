function [ rect2 ] = LKTracker( img1, img2, rect, flowThresh ,seedRes, lPtle, uPtle)
    % img1 and img2 are separated by a small delta time
    % Bounding box rect = [XCoordinate, YCoordinate, width, height]
    % flowThresh is the median flow threshold

    % Construct seed pixels
    xMin = rect(1);
    yMin = rect(2);
    xMax = rect(1) + rect(3);
    yMax = rect(2) + rect(4);
    vecX = xMin:seedRes:xMax;
    vecY = yMin:seedRes:yMax;
    [p,q] = meshgrid(vecX, vecY);
    pairs = [p(:) q(:)];
    x1 = pairs(:,1);
    y1 = pairs(:,2);

    [x2, y2] = LKTrackPyr( img1, img2, x1, y1 );
    
    % Failure detection
    medianFlow = [median(x2)-median(x1), median(y2)-median(y1)];
    if (norm(medianFlow) < flowThresh)
        % Remove pixels that moved too much
        flow = [x2-x1, y2-y1];
        in = sqrt(sum(flow.^2,2));
        x2 = x2(in < flowThresh);
        y2 = y2(in < flowThresh);
    else
        x2 = [];
        y2 = [];
        display('Tracker failed, median flow above threshold');
    end
        
    % Construct next bounding box
    xp = prctile(x2,[lPtle uPtle]);
    yp = prctile(y2,[lPtle uPtle]);
    rect2 = [xp(1), yp(1), xp(2)-xp(1), yp(2)-yp(1)];

end