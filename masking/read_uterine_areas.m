%Produce the change in uterine area covered by placenta plots. Need to have
%the mask.mat file from mask_draw_uterine_areasv1.m, PAR_vol_timings.m and
%the corresponding .PAR file to the .nii that was masked.

%If this runs forever and doesn't load your PAR file (should take a few
%seconds) It is possible the PAR file format is inconsistent between the scan
%and the one I designed this on. Let me know and send me a copy of the PAR
%file you are struggling with and I will update the PAR read in function.

%I don't know if it's possible to get the timings from the .nii, the ones I
%convert don't have this information so I have to scrape it from the PAR

%If you have split the data into two you need to know where the data was
%split... We may have to figure out a way to deal with 3/4 way splits even.
%Can you save information directly to the NIfTI header??


clc
clear
warning('on')

[file,path] = uigetfile('*.PAR','Select the PAR file');
t = PAR_vol_timings([path,file]);
cd R:/

[file,path] = uigetfile('*.nii','Select the .nii file');
scan_hdr = niftiinfo([path,file]);

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

%Do first for Uterus, since all masked slices MUST contain uterus mask
for dyn = 1:length(t)
    for slice_n = 1:size(pla_roi.slice,2)%For each slice
        try %Go through each slice and see if there is volume information
            if ~isempty(pla_roi.slice(slice_n).volume(dyn).uter_length) %Get uter length if availible
                uter_l(slice_n,dyn) = pla_roi.slice(slice_n).volume(dyn).uter_length;
            end
        end
    end
end
%Then do placenta 2nd. Not every slice with a uterus mask will have a
%placental mask; BUT the arrays must be the same size to figure out
%percentages later on
pla_l = zeros(size(uter_l));

for dyn = 1:length(t)
    for slice_n = 1:size(pla_roi.slice,2)%For each slice
        try %Go through each slice and see if there is volume information
            for pla_obj = 1:size(pla_roi.slice(slice_n).volume(dyn).length,2)%For all placental ROIs in slice
                pla_l(slice_n,dyn) = pla_roi.slice(slice_n).volume(dyn).length{pla_obj}{1};%define region covered by placenta
                if pla_obj>1%If more placental objects, add these to above
                     pla_l(slice_n,dyn) = pla_l(slice_n,dyn)+ pla_roi.slice(slice_n).volume(dyn).length{pla_obj}{1};
                end
                
            end
        end
    end
end

%Check for mismatched masking (i.e. a slice on one dynamic, but not on
%another)
uter_log = uter_l>0;
imagesc(uter_log>0)
ylabel('Slices')
xlabel('Volume')

set(gca,'fontsize',32)

t = t(1:size(uter_log,2)); %Not all time points will be used


%Total lengths
not_covered_l = sum((uter_l - pla_l));
total_l = sum(uter_l);
covered_l = sum(pla_l);


plot(t,not_covered_l./not_covered_l(1),'linewidth',4)
hold on
plot(t,covered_l./covered_l(1),'linewidth',4)
set(gca,'fontsize',32)
legend('Not covered','Covered')
xlabel('Time (s)')
ylabel('Fraction of t(0) length')













