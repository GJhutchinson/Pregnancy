%% Script for making masks from 3 or 4D data
% George Hutchinson 10/06/25

% This code allows for masking of placental data into two distince ROIs;
% placental and uterus. Note the placental ROI will also contain the
% uterine wall within it, but this could still be useful later on, or could
% be loaded up and split into the old ROIs we used to use saving some time.
% The outputs are three files;ending placenta.nii, uterus.nii and
% mask_file.mat. As well as producing the ROIs it will save the lengths of
% the uterus and the length the placenta covers along the uterus.


%This code is very much a work in progress, expect some bugs and problems
%while teething issues are sorted out. Code has had a significant overhaul
% to do placental + uterine ROI masking. This may introduce more bugs
% into the code I'd reccomend saving regularly and if it crashes try
% higlightling the line below (excluding the % and pressing F9) to try to save any unsaved data.

% save([save_dir,'/',file(1:end-4),'_mask_file_post_crash'],'pos_store','pla_roi','uter_ID')

%The filename will end with post_crash.mat and not overwrite the current mask file in case
%the data causes issues with the script (This likely would be easily
%recoverable). If you have any reccomendations (moving buttons, changing
%how things work etc) tell me, I've not experimented much with this code so
%there are probably more user friendly or intelligent of doing things.

%##############################CHANGES##############################

%01/08/23
%Added some cd commands to place you in the right directories for SWIRL
%Added a write permissions check to ensure you can actually save the data

%30/06/23
%Swapped image axis to match MIPAV
%Changed slice and volume indices to match MIPAV
%Move undo button
%Save and close now saves and closes (doesn't generate NIfTI masks)
%Added generate mask button which now closes script + generates NIfTI masks

%10/06/25
%Added the ability to load ML nifti masks

%%%%Version history%%%%
% 25/05/23 Initial version
% 30/06/23 Updated to v1.1
% 01/08/23 Updated to v1.2
% 10/06/25 updated to v1.3
%%%%Dependencies%%%%
%partition_placentav03.m
%snap_pla_to_uterv02.m
%image processing toolbox
%ML_to_sides


clc
clear
clf
close all

addpath('.')
% try cd R:/
% catch
%     warning(['Could not locate the R drive'])
% end
%Pre defining ROI colours
C = [0.346666666666667,0.536000000000000,0.690666666666667;0.915294117647059,0.281568627450980,0.287843137254902;0.441568627450980,0.749019607843137,0.432156862745098;1,0.598431372549020,0.200000000000000;0.676862745098039,0.444705882352941,0.711372549019608];
figure('units','normalized','position',[0 0 0.5 0.5])
new_mask = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.1 0.1 0.4 0.4],'String','New Mask');
cont_mask = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.5 0.1 0.4 0.4],'String','Continue Mask');

while new_mask.Value == 0 && cont_mask.Value == 0
    drawnow
end
if new_mask.Value == 1
    disp('Starting new mask')
    close all
    new_mask = 1;
    cont_mask = 0;
elseif cont_mask.Value == 1
    disp('Continuing previous mask')
    close all
    new_mask = 0;
    cont_mask = 1;
end

