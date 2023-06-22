%Produce the change in uterine area covered by placenta plots. Need to have
%the mask.mat file from mask_draw_uterine_areasv1.m, PAR_vol_timings.m and
%the corresponding .PAR file to the .nii that was masked.

%If this runs forever and doesn't load your PAR file (should take a few
%seconds) It is likely the PAR file format is inconsistent between the scan
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
for dyn = 1:length(t)
    for slice_n = 1:size(pla_roi.slice,2)%For each slice
        try %Go through each slice and see if there is volume information
            if ~isempty(pla_roi.slice(slice_n).volume(dyn).uter_length) %Get uter length if availible
                uter_l(slice_n,dyn) = pla_roi.slice(slice_n).volume(dyn).uter_length;
            end
            
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
pla_log = pla_l>0;

uter_log_previous = uter_log(:,1);
pla_log_previous = pla_log(:,1);

for n = 2:length(t)
    uter_log_new = uter_log(:,2);
    pla_log_previous = pla_log(:,2);
    
    if sum(uter_log_new ~= uter_log_previous)>0
        slice_mismatch = num2str(find(uter_log_new ~= uter_log_previous))
        warning(['Mismatch between masks on volume: ',num2str(n-1),'/',num2str(n),' slice(s): '])
        for slice_n = 1:length(slice_mismatch)
           warning(['Slice: ',num2str(slice_mismatch(slice_n))]) 
            
        end
    end
end

total_uter_l = sum(uter_l-pla_l);
total_uter_0 = total_uter_l(find(total_uter_l,1));
uter_percent = total_uter_l./total_uter_0;
uter_idx = (~uter_percent==0);

total_pla_l = sum(pla_l);
total_pla_0 = total_pla_l(find(total_pla_l,1));
pla_percent = total_pla_l./total_pla_0;
pla_idx = (~pla_percent==0);

t_plot = t(logical(dyn_check));

plot(t(uter_idx),uter_percent(uter_idx)-1,'x-','linewidth',4)
hold on
plot(t(pla_idx),pla_percent(pla_idx)-1,'x-','linewidth',4)

ylabel('Fraction change')
xlabel('t (s)')
legend('Not covered by placenta','Covered by placenta')
set(gca,'fontsize',32)
ylim([-1 1])





