function [pla_side,uter_side,pla_side_l,flip_ID] = ML_to_sides(mask)

% %    Start from the mask
% mask_tmp = mask(:,:,slice_n,vol_n);

%Take the outline of the entire mask
[B,L] = bwboundaries(logical(mask));

entire_outline = B{1};

pla_outline = mask==2;
uter_outline = mask==1;
pla_line = edge(pla_outline).*edge(uter_outline);

CC = bwconncomp(pla_line);
[~,idx] = max(cellfun(@length,CC.PixelIdxList));
pla_line_idx = CC.PixelIdxList{idx};

pla_line = zeros(size(pla_line));
pla_line(pla_line_idx) = 1;

%The main issue here is trying to obtain the chorionic plate/fetal side of
%the placenta line; with all the points in order. To do this:
%Edge point is closest to the outside of the mask
idx = find(pla_line);
[y_pla,x_pla] = ind2sub(size(pla_line),idx);

%Doesn't need to be every voxel? Update this line
idx = find(~L);
[y_out,x_out] = ind2sub(size(L),idx);

for n_x = 1:length(x_pla)
    dist(n_x) = min(sqrt( (x_pla(n_x)-x_out).^2 + (y_pla(n_x)-y_out).^2));
end

%Find closest voxel to the outside of the mask
[~,min_idx] = min(dist);
%This is the first point
pla_order = [y_pla(min_idx) x_pla(min_idx)];
%Remove from array
x_pla(min_idx) = []; y_pla(min_idx) = [];

%Iterate through finding the closest next voxel, add it to the ordered list
%and remove from the array, this way you can connect all the points
%together. If there are two equidistant points it should be smoothed out by
%reducepoly later on; so do not need to take this into account.
while length(x_pla)>0
    min_idx = dsearchn([y_pla x_pla],pla_order(end,:));
    pla_order(end+1,:) = [y_pla(min_idx) x_pla(min_idx)];
    x_pla(min_idx) = [];
    y_pla(min_idx) = [];
end

%Reduce poly
tol_pla_line = 0.0075;
pla_side_l = reducepoly(pla_order,tol_pla_line);

%Extend point to edge of mask by finding nearest to B; taking only the
%alrgest object in B to ensure only single tuerus mask

%Approximate the outside of the uterus to poly points; using B (the list of
%exterior points).
tol_uter_line = 0.005;
[~,max_idx] = max(cellfun(@length,B));
outside_poly = reducepoly(B{max_idx},tol_uter_line);


%Convert into ROI to get list of points to check against

%Make an invisible figure to do operations on the ROI
f1 = figure('visible','off');
%Image the entire uterus mask
imagesc(L);
%Draw outside line ROI
uter_tmp = drawpolyline('Position',[outside_poly(:,2) outside_poly(:,1)]);
%Convert to a mask 
uter_approx = createMask(uter_tmp);
%Find these points
[ind] = find(uter_approx>0);
%Convert to x/y coords
[y,x] = ind2sub(size(uter_approx),ind);
%close invisible figure and delete the ROI
delete(uter_tmp)
close(f1)

%Now we have x and y; which are a list of the outside coordinates of the
%mask (non-approx. i.e. all the edge points). We need to find where the
%placenta line we calculated earlier fits into these points. Do this by
%finding the closest uterus edge point (x,y) to the start and end of the
%placenta line (pla_order(1) pla_order(end)); and then add these points to pla_order to 
%ensure it snaps to the uterus outline

for pos_n = [1 length(pla_order)]
    idx = dsearchn([y x],pla_order(pos_n,:));
    if pos_n == 1
        pla_order = [[y(idx) x(idx)];pla_order];
    else
        pla_order = [pla_order; [y(idx) x(idx)]];
    end
end
%Theres a good chance we copy the end or start point twice; if the mask
%ends on the exterior of the uterus (which is reasonbly common). Only take
%unique values
pla_order = unique(pla_order,'rows','stable');


%Now pla order is in order and is snapped to the uterus line: 

