function [pla_out,uter_out] = uter_placenta_stats(pos_store,uter_ID,slice_n,vol_n)
%This function takes the pos_store and uter_ID arrays to recreate the
%placenta/uterus outlines made in the mask drawing program. Due to an error
%in parition_placentav03.m the results calculated by the mask drawing
%program are unreliable. However, it does properly make and assign the
%masks, so we can still use those to calculate the correct values here.


pla_out.length = 0;
pla_out.area = 0;

uter_out.length = 0;
uter_out.area = 0;
n_pla = 0;

%For all objects
%Need to 'complete' the placental mask since it is only a line
for roi_n = 2:size(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos,2)
    n_pla = n_pla+1;
    c = 1;
    for pos_n = [1 ,size(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n},1)]
        pos_tmp = pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(pos_n,:);
        uterus_pos_tmp = [pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{1,1}; pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{1,1}(1,:)];
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
            %So a bit of fun here; the min and max values need to
            %be floor/ceil due to rounding issues when converting
            %polygons to masks.
            
            x_coords =[min_x min_x max_x max_x];
            y_coords = [min_y max_y max_y min_y];
            
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
    
    
    %Now need to determine the placental ROI, including the
    %uterine mask for the maternal boundary of the placenta.       


    if pla_intersect(2)>pla_intersect(1)
        no_wrap_tmp = [pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(1,:);uterus_pos_tmp([pla_intersect(1)+1:pla_intersect(2)],:) ; pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(end,:) ];
        wrap_tmp = [pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(1,:);uterus_pos_tmp([flip(1:pla_intersect(1)),flip(pla_intersect(2)+1:size(uterus_pos_tmp,1))],:);pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(end,:)];
    else
        no_wrap_tmp = [pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(1,:);uterus_pos_tmp(flip([pla_intersect(2)+1:pla_intersect(1)]),:);pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(end,:)];
        wrap_tmp = [pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(1,:);flip(uterus_pos_tmp([flip(1:pla_intersect(2)), flip(pla_intersect(1)+1:size(uterus_pos_tmp,1))],:));pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}(end,:)];
    end
    

    
    no_wrap_l(n_pla) = sum(sqrt(sum(((no_wrap_tmp(2:end,:)-no_wrap_tmp(1:end-1,:)).^2),2)));
    wrap_l(n_pla) = sum(sqrt(sum(((wrap_tmp(2:end,:)-wrap_tmp(1:end-1,:)).^2),2)));
    
    
    no_wrap{n_pla} = no_wrap_tmp;
    wrap{n_pla} = wrap_tmp;
    
    
    if roi_n == 2 %For the first pla ROI save the uterus length
        pla_roi.slice(slice_n).volume(vol_n).uter_length = no_wrap_l(n_pla) + wrap_l(n_pla);
    end
    
%     
    %Now save outputs depending on supplied uter_ID
    
    %Uter ID works to detect which ROI should be the larger ROI I
    %assume this can only happen once so here are the ID codes:
    % 1 = take smallest ROI's everywhere
    % 2 = 1st placenta ROI is largest length
    % 3 = 2nd placenta ROI is largest length
    % and so on
    
    
    if  n_pla+1 ~= uter_ID
        if no_wrap_l(n_pla)<wrap_l(n_pla)
            if pla_intersect(2)>pla_intersect(1)
                pla_out.outline{roi_n-1} = [no_wrap_tmp(1:end,:);flip((pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}))];
            else
                pla_out.outline{roi_n-1}  = [no_wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            end
            
            pla_out.length(n_pla)  = no_wrap_l(n_pla);
        else
            if pla_intersect(2)>pla_intersect(1)
                pla_out.outline{roi_n-1}  = [wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            else
                pla_out.outline{roi_n-1}  = [wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            end
            pla_out.length(n_pla) = wrap_l(n_pla);
        end
    elseif n_pla+1 == uter_ID
        if no_wrap_l(n_pla)>wrap_l(n_pla)
            if pla_intersect(2)>pla_intersect(1)
                pla_out.outline{roi_n-1} = [no_wrap_tmp(1:end,:);flip((pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n}))];
            else
                pla_out.outline{roi_n-1} = [no_wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            end
            pla_out.length(n_pla)  = no_wrap_l(n_pla);
        else
            if pla_intersect(2)>pla_intersect(1)
                pla_out.outline{roi_n-1} = [wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            else
                pla_out.outline{roi_n-1} = [wrap_tmp(1:end,:);flip(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{roi_n})];
            end
            pla_out.length(n_pla) = wrap_l(n_pla);
        end
        
    end
    pla_out.area(n_pla) = polyarea(pla_out.outline{n_pla}(:,1),pla_out.outline{n_pla}(:,2));
    clear pla_intersect;
end
%If there is no placental mask then the entirity of the above loop will be
%skipped. Take the array as the uterus mask and assign placental values to
%[];
if size(pos_store(1).slice(slice_n).volume(vol_n).object(1).pos,2)==1
    uterus_pos_tmp = pos_store(1).slice(slice_n).volume(vol_n).object(1).pos{1};
    pla_out.outline = 0;
    pla_out.length = 0;
    pla_out.area = 0;
end

uter_pgon = polyshape(uterus_pos_tmp(:,1),uterus_pos_tmp(:,2));

uter_out.outline = uterus_pos_tmp;
uter_out.length =  perimeter(uter_pgon); 
uter_out.area = area(uter_pgon);
