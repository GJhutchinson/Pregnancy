clear all
clc

%We need to load in the PCA scan + masks for processing 

SWIRL_ID = '001';
visit_ID = '1';
scan_n = '12';


mag = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'.nii']));
phase = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_ph.nii']));

pla_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_placenta.nii']));
wall_mask = double(niftiread(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_WIPPGSE_placenta_',scan_n,'_uterus.nii']));


%So a fun issue here; the masks are different so do not perfectly
%overlap where you would expect them to... 
wall_mask = wall_mask-pla_mask; 
wall_mask(wall_mask<0) = 0;
tot_mask = wall_mask(:,:,:,1)+pla_mask(:,:,:,1);

tot_mask = permute(tot_mask,[2 1 3]);


%rescale phase from -pi to pi
phase = ((phase./4094).*2*pi) - pi;
phase = permute(fliplr(phase),[2 1 3 4]);
mag = permute(fliplr(mag),[2 1 3 4]);

%Unwrap phase based on b=0 image
phi_unwrap = wrapToPi(phase(:,:,:,2:7) - phase(:,:,:,1));


%% apply butterworth filter
%Apply a butterworth filter to smooth data
D = [4];% filter size

for k = 1:6 %b= P M S, P M S in this order
    for sl = 1:size(phi_unwrap,3)
        filterphase(:,:,sl,k) =   Butterworth_2d(phi_unwrap(:,:,sl,k),D,1);
        filterphase_m(:,:,sl,k) = Butterworth_2d(phi_unwrap(:,:,sl,k),D,1).*tot_mask(:,:,sl);
        tmp = mean(nonzeros(filterphase_m(:,:,sl,k)));
        shift(sl,k) = tmp;
        filterphase_m_shift(:,:,sl,k) = (filterphase_m(:,:,sl,k)-tmp).*tot_mask(:,:,sl);
        filterphase_shift(:,:,sl,k)= filterphase(:,:,sl,k) -tmp;
        clear tmp;
    end
end


phi10 = filterphase_shift(:,:,:,[2 1 3],:);
phi40 =  filterphase_shift(:,:,:,[5 4 6],:);

phi10 = filterphase_shift(:,:,:,[2 1 3],:);
phi40 =  filterphase_shift(:,:,:,[5 4 6],:);
%% I have not personally checked any of these values, they are the same as PiP-Ox
%Should be fine but I'd like to double check.
gamma = 267.513*1e6;
delta = 3.1*1e-3;
% b=10 and 40
Delta = 36.5e-3;

% THESES ARE THE NEW CONVERSION VALUES TO CONVERT PHI TO VELOCITY
A10 = 63.28*1e-6;
A40 = 126.28*1e-6;

vel10 = phi10./(gamma*A10*Delta)*1e2;
vel40 = phi40./(gamma*A40*Delta)*1e2;

%% check the slices and discard the bad ones. for b=10 (+/- 0.5cm/s vel)
% need to do scan by scan.
bad_sl_b10(:,:,sc) = sliceviewer_dwi(vel10.*tot_mask,size(vel10,3),size(vel10,4),[-.4 .4])


%% check the slices and discard the bad ones. for b=40 (?cm/s vel)
% need to do scan by scan.
bad_sl_b40(:,:,sc) = sliceviewer_dwi(vel40.*tot_mask,size(vel40,3),size(vel40,4),[-.2 .2])


%% calculate the net velocity.
v10 = (squeeze(vel10(:,:,:,1,:).^2) + squeeze(vel10(:,:,:,2,:).^2) + squeeze(vel10(:,:,:,3,:).^2)).^.5;
v40 = (squeeze(vel40(:,:,:,1,:).^2) + squeeze(vel40(:,:,:,2,:).^2) + squeeze(vel40(:,:,:,3,:).^2)).^.5;

velx10_pla = vel10(:,:,:,1,:).*tot_mask;
vely10_pla = vel10(:,:,:,2,:).*tot_mask;
velz10_pla = vel10(:,:,:,3,:).*tot_mask;

velx40_pla = vel40(:,:,:,1,:).*tot_mask;
vely40_pla = vel40(:,:,:,2,:).*tot_mask;
velz40_pla = vel40(:,:,:,3,:).*tot_mask;

save(['R:\DRS-SWIRL\Activity 2 MRI\SWIRL_B_',SWIRL_ID,'_',visit_ID,'\PCA\SWIRL_B_',SWIRL_ID,'_',visit_ID,'_',scan_n,'_processed'],'velx10_pla','vely10_pla','velz10_pla','velx40_pla','vely40_pla','velz40_pla','bad_sl_b10','bad_sl_b40')











