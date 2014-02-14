function [im2] = DrawHighScores(im, hypotheses, scores, n)
if nargin < 4
    n = 20; end

n = min(n, length(hypotheses));
[scores2, isort] = sort(scores, 'descend');
im2 = im;
doInsert = exist('insertShape');
doInsert = false;
if ~doInsert
    imshow(im); end

for i = 1:n%round(linspace(1, length(scores), n))
    ind = isort(i);
    
    rect = BR2WH(HypRectRounded(hypotheses(ind)));
%     rect = BR2WH(HypRectRounded(hypotheses, ind));
    if doInsert
        im2 = insertShape(im2, 'rectangle', rect);
    else
        
        rectangle('Position', rect);
%         keyboard
    end
%     im2 = insertObjectAnnotation(im2, 'rectangle', rect, scores(ind));
end

end
