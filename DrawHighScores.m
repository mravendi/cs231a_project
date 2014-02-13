function [im2] = DrawHighScores(im, hypotheses, scores, n)
if nargin < 4
    n = 20; end

n = min(n, length(hypotheses));
[scores2, isort] = sort(scores, 'descend');
im2 = im;
for i = 1:n%round(linspace(1, length(scores), n))
    ind = isort(i);
    
    rect = BR2WH(HypRectRounded(hypotheses(ind)));
%     rect = BR2WH(HypRectRounded(hypotheses, ind));
    im2 = insertShape(im2, 'rectangle', rect);
%     im2 = insertObjectAnnotation(im2, 'rectangle', rect, scores(ind));
end

end
