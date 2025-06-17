clear all
clc

%We need to load in: The DWI scan, the mask + the discarded volumes...
%Is it worth running these one at a time? or should the code try to do
%both?.... probably one at a time. I'm not going to have GUI inputs or the
%like; just edit below parameters to select the scans you want

SWIRL_ID = '008';
visit_ID = '2';
scan_n = '11';
discard_n = [6 11];


% clearvars -except SWIRL_ID visit_ID scan_n
% discard_n = [4 9 19];

%Output variable: IVIM_fit
IVIM_fit.discard_n = discard_n;

b = [0 1 3 9 18 32 54 88 110 147 180 200 230 270 300 350 400 450 500];
%Save b as well.. might make things easier
IVIM_fit.b = b;

img = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\DWI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPDWI_19bvalues_',scan_n,'.nii']));
pla_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_pla_mask.nii']));
wall_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_wall_mask.nii']));
chor_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_chor_mask.nii']));
bas_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_bas_mask.nii']));
%Save the raw data
IVIM_fit.img = img;
img(:,:,:,discard_n) = [];
b(discard_n) = [];

%So a fun issue here; the masks are different so do not perfectly
%overlap where you would expect them to... 
wall_mask = wall_mask-pla_mask; 
wall_mask(wall_mask<0) = 0;

%% Find a non-zero region of signal to determine a threshold which we will
%save along with the data so we can rule out regions where the signal
%decays into the noise floor; which would provide meaningless fits.

for vol_n = 1:size(img,4)
    for slice_n = 1:size(img,3)%imadjust only takes 2D input
        tmp(:,:,slice_n,vol_n) = imadjust(img(:,:,slice_n,vol_n)./max(img(:,:,slice_n,vol_n),[],'all'));
    end
end

%Allow user to flick between slices/adjust contrast to find region

figure
colormap gray

contrast_label = uicontrol('Style','Text','Position',[100 50 135 30],'String','Contrast')
contrast_slider = uicontrol('Style','Slider','min',0.01,'max',1,'Value',1,'Position', [100 20 120 30],'SliderStep',[1/20 1/10]);

slice_label = uicontrol('Style','Text','Position',[250 50 135 30],'String','Slice = ')
slice_slider = uicontrol('Style','Slider','min',1,'max',size(img,3),'Value',1,'Position', [250 20 120 30],'SliderStep',[1/6 1/3]);


b_label = uicontrol('Style','Text','Position',[400 50 135 30],'String','Slice = ')
b_slider = uicontrol('Style','Slider','min',1,'max',length(b),'Value',length(b),'Position', [400 20 120 30],'SliderStep',[1/length(b) 1/3]);


kill_button = uicontrol(figure(1),'Style','togglebutton','min',0,'max',1,'Value',0,'Position', [550 20 120 30],'String','Choose slice');

%GUI for selecting slice/contrast
while kill_button.Value == 0 %Until button is pressed

    
    %Slice slider label
    set(slice_label,'String',['Slice = ',num2str(round(slice_slider.Value))])
    set(b_label,'String',['b = ',num2str(b(round(b_slider.Value)))])


    %Display image and edit contrast
    imagesc(tmp(:,:,round(slice_slider.Value),round(b_slider.Value)))
    title('Find a region of low signal within the participant')
    caxis([0 contrast_slider.Value])

    drawnow
    pause(0.1)
end

%Now draw ROI
ROI = drawpolygon;
%Turn into mask
ROI = createMask(ROI,256,256);
%Calculate mean signal intensity, this is the noise floor
IVIM_fit.background = mean(nonzeros(img(:,:,round(slice_slider.Value),round(b_slider.Value)).*ROI))

%Fit to IVIM model
[IVIM_fit.S0,IVIM_fit.f_IVIM,IVIM_fit.D,IVIM_fit.Dstar] = fit_IVIM(b,img,pla_mask(:,:,:,1)+wall_mask(:,:,:,1)+chor_mask(:,:,:,1)+bas_mask(:,:,:,1));

%Save masks... might be easier than re-reading in the .nii
IVIM_fit.pla_mask = pla_mask;
IVIM_fit.wall_mask = wall_mask;
IVIM_fit.bas_mask = bas_mask;
IVIM_fit.chor_mask = chor_mask;


save(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\DWI\erosion_masks_fitting\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B',SWIRL_ID,'_',visit_ID,'_',scan_n,'_IVIM_fit'],'IVIM_fit')


close all














