function [ bestBox, bestScore ] = Integrate( boxes_detect, box_track )
    bestScore = 0;
    bestBox = [0 0 0 0];
    for i=1:length(boxes_detect)
        box_detect = boxes_detect(i);
        box_detect = [box_detect.x1 box_detect.y1 box_detect.x2 box_detect.y2];
        intersection_area = rectint(box_detect, box_track);

        area1 = box_detect(3)*box_detect(4);
        area2 = box_track(3)*box_track(4);

        score = intersection_area / (area1 + area2 -intersection_area);

        if score > bestScore
            bestBox = (box_detect + box_track) / 2;
            bestScore = score;
        end
    end
end

