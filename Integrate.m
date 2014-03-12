function [ bestBox, bestScore, idx ] = Integrate( boxes_detect, box_track )
    bestScore = 0;
    bestBox = [0 0 0 0];
    idx = 0;
    for i=1:length(boxes_detect)
        box_detect = boxes_detect(i);
        box_detect = [box_detect.x1 box_detect.y1 box_detect.x2 box_detect.y2];
        intersection_area = rectint(BR2WH(box_detect), BR2WH(box_track));

        area1 = (box_detect(3)-box_detect(1))*(box_detect(4)-box_detect(2));
        area2 = (box_track(3)-box_track(1))*(box_track(4)-box_track(2));

        score = intersection_area / (area1 + area2 -intersection_area);
        
        if score > bestScore
            bestBox = (box_detect + box_track) / 2;
            bestBox_mid = [((bestBox(1)+bestBox(3))/2) ((bestBox(2)+bestBox(4))/2)];
            width_height = box_detect(3:4) - box_detect(1:2);
            width_height = width_height / 3;
            bestBox = [(bestBox_mid(1)-width_height(1)) (bestBox_mid(2)-width_height(2)) (bestBox_mid(1)+width_height(1)) (bestBox_mid(2)+width_height(2))];
            bestScore = score;
            idx = i;
        end
    end
end

