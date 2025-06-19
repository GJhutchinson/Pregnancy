function save_masks(pos_store,save_dir,pla_roi,file,scan_1,varargin)

if length(varargin)>0;
    nifti_mask = varargin{1};
end

if exist('nifti_mask') %%If continuing/editing a nifti mask
    mask = nifti_mask;
    % delete('scan_1')
    for slice_n = 1:size(pos_store.slice,2)
        for vol_n = 1:size(pos_store.slice(slice_n).volume,2)
            mask_tmp = zeros(256,256);
            if length(pos_store.slice(slice_n).volume(vol_n).object)>0
                for mask_n = 1:size(pos_store.slice(slice_n).volume(vol_n).object(1).pos,2)
                    disp(['Slice',num2str(slice_n),' vol',num2str(vol_n)])
                    if mask_n == 1
                        mask_pos = pos_store(1).slice(slice_n).volume(vol_n).object.pos{mask_n};
                        mask_tmp = poly2mask(mask_pos(:,1),mask_pos(:,2),256,256);
                    else
                        mask_pos = pla_roi.slice(slice_n).volume(vol_n).pos{1};
                        mask_tmp = mask_tmp + poly2mask(mask_pos(:,1),mask_pos(:,2),256,256);
                    end
                end
                mask(:,:,slice_n,vol_n) = fliplr(mask_tmp');
            end
        end
    end

    if strcmp(file(1:end-4),'.nii')
        niftiwrite(mask,[save_dir,'\',file(1:end-4),'_mask_edited'])
    else
        niftiwrite(mask,[save_dir,'\',file(1:end-7),'_mask_edited'])
    end
else
    mask = zeros(size(scan_1));
    for slice_n = 1:size(pos_store.slice,2)
        for vol_n = 1:size(pos_store.slice(slice_n).volume,2)
            mask_tmp = zeros(256,256);
            if length(pos_store.slice(slice_n).volume(vol_n).object)>0
                for mask_n = 1:size(pos_store.slice(slice_n).volume(vol_n).object(1).pos,2)
                    disp(['Slice',num2str(slice_n),' vol',num2str(vol_n)])
                    if mask_n == 1
                        mask_pos = pos_store(1).slice(slice_n).volume(vol_n).object.pos{mask_n};
                        mask_tmp = poly2mask(pos_store(1).slice(slice_n).volume(vol_n).object.pos{mask_n}(:,1),pos_store(1).slice(slice_n).volume(vol_n).object.pos{mask_n}(:,2),256,256);
                    else
                        mask_pos = pla_roi.slice(slice_n).volume(vol_n).pos{1};
                        mask_tmp = mask_tmp + poly2mask(mask_pos(:,1),mask_pos(:,2),256,256);
                    end
                end
            end
            mask(:,:,slice_n,vol_n) = fliplr(mask_tmp');
        end
    end
    if strcmp(file(1:end-4),'.nii')
        niftiwrite(mask,[save_dir,'\',file(1:end-4),'_mask'])
    else
        niftiwrite(mask,[save_dir,'\',file(1:end-7),'_mask'])
    end
end
