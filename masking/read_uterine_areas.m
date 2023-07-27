%Produce the change in uterine area covered by placenta plots. Need to have
%the mask.mat file from mask_draw_uterine_areasv1.m, PAR_vol_timings.m and
%the corresponding .PAR file to the .nii that was masked.

%If this runs forever and doesn't load your PAR file (should take a few
%seconds) It is possible the PAR file format is inconsistent between the scan
%and the one I designed this on. Let me know and send me a copy of the PAR
%file you are struggling with and I will update the PAR read in function.

%I don't know if it's possible to get the timings from the .nii, the ones I
%convert don't have this information so I have to scrape it from the PAR
clc
clear
warning('on')

[file,path] = uigetfile('*.PAR','Select the PAR file');
t = PAR_vol_timings([path,file]);


[file,path] = uigetfile('*file.mat','Select the mask file');
load([path,file]);

dyn_check = zeros([1,length(t)]);

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

%First dynamic
uter_log_previous = uter_log(:,1);
for n = 2:length(t)
    %Take current dynamic
    uter_log_new = uter_log(:,n);
    
    if sum(uter_log_new ~= uter_log_previous)>0 && sum(uter_log_previous)~=0%Check if the same slices are masked
        %If not- figure out the volume/slices and print a warning
        uter_mismatch = num2str(find(uter_log_new ~= uter_log_previous));
        warning(['Mismatch between masks on volumes: ',num2str(n-1),' and ',num2str(n),' slice(s): '])
        for slice_n = 1:length(uter_mismatch)
           disp(['Slice: ',num2str(uter_mismatch(slice_n,:))]) 
        end
        clear uter_mismatch
    end
    %Store current dynamic and then compare to the next
    uter_log_previous = uter_log(:,n);
end

%Total lengths
not_covered_l = sum((uter_l - pla_l));
total_l = sum(uter_l);
covered_l = sum(pla_l);

not_covered_l(1:75) = 0;
total_l(1:75) = 0;
covered_l(1:75) = 0;

%Find first non-zero i.e. first results
frac_idx = find(total_l>0);

%As a fraction of t(0)
not_covered_frac = (not_covered_l./not_covered_l(frac_idx(1)));
covered_frac = (covered_l./covered_l(frac_idx(1)));

%Only take non-zero
not_covered_frac = not_covered_frac(frac_idx);
covered_frac = covered_frac(frac_idx);

plot(t(frac_idx)-t(frac_idx(1)),not_covered_frac,'x-','linewidth',4,'markersize',14)
hold on
plot(t(frac_idx)-t(frac_idx(1)),covered_frac,'x-','linewidth',4,'markersize',14)
legend('not covered','covered')
ylabel('Fraction of value at t(0)')
xlabel('Time (s)')
set(gca,'fontsize',32)








