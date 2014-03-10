function [ patches ] = N_Expert( g, cascade_candidates, best_box )
    patches = {};
    for i=1:length(cascade_candidates)
        cc = cascade_candidates(i);
        cc = [cc.x1 cc.y1 cc.x2 cc.y2];
        intersection_area = rectint(cc, best_box);

        area1 = cc(3)*cc(4);
        area2 = best_box(3)*best_box(4);

        score = intersection_area / (area1 + area2 - intersection_area);

        if score < 0.2
            % add to negative labels!
            patches{end+1} = imcrop(g, BR2WH(cc));
        end
    end
end

