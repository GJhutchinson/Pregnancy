function [uter_side] = find_uter_outline(mask)


[B,L] = bwboundaries(logical(mask));
tol_uter_line = 0.005;
[~,max_idx] = max(cellfun(@length,B));
outside_poly = reducepoly(B{max_idx},tol_uter_line);
