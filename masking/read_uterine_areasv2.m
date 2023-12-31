%Produce the change in uterine area covered by placenta plots. Need to have
%the mask.mat file from mask_draw_uterine_areasv1.m, PAR_vol_timings.m and
%the corresponding .PAR file to the .nii that was masked.

%If this runs forever and doesn't load your PAR file (should take a few
%seconds) It is possible the PAR file format is inconsistent between the scan
%and the one I designed this on. Let me know and send me a copy of the PAR
%file you are struggling with and I will update the PAR read in function.

%I don't know if it's possible to get the timings from the .nii, the ones I
%convert don't have this information so I have to scrape it from the PAR


%Data is saved as a .xls for reading into excel in two seperate files:
%pla_stats.xls and uter_stats.xls. The first block of data are the areas,
%then there's an empty row and the lengths. Final row is the time. 
%Columns are volumes, rows are slices. 



clc
clear
warning('on')
addpath('.')

cd('R:\DRS-SWIRL\Activity 2 MRI')
[file,path] = uigetfile('*.PAR','Select the PAR file');
t = PAR_vol_timings([path,file]);
cd([path,'/..'])

[file,path] = uigetfile('*.nii*','Select the .nii file');
scan_hdr = niftiinfo([path,file]);
img = double(niftiread([path,file]));

[file,path] = uigetfile('*file.mat','Select the mask file');
load([path,file]);

dyn_check = zeros([1,length(t)]);

%If the file has been split the timings no longer line up with the volumes,
%to detect this check if the time array and the volumes match. If they
%don't then we need to realign the time array with the volumes
if length(t) ~= scan_hdr.ImageSize(4)
    disp('===Split file detected===')
    %For data sets split with split_n_data the volumes used are stored in
    %the description section of the header file. So you can rename the
    %files but make sure the header stays intact.
    vol_idx = str2num(scan_hdr.Description(9:end))+1;
    t = t(vol_idx);
end


%Due to an error in how the mask function handles lengths, I've had to make
%this analysis code a little heavier than it was intended to be. The below
%function is a rewiriting of partition_placenta_v03 using only the
%pos_store and uter_ID arrays to recreate the masks and calculate the
%lengths. Note this error does not affect the masks, they are still
%correct, just the calculations made using them were incorrect. 

for vol_n = 1:length(t)
    for slice_n = 1:size(pos_store.slice,2)
        try
            [pla_out,uter_out] = uter_placenta_stats(pos_store,uter_ID.slice(slice_n).volume(vol_n),slice_n,vol_n);
            pla_a(slice_n,vol_n) = sum(pla_out.area);
            pla_l(slice_n,vol_n) = sum(pla_out.length);
            uter_a(slice_n,vol_n) = uter_out.area;
            uter_l(slice_n,vol_n) = uter_out.length;
            
            %Calculate the intensity of the placenta
            pla_mask_tmp = poly2mask(pla_out.outline{1}(:,2),pla_out.outline{1}(:,1),size(img,1),size(img,2));
            if pla_out.area>1
                pla_int(slice_n,vol_n) = nanmean(nonzeros(img(:,:,slice_n,vol_n).*pla_mask_tmp));
            end
        end
    end
end

%Set NaNs to zero; if there are no voxels within a slice that are not NaNs or zero, then 
%nanmean(nonzeros()) will return a NaN, but these should be zero i.e. no
%voxels present
pla_int(isnan(pla_int)) = 0;


figure
imagesc(uter_l>0)
title('Masked slices')
ylabel('Slice')
xlabel('Volume')
set(gca,'fontsize',32)

%Calculate total areas
sum_uter_a = sum(uter_a);
t_uter = t;
t_uter = t_uter(1:size(sum_uter_a,2));
t_uter(sum_uter_a==0) = nan;
sum_uter_a(sum_uter_a==0) = nan;

sum_pla_a = sum(pla_a);
t_pla = t;
t_pla = t_pla(1:size(sum_pla_a,2));
t_pla(sum_pla_a==0) = nan;
sum_pla_a(sum_pla_a==0) = nan;

%Plot areas
figure
title('Areas')
subplot(2,1,1)
plot(t_uter,sum_uter_a,'linewidth',4)
ylabel('Total area (voxels)')
xlabel('Time (s)')
set(gca,'fontsize',32)
title('Uterus')
subplot(2,1,2)
plot(t_pla,sum_pla_a,'linewidth',4)
ylabel('Total area (voxels)')
xlabel('Time (s)')
set(gca,'fontsize',32)
title('Placenta')

%calculate lengths
sum_uter_l = sum(uter_l);
sum_uter_l(sum_uter_l==0) = nan;
sum_pla_l = sum(pla_l);
sum_pla_l(sum_pla_l==0) = nan;

%Plot lengths
figure
title('Lengths')
subplot(2,1,1)
plot(t_uter,sum_uter_l,'linewidth',4)
ylabel('Total length (voxels)')
xlabel('Time (s)')
set(gca,'fontsize',32)
title('Uterus')

subplot(2,1,2)
plot(t_pla,sum_pla_l,'linewidth',4)
ylabel('Total length (voxels)')
xlabel('Time (s)')
set(gca,'fontsize',32)
title('Placenta')
ylabel('Total length (voxels)')
xlabel('Time (s)')
set(gca,'fontsize',32)

pla_stats = [pla_a;zeros([1,size(pla_a,2)])*nan;pla_l;zeros([1,size(pla_a,2)])*nan;t_pla];
uter_stats = [uter_a;zeros([1,size(uter_a,2)])*nan;uter_l;zeros([1,size(uter_a,2)])*nan;t_uter];


%Write out data
xlswrite([path,file(1:end-13),'contractions_pla_stats.xls'],pla_stats);
xlswrite([path,file(1:end-13),'contractions_uter_stats.xls'],uter_stats);

save([path,file(1:end-13),'contractions_data'],'pla_a','pla_l','uter_a','uter_l','pla_int');
writematrix(transpose(t),[path,file(1:end-13),'time_table.txt']);
writematrix(transpose(pla_a),[path,file(1:end-13),'pla_a_table.txt']);
writematrix(transpose(pla_l),[path,file(1:end-13),'pla_l_table.txt']);
writematrix(transpose(uter_a),[path,file(1:end-13),'uter_a_table.txt']);
writematrix(transpose(uter_l),[path,file(1:end-13),'uter_l_table.txt']);
writematrix(transpose(pla_int),[path,file(1:end-13),'pla_int_table.txt']);