%Need to 'complete' the placental mask since it is only a line
c = 1;
for pos_n = [1 ,length(pla_order)]
    pos_tmp = pla_order(pos_n,:);
    uterus_pos_tmp = [outside_poly];

    for uterus_roi_n = 1:size(uterus_pos_tmp,1)-1
        %So there's a problem that needs solving here; We have
        %the Uterus outline and the line that describes the
        %placenta and divides this mask in two... Where in the
        %list of uterus points does the placental mask lie? I
        %couldn't think of an easy/obvious method for this.
        %Since we know that the first and last placental ROI
        %points lie along the uterus mask, we need to find
        %where to insert them. To do this search every uterus
        %mask point to see if either the first or last
        %placental mask locations is imbetween it and its
        %neighbour. Do this by drawing a polygon around the
        %points and using inpolygon to see if the point lies
        %within.


        min_x = floor(min([uterus_pos_tmp(uterus_roi_n,1) uterus_pos_tmp(uterus_roi_n+1,1)]));
        max_x = ceil(max([uterus_pos_tmp(uterus_roi_n,1) uterus_pos_tmp(uterus_roi_n+1,1)]));
        min_y = floor(min([uterus_pos_tmp(uterus_roi_n,2) uterus_pos_tmp(uterus_roi_n+1,2)]));
        max_y = ceil(max([uterus_pos_tmp(uterus_roi_n,2) uterus_pos_tmp(uterus_roi_n+1,2)]));


        x_coords =[min_x min_x max_x max_x];
        y_coords = [min_y max_y max_y min_y];

        %Is the placental point between neighbouring points
        bool_check = inpolygon(pos_tmp(1),pos_tmp(2),x_coords,y_coords);

        if bool_check == 1
            pla_intersect(c) = uterus_roi_n;
            c = c+1;
            break
        end
    end
end

if pla_intersect(2)>pla_intersect(1)
    no_wrap_tmp = [pla_order(1,:);uterus_pos_tmp([pla_intersect(1)+1:pla_intersect(2)],:) ;pla_order(end,:)];
    wrap_tmp = [pla_order(1,:);uterus_pos_tmp([flip(1:pla_intersect(1)),flip(pla_intersect(2)+1:size(uterus_pos_tmp,1))],:);pla_order(end,:)];
else
    no_wrap_tmp = [pla_order(1,:);uterus_pos_tmp(flip([pla_intersect(2)+1:pla_intersect(1)]),:);pla_order(end,:)];
    wrap_tmp = [pla_order(1,:);flip(uterus_pos_tmp([flip(1:pla_intersect(2)), flip(pla_intersect(1)+1:size(uterus_pos_tmp,1))],:));pla_order(end,:)];
end

%Just take edge voxels
pla_edge = edge(pla_outline).*~edge(uter_outline);

idx = find(pla_edge);
[y,x] = ind2sub(size(pla_edge),idx);

% plot(x,y,'x')

dist_wrap = sum(sqrt(sum((wrap_tmp(2:end,:)-wrap_tmp(1:end-1,:)).^2,2)));
dist_no_wrap = sum(sqrt(sum((no_wrap_tmp(2:end,:)-no_wrap_tmp(1:end-1,:)).^2,2)));

%Because we have the mask we can determine which side is placental bed
%area, and which is remaining uterus. The placental bed area will be near
%more '2' mask values, and uterus area near more '1' mask values. 
wrap_idx = sub2ind(size(mask),wrap_tmp(:,1),wrap_tmp(:,2));
no_wrap_idx = sub2ind(size(mask),no_wrap_tmp(:,1),no_wrap_tmp(:,2));


%If wrap_idx is larger
if mean(mask(wrap_idx)) > mean(mask(no_wrap_idx))
    %Then wrap_idx is placental bed
    pla_side = wrap_tmp;
    uter_side = no_wrap_tmp;
    %Assign flip ID based on distances
    if dist_wrap>dist_no_wrap;
        flip_ID = 2;
    else 
        flip_ID = 1;
    end
else %Else no_wrap is placental bed
    pla_side = no_wrap_tmp;
    uter_side = wrap_tmp;
    %Assign flip_ID
    if dist_no_wrap>dist_wrap
        flip_ID = 2;
    else
        flip_ID = 1;
    end
end

%pla_side - placental bed outline reduced
%uter_side - Uterus outline reduced
%pla_side_l - diving line


%For the masking programme we need an entire uterus outline; in order for
%the plotting; ensure that pla_side and uter_side can be combined


dist_points = sqrt(sum(([pla_side(1,2) pla_side(1,1)] - [uter_side(:,2) uter_side(:,1)]).^2,2));

if dist_points(1)<dist_points(end)
    uter_side = flip(uter_side);
end