%Look only for nifti
%File to mask
% cd('C:\placental\Functions\masking_working\')

[file,path] = uigetfile('*.nii*','Select the NIfTI to mask');
scan_1 = niftiread([path,file]);
cd(path)
%Save directory
[save_dir] = uigetdir('','Select the directory to save the mask(s) to');

%Check write permissions... This is a bit of a caveman way to do this but I
%couldn't find a better way
test_fname = [save_dir,'/test_file_asd4hjiowjas522854.txt']; %Random string to ensure there wont be a file in the directory with that name
try
    [fileID,flag] = fopen(test_fname,'w');
    fprintf(fileID,'TEST');
    fclose(fileID);
    delete([save_dir,'/test_file_asd4hjiowjas522854.txt']);
catch
    error('You may not have write perimissions in this folder, please try another.')
end


%Main GUI figure
f = figure('units','normalized','position',[0 0 0.5 0.5]);
ax = axes('Parent',f);


%Make UI control options
slice_display = uicontrol(figure(1),'Style','Text','units','normalized','Position',[0.0521 0.0463 0.0703 0.0278],'String','X');
slice_slider = uicontrol(figure(1),'Style','Slider','units','normalized','min',1,'max',size(scan_1,3),'Value',1,'Position', [0.0521 0.0185 0.0625 0.0278],'SliderStep',[1/size(scan_1,3) 1/size(scan_1,3)]);

%If 3D or 4D data
if size(scan_1,4) > 1
    volume_slider  = uicontrol(figure(1),'Style','Slider','units','normalized','min',1,'max',size(scan_1,4),'Value',1,'Position', [0.1302 0.0185 0.0625 0.0278],'SliderStep',[1/size(scan_1,4) 1/size(scan_1,4)]);
    volume_display = uicontrol(figure(1),'Style','Text','units','normalized','Position',[0.1302 0.0463 0.0703 0.0278],'String','X');
else
    volume_slider  = uicontrol(figure(1),'Style','Slider','units','normalized','min',1.1,'max',1.3,'Value',1.15,'Position', [0.1302 0.0185 0.0625 0.0278],'SliderStep',[1/size(scan_1,4) 1/size(scan_1,4)]);
    volume_display = uicontrol(figure(1),'Style','Text','units','normalized','Position',[0.1302 0.0463 0.0703 0.0278],'String','X');

end


kill_button = uicontrol(figure(1),'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.9 0.0185 0.0812 0.0556],'String','Close and save');
save_and_continue = uicontrol(figure(1),'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.82 0.0185 0.0812 0.0556],'String','Save');

generate_masks = uicontrol(figure(1),'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.90 0.0768 0.0812 0.09],'String','Generate Masks');

contrast_button = uicontrol(figure(1),'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.635 0.0185 0.034 0.0556],'String','Contrast');
contrast_figure = figure;
close(contrast_figure)

toggle_placenta_side = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.4029 0.0185 0.07 0.03],'String','Toggle pla');

undo_last_ROI = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.3050 0.0463 0.07 0.03],'String','Undo');

draw_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.2344 0.0185 0.07 0.03],'String','Add obj');

edit_nifti_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.3050 0.0185 0.07 0.03],'String','Edit nifti');

draw_dropdown.Value = 3;

edit_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.2344 0.0463 0.07 0.03],'String','Edit obj');

send_across_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.4029 0.0463 0.07 0.03],'String','send ROI');
send_across_popup_list = uicontrol(f,'Style','popupmenu','units','normalized','Position',[0.472 0.0463 0.05 0.03],'String',{'Next slice:','Next volume:','Previous slice:','Previous volume:'});


% add_mask_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.68 0.0185 0.0812 0.0556],'String','Add ROI');
% ROI_select_text = uicontrol(f,'Style','Text','units','normalized','Position',[0.0171 0.52 0.153 0.178],'String','Switch between ROIs','fontsize',32);

if new_mask == 1 %If starting new masks from scratch
    n_masks = 1;
    %Some arrays for data storage
    pos_store = struct;%The positions of the polygons for the mask
    uter_ID = struct;
    pla_roi = struct;
    nifti_cont = 0;
