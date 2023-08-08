function [pla_roi] = partition_placentav03(pos_store,slice_n,vol_n,selected_mask,uter_ID,pla_roi)


n_pla = 0;
%For all objects
for obj_n = 1:size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object,2)
    %If the object is a uterus pla combination mask
    if pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).type == 3;
        %Need to 'complete' the placental mask since it is only a line
        for roi_n = 2:size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi,2)
            n_pla = n_pla+1;
            c = 1;
            for pos_n = [1 ,size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position,1)]
                pos_tmp = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(pos_n,:);
                uterus_pos_tmp = [pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).roi(1).Position; pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).roi(1).Position(1,:)];

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
            
            %Find distance from placental intersect to ROI; needs to be
            %done to know which way round the ROI's are
            
            
            
            
            %Now need to recalculate the placental ROI, including the
            %uterine mask for the placenta. To do this look at the lengths
            %of the uterus segments, and assume the shortest is the correct
            %one. 
            

            if pla_intersect(2)>pla_intersect(1)
                no_wrap_tmp = [pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(1,:);uterus_pos_tmp([pla_intersect(1)+1:pla_intersect(2)],:) ; pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(end,:) ];
                wrap_tmp = [pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(1,:);uterus_pos_tmp([flip(1:pla_intersect(1)),flip(pla_intersect(2)+1:size(uterus_pos_tmp,1))],:);pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(end,:)];
            else
                no_wrap_tmp = [pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(1,:);uterus_pos_tmp(flip([pla_intersect(2)+1:pla_intersect(1)]),:);pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(end,:)];
                wrap_tmp = [pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(1,:);flip(uterus_pos_tmp([flip(1:pla_intersect(2)), flip(pla_intersect(1)+1:size(uterus_pos_tmp,1))],:));pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position(end,:)];
            end

           %Figure out where the placenta mask started from 
           
           
            no_wrap_l{n_pla} = sum(sqrt(sum(((no_wrap_tmp(2:end,:)-no_wrap_tmp(1:end-1,:)).^2),2)));
            wrap_l{n_pla} = sum(sqrt(sum(((wrap_tmp(2:end,:)-wrap_tmp(1:end-1,:)).^2),2)));

           
            no_wrap{n_pla} = no_wrap_tmp;
            wrap{n_pla} = wrap_tmp;
            
            if roi_n == 2 %For the first pla ROI save the uterus length
                pla_roi.slice(slice_n).volume(vol_n).uter_length = no_wrap_l{n_pla} + wrap_l{n_pla};
            end

            
            %Now save outputs depending on supplied uter_ID
            
            %Uter ID works to detect which ROI should be the larger ROI I
            %assume this can only happen once so here are the ID codes:
            % 1 = take smallest ROI's everywhere
            % 2 = 1st placenta ROI is largest length
            % 3 = 2nd placenta ROI is largest length
            % and so on
            
            
            if  n_pla+1 ~= uter_ID
                if no_wrap_l{n_pla}<wrap_l{n_pla}
                    if pla_intersect(2)>pla_intersect(1)
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [no_wrap_tmp(1:end,:);flip((pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position))];
                    else
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [no_wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    end
                    roi.slice(slice_n).volume(vol_n).length{n_pla} = no_wrap_l;
                    pla_roi.slice(slice_n).volume(vol_n).type{n_pla} = 'no_wrap';
                else
                    if pla_intersect(2)>pla_intersect(1)
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    else
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    end
                    pla_roi.slice(slice_n).volume(vol_n).length{n_pla} = wrap_l;
                    pla_roi.slice(slice_n).volume(vol_n).type{n_pla} = 'wrap';
                end
            elseif n_pla+1 == uter_ID
                if no_wrap_l{n_pla}>wrap_l{n_pla}
                    if pla_intersect(2)>pla_intersect(1)
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [no_wrap_tmp(1:end,:);flip((pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position))];
                    else
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [no_wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    end
                    roi.slice(slice_n).volume(vol_n).length{n_pla} = no_wrap_l;
                    pla_roi.slice(slice_n).volume(vol_n).type{n_pla} = 'no_wrap';
                else
                    if pla_intersect(2)>pla_intersect(1)
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    else
                        pla_roi.slice(slice_n).volume(vol_n).pos{n_pla} = [wrap_tmp(1:end,:);flip(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position)];
                    end
                    pla_roi.slice(slice_n).volume(vol_n).length{n_pla} = wrap_l;
                    pla_roi.slice(slice_n).volume(vol_n).type{n_pla} = 'wrap';
                end

                
            end
            
            clear pla_intersect;
        end
    end
end








