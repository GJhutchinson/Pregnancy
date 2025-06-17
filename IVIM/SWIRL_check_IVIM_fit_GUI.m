% clear all
% clc
% 
% %We need to load in: The DWI scan, the mask + the discarded volumes...
% %Is it worth running these one at a time? or should the code try to do
% %both?.... probably one at a time. I'm not going to have GUI inputs or the
% %like; just edit below parameters to select the scans you want
% 
% 
% SWIRL_ID = '007';
% visit_ID = '2';
% scan_n = '12';

%%
clearvars -except SWIRL_ID scan_n visit_ID
addpath('C:\placental\Functions')
%Load in fit data
load(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B',SWIRL_ID,'_',visit_ID,'_',scan_n,'_IVIM_fit']);
%Combine masks to get all data

tot_mask = IVIM_fit.pla_mask+IVIM_fit.wall_mask+IVIM_fit.bas_mask+IVIM_fit.chor_mask;

noise_mask = [IVIM_fit.img(:,:,:,1)>[5.*IVIM_fit.background]].*tot_mask;

%Remove unnecessary data
IVIM_fit.b(IVIM_fit.discard_n) = [];
IVIM_fit.img(:,:,:,IVIM_fit.discard_n) = [];

%Find the locations of the voxels
[idx] = find(tot_mask(:,:,:,1));
[y,x,z] = ind2sub(size(tot_mask(:,:,:,1)),idx);

%This is for cropping the figure, and placing the starting point over the
%placenta. offset is how far either side of the placenta in voxels we look
offset = 30;
[min_x,~] = min(x);[max_x,~] = max(x);
[min_y,~] = min(y);[max_y,~] = max(y);
%For setting the axis of the image over placenta
min_x = min_x - offset;max_x = max_x + offset;
min_y = min_y - offset;max_y = max_y + offset;


%For a smooth fit use more b-values
b_fit = linspace(0,500,501);
%IVIM model
bi_exp = @(x,x_data) x(1).*( (1-x(2)).*exp(-x(3).*x_data) + x(2).*exp(-x(4).*x_data));


%GUI; x,y controls, slice controls + parameter to dispaly (S0,fIVIM,D,D*)
x_display = uicontrol('Style','Text','Position',[100 50 135 30],'String','X');
x_slider = uicontrol('Style','Slider','min',min_x,'max',max_x,'Value',min_x + (max_x - min_x)/2,'Position', [100 20 120 30],'SliderStep',[1/(max_x-min_x) 1/25]);

y_display = uicontrol('Style','Text','Position',[250 50 135 30],'String','Y');
y_slider = uicontrol('Style','Slider','min',min_y,'max',max_y,'Value',min_y + (max_y - min_y)/2,'Position', [250 20 120 30],'SliderStep',[1/(max_y-min_y) 1/25]);

slice_display = uicontrol('Style','Text','Position',[400 50 135 30],'String','Y');
slice_slider = uicontrol('Style','Slider','min',1,'max',size(IVIM_fit.img,3),'Value',1,'Position', [400 20 120 30],'SliderStep',[1/size(IVIM_fit.img,3) 1/size(IVIM_fit.img,3)]);

param_display = uicontrol('Style','Text','Position',[550 50 135 30],'String','Y');
param_slider = uicontrol('Style','Slider','min',1,'max',4,'Value',1,'Position', [550 20 120 30],'SliderStep',[1/4 1/4]);

noise_floor_button = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'Position',[700 20 120 30],'String','Noise floor');

wall_mask_button = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'Position',[840 20 120 30],'String','Wall');
bas_mask_button = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'Position',[980 20 120 30],'String','Basal plate');
pla_mask_button = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'Position',[1120 20 120 30],'String','Placenta');
chor_mask_button = uicontrol('Style','togglebutton','min',0,'max',1,'Value',0,'Position',[1260 20 120 30],'String','Chorionic plate');




while true
    %Get slider values
    x_val = round(x_slider.Value);
    y_val = round(y_slider.Value);
    slice_n = round(slice_slider.Value);
    param_n = round(param_slider.Value);

    %Update displays
    set(slice_display,'string',['Slice = ',num2str(slice_n)]);
    set(x_display,'string',['x = ',num2str(x_val)]);
    set(y_display,'string',['y = ',num2str(y_val)]);

    %Depending on which parameter selected; select that one to display; and
    %change the display to match
    switch param_n
        case  1
            map = IVIM_fit.S0(:,:,slice_n);
            set(param_display,'string',['S_0']);
        case  2
            map = IVIM_fit.f_IVIM(:,:,slice_n);
           set(param_display,'string',['f_{IVIM}']);

        case  3
            map = IVIM_fit.D(:,:,slice_n);
            set(param_display,'string',['D']);
        case  4
            map = IVIM_fit.Dstar(:,:,slice_n);
            set(param_display,'string',['D^*']);
    end

    %Display background image, parameter map, and show the highlighted
    %voxel
    img_map = [IVIM_fit.wall_mask(:,:,slice_n).*~wall_mask_button.Value+IVIM_fit.bas_mask(:,:,slice_n).*~bas_mask_button.Value+IVIM_fit.pla_mask(:,:,slice_n).*~pla_mask_button.Value+IVIM_fit.chor_mask(:,:,slice_n).*~chor_mask_button.Value].*map;


    subplot(2,2,[1 3])
    if noise_floor_button.Value == 0
        colour_map_greyscale_background2(IVIM_fit.img(:,:,slice_n),img_map);
    else
        colour_map_greyscale_background2(IVIM_fit.img(:,:,slice_n),img_map.*noise_mask(:,:,slice_n));
    end

    switch param_n
        case 2
            caxis([0 1])
        case 3
            caxis([0 5*1e-3])
        case 4
            caxis([0 300*1e-3])
    end
   
    yline(y_val,'g');
    xline(x_val,'g');
    hold off

    plot_tmp = [IVIM_fit.S0(y_val,x_val,slice_n) IVIM_fit.f_IVIM(y_val,x_val,slice_n) IVIM_fit.D(y_val,x_val,slice_n) IVIM_fit.Dstar(y_val,x_val,slice_n)];
    
    subplot(2,2,2)
    plot(IVIM_fit.b,squeeze(IVIM_fit.img(y_val,x_val,slice_n,:)),'x','markersize',14,'linewidth',4)
    hold on
    plot(b_fit,bi_exp(plot_tmp,b_fit),'linewidth',3)
    xlabel('b (s/mm^2)')
    ylabel('S_0')
    set(gca,'fontsize',24)
    hold off

    drawnow

end