elseif cont_mask == 1 %If continuing from a mask file produced by this script
    disp('Loading previous mask')
    [maskfile_file,maskfile_path] = uigetfile({'*.nii*';'*.mat'},'Select the .mat mask file');

    %If matlab mask
    if strcmp(maskfile_file(end-2:end),'mat')
        load([maskfile_path,maskfile_file]);
        nifti_cont = 0;
    elseif strcmp(maskfile_file(end-2:end),'nii') || strcmp(maskfile_file(end-2:end),'.gz')
        nifti_cont = 1;
        nifti_mask = niftiread([maskfile_path,'\',maskfile_file]);
        %To display mask we need to convert it into an RGB array to display
        %ontop of the MRI image
        nifti_mask = flip(permute(nifti_mask,[2 1 3 4 5]),1);

        %Initialise temporary arrays
        nifti_mask_R = zeros([size(nifti_mask)]);
        nifti_mask_G = zeros([size(nifti_mask)]);
        nifti_mask_B = zeros([size(nifti_mask)]);
        %Assign uterine ROI to colour
        nifti_mask_R(nifti_mask==1) = C(4,1);
        nifti_mask_G(nifti_mask==1) = C(4,2);
        nifti_mask_B(nifti_mask==1) = C(4,3);
        %Assign placental ROI to colour
        nifti_mask_R(nifti_mask==2) = C(3,1);
        nifti_mask_G(nifti_mask==2) = C(3,2);
        nifti_mask_B(nifti_mask==2) = C(3,3);
        %Combine and reshape to final array
        nifti_mask_RGB = cat(5,nifti_mask_R,nifti_mask_G,nifti_mask_B);
        % nifti_mask_RGB = permute(nifti_mask_RGB,[1 2 3 4 5]);
        clear nifti_mask_R nifti_mask_G nifti_mask_B %Delete temporary arrays

        pos_store = struct;%The positions of the polygons for the mask
        uter_ID = struct;
        pla_roi = struct;
        

    end
end

%A load of things that get compared during iterations to see if anything
%has changed and thus require action between runs.
uter_ID_prev = 1;
kill = [0 0];
check_obj = 1;
selected_mask = 1;
prev_slice = 0;
prev_vol = 0;
prev_selected_mask = 0;
obj_bool_prev = 0;
total_obj_prev = 999;
show_masks = 1;
show_n_masks = 1;
while kill == [0 0]
    % Initially I tried to make this function free; so only one program is
    % needed to run making things easier. I ended up having to add
    % functions, so it would be better to rewrite this at some point, where
    % each button calls upon a function to execute... but I've spent a lot
    % of time on this and will not be doing this until I have
    % to overhaul the code again. If anyone wants to rewrite the code for
    % functionality or ease of reading please be my guest.

    %Get values from sliders and set strings
    slice_n = round(get(slice_slider,'Value'));
    set(slice_display,'string',['Slice = ',num2str(slice_n-1)]);
    vol_n = round(get(volume_slider,'Value'));
    set(volume_display,'string',['Volume = ',num2str(vol_n-1)]);

    %Check if slice or volume has updated; if it has update the objects in
    %the image
    if slice_n ~= prev_slice || prev_vol ~= vol_n
        %Show the selected slice
        im = imagesc(ax,flip(scan_1(:,:,slice_n,vol_n)'));
        axis([0 256 0 256])
        axis(ax,'square');
        colormap(ax,'gray');

        %If contrast has been edited adjust contrast
        if exist('caxis_lb')
            caxis(ax,[caxis_lb caxis_ub]);
        end

        %If a mask exists display the pologon on current slice
        for n = 1:length(show_n_masks)
            if show_n_masks(n) ~=0
                try
                    pos_store(n).slice(slice_n).volume(vol_n).object.type;
                    for obj_n = 1:size(pos_store(n).slice(slice_n).volume(vol_n).object,2)
                        if pos_store(n).slice(slice_n).volume(vol_n).object.type == 3
                            for roi_n = 1:size(pos_store(n).slice(slice_n).volume(vol_n).object(obj_n).roi,2)
                                if roi_n == 1
                                    pos_store(n).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n) = images.roi.Polygon(im.Parent,'Position',pos_store(n).slice(slice_n).volume(vol_n).object(obj_n).pos{roi_n},'color',C(n,:));
                                else
                                    pos_store(n).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n) = images.roi.Polyline(im.Parent,'Position',pos_store(n).slice(slice_n).volume(vol_n).object(obj_n).pos{roi_n},'color',C(n,:));
                                end
                            end
                            for pla_roi_n = 1:size(pla_roi.slice(slice_n).volume(vol_n).pos,2)
                                pla_roi_tmp = pla_roi.slice(slice_n).volume(vol_n).pos{pla_roi_n};
                                hold on
                                green_line(pla_roi_n) = plot(pla_roi_tmp(:,1),pla_roi_tmp(:,2),'g','linewidth',1);
                                hold off
                            end
                        end
                    end
                catch %If failed to display mask
                    %Check if there is a nifti mask loaded

                    if nifti_cont == 1
                        hold on
                        image(ax,squeeze(nifti_mask_RGB(:,:,slice_n,vol_n,:)),'AlphaData',logical(nifti_mask(:,:,slice_n,vol_n))*0.5);
                        hold off
                    end

                end
            end
        end
        prev_slice = slice_n;
        prev_vol = vol_n;
    end



    kill = [get(kill_button,'value')  get(generate_masks,'value')];

    %Has draw or edit ROI been pressed
    draw_button_val = get(draw_button,'value');
    edit_button_val = get(edit_button,'value');


    %If contrast has been edited adjust contrast
    if exist('caxis_lb')
        caxis(ax,[caxis_lb caxis_ub]);
    end

    %If nifti-mask display mask outline; unless the mask has been edited






    if draw_button.Value == 1 %If draw button is pressed then add an object to the current ROI
        obj_type = draw_dropdown.Value;
        %only one obj_type in this code, but will keep using this to make
        %merging code easier down the line
        try
            obj_n = size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object,2) + 1;
        catch%Else it's the first
            obj_n = 1;
        end

        %If drawing a placental/uterine ROI and it's not the first object,
        %check if a uterine/placental object already exists
        if obj_type == 1%Polygon ROI
            pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi = drawpolygon(im.Parent);
            pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi.Position; %Update ROI with new ROI
        elseif obj_type == 2%Line ROI
            pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi = drawpolyline(im.Parent);
            pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi.Position; %Update ROI with new ROI
        elseif obj_type == 3%Special uterine+placenta ROI

            try%Try: If there already is a placental/uterine object drawn
                if ismember(3,pos_store(selected_mask).slice(slice_n).volume(vol_n).object.type(:))
                    obj_n = find(pos_store(selected_mask).slice(slice_n).volume(vol_n).object.type(:)==3);
                    %Then allow another polygon for the placental ROI
                    roi_n = size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi,2);
                    pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n+1) = drawpolyline(im.Parent);
                    %Force placental mask to start and end on the uterus mask
                    [pos_store] = snap_pla_to_uterv02(pos_store,selected_mask,slice_n,vol_n,obj_n);               %Now need to snap the placental ROI to a point which is also
                    pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos{roi_n+1} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n+1).Position; %Update ROI with new ROI

                end
            catch%if no placental/uterine object
                %Then
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(1) = drawpolygon(im.Parent);
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos{1} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(1).Position; %Update ROI with new ROI

                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(2) = drawpolyline(im.Parent);
                %Force placental mask to start and end on the uterus mask
                [pos_store] = snap_pla_to_uterv02(pos_store,selected_mask,slice_n,vol_n,obj_n);               %Now need to snap the placental ROI to a point which is also

                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos{2} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(2).Position; %Update ROI with new ROI

                %on the uterus. This will need to be done after
            end
        end
        pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).type = obj_type;
        if uter_ID_prev <3
            uter_ID.slice(slice_n).volume(vol_n) = uter_ID_prev;
        else
            uter_ID.slice(slice_n).volume(vol_n) = 1;
        end
        %Now need to split the Uterus into placenta and not placenta + find
        %the intersect of the placenta with the wall mask
        [pla_roi] = partition_placentav03(pos_store,slice_n,vol_n,selected_mask,uter_ID.slice(slice_n).volume(vol_n),pla_roi);
        draw_button.Value = 0;
        %Hack to update the image
        prev_slice = 0;
    end

    if edit_button.Value == 1 %If edit button is pushed edit currently existing ROI if present
        edit_button = uicontrol(f,'Style','togglebutton','Callback','uiresume(f)','units','normalized','Position',[0.2344 0.0185 0.07 0.0578],'String','Finished editing');
        if exist('green_line')
            delete(green_line)
        end
        try %Allow editing of the current mask. try is to prevent a crash if no polygon exists
            %             delete(h)%Delete current ROI from figure
            %             roi = drawpolygon('Position',pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos);%Draw new ROI
            uiwait(f)%callback to edit button to allow script to resume after 'finished editing' button is pressed
            for mask_n = 1:size(pos_store,2)
                for obj = 1:size(pos_store(mask_n).slice(slice_n).volume(vol_n).object,2)
                    if pos_store(mask_n).slice(slice_n).volume(vol_n).object.type<3
                        pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).pos = pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).roi.Position;%Store new ROI position
                    elseif pos_store(mask_n).slice(slice_n).volume(vol_n).object.type == 3
                        for roi_n = 1:size(pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi,2)
                            if roi_n == 1
                                pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).pos{roi_n} = pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).roi(roi_n).Position;%Store new ROI position
                            else
                                pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).roi(roi_n).Position = pos_store(mask_n).slice(slice_n).volume(vol_n).object(obj).roi(roi_n).Position;%Store new ROI position
                                [pos_store] = snap_pla_to_uterv02(pos_store,selected_mask,slice_n,vol_n,obj_n);               %Now need to snap the placental ROI to a point which is also
                                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).pos{roi_n} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(roi_n).Position; %Update ROI with new ROI
                            end
                        end
                    end
                end

            end
            [pla_roi] = partition_placentav03(pos_store,slice_n,vol_n,selected_mask,uter_ID.slice(slice_n).volume(vol_n),pla_roi);
            delete(edit_button)
            %Reset edit button

        catch
            disp('Error in edit function')
            delete(edit_button)
        end
        edit_button = uicontrol(f,'Style','togglebutton','min',0,'max',1,'Value',0,'units','normalized','Position',[0.2344 0.0463 0.07 0.03],'String','Edit ROI');
        %Force the image to update
        prev_slice = 0;
    end

    if edit_nifti_button.Value == 1
        %Check if there actually is a NifTi mask loaded
        if exist('nifti_mask')

            if length(find(nifti_mask(:,:,slice_n,vol_n)==2))>0 %If placenta masked in slice
                [pla_side,uter_side,pla_side_l,flip_ID] = ML_to_sides(nifti_mask(:,:,slice_n,vol_n));
                uter_outline_tmp = fliplr([pla_side;uter_side]);

                %Fill in information for future functions
                selected_mask = 1;
                obj_n = 1;
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).type = 3;

                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).roi(1) = drawpolygon(im.Parent,'position',[uter_outline_tmp]);
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).roi(2) = drawpolyline(im.Parent,'position',fliplr(pla_side_l));
                %Force placental mask to start and end on the uterus mask
                [pos_store] = snap_pla_to_uterv02(pos_store,selected_mask,slice_n,vol_n,1);               %Now need to snap the placental ROI to a point which is also
                %
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).pos{1} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(1).Position; %Update ROI with new ROI
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).pos{2} = pos_store(selected_mask).slice(slice_n).volume(vol_n).object(obj_n).roi(2).Position; %Update ROI with new ROI
                uter_ID.slice(slice_n).volume(vol_n) = flip_ID;
                [pla_roi] = partition_placentav03(pos_store,slice_n,vol_n,selected_mask,uter_ID.slice(slice_n).volume(vol_n),pla_roi);

            elseif length(find(nifti_mask(:,:,slice_n,vol_n)==1))>0 %Else no placenta

                [B,L] = bwboundaries(logical(nifti_mask(:,:,slice_n,vol_n)));
                tol_uter_line = 0.005;
                [~,max_idx] = max(cellfun(@length,B));
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).pos{1} = fliplr(reducepoly(B{max_idx},tol_uter_line));
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).roi(1) = drawpolygon(im.Parent,'position',[pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).pos{1}]);
                uter_ID.slice(slice_n).volume(vol_n) = 0;
                pos_store(selected_mask).slice(slice_n).volume(vol_n).object(1).type = 3;

                pla_roi.slice(slice_n).volume(vol_n).pos = [];

            end
        end
        prev_slice = 0;

        edit_nifti_button.Value = 0;
    end


    if send_across_button.Value == 1 %Send to next slice or volume
        disp('button press')
        try
            if send_across_popup_list.Value == 1 %Next slice
                pos_store(1).slice(slice_n+1).volume(vol_n).object = pos_store(1).slice(slice_n).volume(vol_n).object;
                pla_roi.slice(slice_n+1).volume(vol_n) = pla_roi.slice(slice_n).volume(vol_n);
                uter_ID.slice(slice_n+1).volume(vol_n) = uter_ID.slice(slice_n).volume(vol_n);
            elseif send_across_popup_list.Value == 2 %Next volume
                pos_store(1).slice(slice_n).volume(vol_n+1).object = pos_store(1).slice(slice_n).volume(vol_n).object;
                pla_roi.slice(slice_n).volume(vol_n+1) = pla_roi.slice(slice_n).volume(vol_n);
                uter_ID.slice(slice_n).volume(vol_n+1) = uter_ID.slice(slice_n).volume(vol_n);
            elseif send_across_popup_list.Value == 3 %Previous slice
                pos_store(1).slice(slice_n-1).volume(vol_n).object = pos_store(1).slice(slice_n).volume(vol_n).object;
                pla_roi.slice(slice_n-1).volume(vol_n) = pla_roi.slice(slice_n).volume(vol_n);
                uter_ID.slice(slice_n-1).volume(vol_n) = uter_ID.slice(slice_n).volume(vol_n);
            elseif send_across_popup_list.Value == 4 %Previous volume
                pos_store(1).slice(slice_n).volume(vol_n-1).object = pos_store(1).slice(slice_n).volume(vol_n).object;
                pla_roi.slice(slice_n).volume(vol_n-1) = pla_roi.slice(slice_n).volume(vol_n);
                uter_ID.slice(slice_n).volume(vol_n-1) = uter_ID.slice(slice_n).volume(vol_n);


            end
        catch
            disp('Unable to send to next volume or slice')
        end
        send_across_button.Value = 0;
    end

    %Contrast adjustment
    if contrast_button.Value == 1
        %For plotting histogram of non-zero voxels
        hist_data = scan_1(:,:,slice_n,vol_n);
        hist_data = hist_data(hist_data~=0);
        %If the contrast figure doesn't exist; make it
        if ishandle(contrast_figure) == 0
            contrast_figure = figure(2);
            contrast_ax = axes('Parent',contrast_figure);

            %This was added because its easy to just close the contrast
            %figure and lose the edit you just made. If there has been no
            %attempt to edit the contrast; then set limits to min-max
            %grayscale values. If there has been an attempt use those as
            %the limits for the slider
            if ~exist('caxis_lb','var')
                contrast_lb_display = uicontrol(figure(2),'Style','Text','units','normalized','Position',[0.75 0.82 0.15 0.07],'String','Lower bound');
                contrast_lb_slider = uicontrol(figure(2),'Style','Slider','min',1,'max',max(hist_data),'Value',1,'units','normalized','Position', [0.75 0.75 0.15 0.07],'SliderStep',[1/100 1/10]);
                contrast_ub_display = uicontrol(figure(2),'Style','Text','units','normalized','Position',[0.59 0.82 0.15 0.07],'String','Upper bound');
                contrast_ub_slider = uicontrol(figure(2),'Style','Slider','min',1,'max',max(hist_data),'Value',max(hist_data),'units','normalized','Position', [0.59 0.75 0.15 0.07],'SliderStep',[1/size(scan_1,3) 1/size(scan_1,3)]);
            else
                contrast_lb_display = uicontrol(figure(2),'Style','Text','units','normalized','Position',[0.75 0.82 0.15 0.07],'String','Lower bound');
                contrast_lb_slider = uicontrol(figure(2),'Style','Slider','min',1,'max',max(hist_data),'Value',caxis_lb,'units','normalized','Position', [0.75 0.75 0.15 0.07],'SliderStep',[1/100 1/10]);
                contrast_ub_display = uicontrol(figure(2),'Style','Text','units','normalized','Position',[0.59 0.82 0.15 0.07],'String','Upper bound');
                contrast_ub_slider = uicontrol(figure(2),'Style','Slider','min',1,'max',max(hist_data),'Value',caxis_ub,'units','normalized','Position', [0.59 0.75 0.15 0.07],'SliderStep',[1/size(scan_1,3) 1/size(scan_1,3)]);
            end
        end
        %Take upper and lower bounds from sliders
        caxis_lb = contrast_lb_slider.Value;
        caxis_ub = contrast_ub_slider.Value;
        %Hack to prevent the upper bound being lower than the lower bound;
        %otherwise it will cause a crash
        if caxis_lb >= caxis_ub
            caxis_ub = caxis_lb+1;
        end
        histogram(contrast_ax,hist_data,100)
        hold on
        xline(caxis_lb,'linewidth',5);
        xline(caxis_ub,'linewidth',5);
        hold off

    end

    if toggle_placenta_side.Value == 1
        try
            uter_ID_max = size(pla_roi.slice(slice_n).volume(vol_n).pos,2)+1;
            if uter_ID.slice(slice_n).volume(vol_n)<uter_ID_max
                uter_ID.slice(slice_n).volume(vol_n) = uter_ID.slice(slice_n).volume(vol_n)+1;
            else
                uter_ID.slice(slice_n).volume(vol_n) = 1;
            end

            uter_ID_prev = uter_ID.slice(slice_n).volume(vol_n);
            [pla_roi] = partition_placentav03(pos_store,slice_n,vol_n,selected_mask,uter_ID.slice(slice_n).volume(vol_n),pla_roi);


        catch
            disp('Error switching placenta ROI; is there a masked placenta on this slice?')
        end
        toggle_placenta_side.Value = 0;
        %Force the image to update
        prev_slice = 0;
    end

    if undo_last_ROI.Value == 1
        disp('pressed')
        try
            %For placental/uterine ROI
            if pos_store(n).slice(slice_n).volume(vol_n).object(1).type == 3
                %Delete last entry in pos_store
                pos_store(n).slice(slice_n).volume(vol_n).object(1).roi(size(pos_store(n).slice(slice_n).volume(vol_n).object(1).roi,2)) = [];
                pos_store(n).slice(slice_n).volume(vol_n).object(1).pos(size(pos_store(n).slice(slice_n).volume(vol_n).object(1).pos,2)) = [];
                %If this was a placental ROI, delete that too
                if size(pla_roi.slice(slice_n).volume(vol_n).pos,2) ~= 0
                    pla_roi.slice(slice_n).volume(vol_n).pos(size(pla_roi.slice(slice_n).volume(vol_n).pos,2)) = [];
                    pla_roi.slice(slice_n).volume(vol_n).length(size(pla_roi.slice(slice_n).volume(vol_n).length,2)) = [];
                else %Else it's a uterine object; clear everything out; means when you press draw
                    %it will start again; draw uterus + pla in one go
                    pos_store(selected_mask).slice(slice_n).volume(vol_n).object = [];
                end
            end

        catch
            disp('Unable to undo ROI')
        end

        undo_last_ROI.Value = 0;
    end

    if get(save_and_continue,'value') == 1

        save([save_dir,'/',file(1:end-4),'_mask_file'],'pos_store','pla_roi','uter_ID')
        save_and_continue.Value = 0;

    end

    drawnow %Causes figures to update
