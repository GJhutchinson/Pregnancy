clc
clear
%Cut a nifti into a certain number of volumes
%The script uses GUIs to open the .nii and choose the output location 

%Then it will ask you how many files to cut the data into: 
% 1 - Just 1 file (can be used to cut out certain volumes)
% 2+ Will cut data into 2+ files depending on the volumes you supply

%The split volumes will be output as a .nii with an edited header file, do
%not change the header if you wish to use read_uterine_areas, however you
%can change the file names. 


[file,path] = uigetfile('*.nii*','Select the NIfTI to split');
scan = niftiread([path,file]);%Load data using GUI
scan_hdr = niftiinfo([path,file]);%Load header
[save_dir] = uigetdir('','Select the directory to save the output to');

disp(['Scan has ',num2str(size(scan,4)-1),' volumes'])%Disp volumes
f_info = whos('scan');
disp(['Filesize ',num2str(f_info.bytes*1e-9),' GB'])%Disp filesize
disp('............')
disp('This file uses the same indexing as MIPAV (start counting from 0)')
%If you select 1 you can just cut out 1 section
n_splits = input('How many files do you want to cut the data into? (enter an integer): ');


disp('............')


for n = 1:n_splits
   disp('............')
   disp(['Scan has ',num2str(size(scan,4)-1),' volumes'])
   %Take first and last volume required
    start_idx_tmp = input(['File ',num2str(n),'/',num2str(n_splits), ' Enter first volume: ']);
    end_idx_tmp = input(['File ',num2str(n),'/',num2str(n_splits), ' Enter last volume: ']);
    %Cut down to size
    scan_tmp = scan(:,:,:,start_idx_tmp+1:end_idx_tmp+1);
    %Copy header
    hdr_tmp = scan_hdr;
    %Edit header to match new size
    hdr_tmp.ImageSize(4) = length(start_idx_tmp:end_idx_tmp);
    %Add description to header for read_uterine_areas
    hdr_tmp.Description = ['Volumes ',num2str(start_idx_tmp),':',num2str(end_idx_tmp)];
    disp('File split')
    %Save file
    if strcmp(file(end-6:end),'.nii.gz')
        niftiwrite(scan_tmp,[save_dir,'\',file(1:end-7),'vol_',num2str(start_idx_tmp),'_to_',num2str(end_idx_tmp)],hdr_tmp)
    else
        niftiwrite(scan_tmp,[save_dir,'\',file(1:end-4),'vol_',num2str(start_idx_tmp),'_to_',num2str(end_idx_tmp)],hdr_tmp)
    end
    clear scan_tmp
    disp('............')
end





