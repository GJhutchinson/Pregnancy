%Contraction data splitter: Indexing was designed to match MIPAV (i.e.
%starts counting from 0)

%Run the code, then select the NIfTI you wish to split in two using
%the GUI, then select the directory to save out to. It will then ask you
%which volume to cut the data at (counting from 0), the data will be split
%into two NIfTI files: 
%original_name_split_1.nii and
%originial_name_split_2.nii
% where the first file contains volumes 0:selected volume
% and the second contains volumes selected volume+1:end. 

clc
clear

[file,path] = uigetfile('*.nii*','Select the NIfTI to split');
scan = niftiread([path,file]);%Load data using GUI
scan_hdr = niftiinfo([path,file]);%Load header
[save_dir] = uigetdir('','Select the directory to save the output to');

disp(['Scan has ',num2str(size(scan,4)-1),' volumes'])%Disp volumes
f_info = whos('scan');
disp(['Filesize ',num2str(f_info.bytes*1e-9),' GB'])%Disp filesize
split_idx = input('Enter index to split data: ');

scan_1 = scan(:,:,:,1:split_idx+1);%Split to scan_1
scan_1_info = whos('scan_1');
scan_1_hdr = scan_hdr;
scan_1_hdr.ImageSize = [];
scan_1_hdr.Description = ['Volumes 1:',num2str(split_idx+1)]
disp(['Scan 1 ',num2str(size(scan_1,4)),' volumes ',num2str(scan_1_info.bytes*1e-9),' GB'])
niftiwrite(scan_1,[save_dir,'/',file(1:end-4),'split_1_test'],scan_1_hdr)
clear scan_1

scan_2 = scan(:,:,:,split_idx+2:end);%split to scan_2
scan_2_info = whos('scan_2');
disp(['Scan 2 ',num2str(size(scan_2,4)),' volumes ',num2str(scan_2_info.bytes*1e-9),' GB'])
niftiwrite(scan_2,[save_dir,'/',file(1:end-4),'split_2_test'],scan_2_hdr)