end

close all

save([save_dir,'/',file(1:end-4),'_mask_file'],'pos_store','pla_roi','uter_ID')



if isequal(kill,[0 1]) || isequal(kill,[1 1])
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
                            mask_tmp = poly2mask(pos_store(mask_n).slice(slice_n).volume(vol_n).object.pos{pla_roi_n}(:,1),pos_store(mask_n).slice(slice_n).volume(vol_n).object.pos{pla_roi_n}(:,2),256,256);
                        else
                            mask_pos = pla_roi.slice(slice_n).volume(vol_n).pos{1};
                            mask_tmp = mask_tmp + poly2mask(mask_pos(:,1),mask_pos(:,2),256,256);
                        end
                    end
                    mask(:,:,slice_n,vol_n) = mask_tmp;
                end
            end
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
                            mask_tmp = poly2mask(pos_store(mask_n).slice(slice_n).volume(vol_n).object.pos{pla_roi_n}(:,1),pos_store(mask_n).slice(slice_n).volume(vol_n).object.pos{pla_roi_n}(:,2),256,256);
                        else
                            mask_pos = pla_roi.slice(slice_n).volume(vol_n).pos{1};
                            mask_tmp = mask_tmp + poly2mask(mask_pos(:,1),mask_pos(:,2),256,256);
                        end
                    end
                end
                mask(:,:,slice_n,vol_n) = mask_tmp;
            end
        end


    end
end











