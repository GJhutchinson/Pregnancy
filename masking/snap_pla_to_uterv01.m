function [pos_store] = snap_pla_to_uterv01(pos_store,selected_mask,slice_n,vol_n,obj_n)

%Approximate the Uterus mask to a line ROI;
%Two hacks here; First you cannot edit the type of ROI
%something is, these values are set to read only by MATLAB. For the Uterus mask I 
%just want the exterior voxels. To get around this, load up a polyline ROI 
%(i.e. the first placental boundary) then change the position to be the 
%coordniates of the uterus mask. 
%2nd Hack, as this is a polyline it will leave it open (i.e. not connect 
%the first and last points) so start and end with the same set of points, 
%so it will connect everything together. 
uter_tmp = drawpolyline('position',[pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(1).Position;pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(1).Position(1,:)]);
uter_approx = createMask(uter_tmp);
%Then create a mask, this is a 1-voxel wide mask around the edge of the
%uterus. By doing so we can take the x+y coordinated of the exterior of the
%uterus, and find the closest point to the end of the placental mask, and
%snap the placental mask to this point. 
[ind] = find(uter_approx>0);
[y,x] = ind2sub(size(uter_approx),ind);
delete(uter_tmp)
        for roi_n = 2:size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi,2)
            for pos_n = [1 ,size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position,1)]
                pos_tmp = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(pos_n,:);
                pos_diff = sqrt(sum(([x,y] - pos_tmp).^2,2));
                [~,snap_pos] = min(pos_diff);
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(pos_n,:) = [x(snap_pos),y(snap_pos)];
            end
        end
end