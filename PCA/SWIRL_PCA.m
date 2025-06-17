%% THIS BIT MEANS I CAN RUN STRAIGHT AFTER mask_PCA
clearvars -except subj visit_n scan_n 

SWIRL_ID = subj;
visit_ID = visit_n;

clear subj visit_n;
use_old_discard = 0;
clc
addpath('C:\placental\Functions\')


%% This bit if you don't run mask PCA
% SWIRL_ID = '032';
% visit_ID = '2';
% scan_n = '22';
% use_old_discard = 1;
%%
mag = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'.nii']));
phase = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_ph.nii']));

wall_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion masks\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_wall_mask.nii']));
bas_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion masks\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_bas_mask.nii']));
pla_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion masks\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_pla_mask.nii']));
chor_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion masks\masks\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_chor_mask.nii']));

phase = 2*pi*(phase./4094)-pi;%rescale -pi to pi

%So a fun issue here; the masks are different so do not perfectly
%overlap where you would expect them to... 
tot_mask = pla_mask+wall_mask+bas_mask+chor_mask;


cmp_base = mag(:,:,:,1).*exp(i*phase(:,:,:,1));
for k = 1:7 % b=0, b= P M S in this order
    cmp_vel = mag(:,:,:,k).*exp(i*phase(:,:,:,k));
    cmp_ratio(:,:,:,k) = cmp_vel./cmp_base;
    phi_unwrap(:,:,:,k) = angle(cmp_ratio(:,:,:,k)) ;
    phi_unwrap_m(:,:,:,k) = angle(cmp_ratio(:,:,:,k)).*squeeze(pla_mask(:,:,:));
end


phi_unwrap(isnan(phi_unwrap))=0;
phi_unwrap_m(isnan(phi_unwrap_m))=0;

% %rescale phase from -pi to pi
% phase = ((phase./4094).*2*pi) - pi;
% 
% 
% %Unwrap phase based on b=0 image
% phi_unwrap = wrapToPi(phase(:,:,:,2:7) - phase(:,:,:,1));

phi_unwrap2 = wrapToPi(phase(:,:,:,2:end) - phase(:,:,:,1));

%% apply butterworth filter
%Apply a butterworth filter to smooth data
D = [4];% filter size

for k = 1:7 %b= P M S, P M S in this order
    for sl = 1:size(phi_unwrap,3)
        filterphase(:,:,sl,k) =   Butterworth_2d(phi_unwrap(:,:,sl,k),D,1);
        filterphase_m(:,:,sl,k) = Butterworth_2d(phi_unwrap(:,:,sl,k),D,1).*pla_mask(:,:,sl);
        tmp = nanmean(nonzeros(filterphase_m(:,:,sl,k)));
        shift(sl,k) = tmp;
        filterphase_m_shift(:,:,sl,k) = (filterphase_m(:,:,sl,k)-tmp).*pla_mask(:,:,sl);
        filterphase_shift(:,:,sl,k)= filterphase(:,:,sl,k) -tmp;
        clear tmp;
    end
end


phi10 = filterphase_shift(:,:,:,[3 2 4],:);
phi40 =  filterphase_shift(:,:,:,[6 5 7],:);
%% I have not personally checked any of these values, they are the same as PiP-Ox
%Should be fine but I'd like to double check.
gamma = 267.513*1e6;
delta = 3.1*1e-3;
% b=10 and 40
Delta = 34.9e-3;

% THESES ARE THE NEW CONVERSION VALUES TO CONVERT PHI TO VELOCITY
A10 = 64.93*1e-6;
A40 = 126.28*1e-6;
vel10 = phi10./(gamma*A10*Delta)*1e2;
vel40 = phi40./(gamma*A40*Delta)*1e2;


%%
%If you want to use previously discarded slices
if use_old_discard == 1
    try %Try and load the discard
        prev_discard = load(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_',scan_n,'_maps.mat']);
        bad_sl_b10 = prev_discard.bad_sl_b10;
        bad_sl_b40 = prev_discard.bad_sl_b40;
    catch %If it can't load; it may not exist. Discard slices again
        bad_sl_b10 = sliceviewer_dwi(vel10.*pla_mask,size(vel10,3),size(vel10,4),[-.4 .4])
        bad_sl_b40 = sliceviewer_dwi(vel40.*pla_mask,size(vel40,3),size(vel40,4),[-.2 .2])

    end
else %If you want to (re)discard slices: 
    bad_sl_b10 = sliceviewer_dwi(vel10.*pla_mask,size(vel10,3),size(vel10,4),[-.4 .4])
    bad_sl_b40 = sliceviewer_dwi(vel40.*pla_mask,size(vel40,3),size(vel40,4),[-.2 .2])

end




%% calculate the net velocity.
v10 = (squeeze(vel10(:,:,:,1,:).^2) + squeeze(vel10(:,:,:,2,:).^2) + squeeze(vel10(:,:,:,3,:).^2)).^.5;
v40 = (squeeze(vel40(:,:,:,1,:).^2) + squeeze(vel40(:,:,:,2,:).^2) + squeeze(vel40(:,:,:,3,:).^2)).^.5;

velx10_pla = vel10(:,:,:,1,:).*tot_mask;
vely10_pla = vel10(:,:,:,2,:).*tot_mask;
velz10_pla = vel10(:,:,:,3,:).*tot_mask;

velx40_pla = vel40(:,:,:,1,:).*tot_mask;
vely40_pla = vel40(:,:,:,2,:).*tot_mask;
velz40_pla = vel40(:,:,:,3,:).*tot_mask;

mkdir(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion_vel\processing\',SWIRL_ID,'_',visit_ID])
save(['R:\DRS-SWIRL\Activity 2 MRI\misc\George\PCA\Erosion_vel\processing\',SWIRL_ID,'_',visit_ID,'\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_',scan_n,'_maps'],'velx10_pla','vely10_pla','velz10_pla','velx40_pla','vely40_pla','velz40_pla','bad_sl_b10','bad_sl_b40','pla_mask','wall_mask','bas_mask','chor_mask')

for slice_n = 1:6
    if sum(bad_sl_b10(slice_n,:))==0
    subplot(2,3,slice_n)
    colour_map_greyscale_background2(mag(:,:,slice_n,1),v10(:,:,slice_n).*pla_mask(:,:,slice_n))
    caxis([0 0.15])
    end
end









