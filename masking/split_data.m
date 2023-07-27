%Contraction data splitter: Indexing was designed to match MIPAV (i.e.
%starts counting from 0)
clc
clear

[file,path] = uigetfile('*.nii','Select the NIfTI to split');
scan = niftiread([path,file]);%Load data using GUI
[save_dir] = uigetdir('','Select the directory to save the output to');

disp(['Scan has ',num2str(size(scan,4)-1),' volumes'])%Disp volumes
f_info = whos('scan');
disp(['Filesize ',num2str(f_info.bytes*1e-9),' GB'])%Disp filesize
split_idx = input('Enter index to split data: ');

scan_1 = scan(:,:,:,1:split_idx+1);
scan_1_info = whos('scan_1');
disp(['Scan 1 ',num2str(size(scan_1,4)),' volumes ',num2str(scan_1_info.bytes*1e-9),' GB'])
niftiwrite(scan_1,[save_dir,'/',file(1:end-4),'split_1'])

scan_2 = scan(:,:,:,split_idx+2:end);
scan_2_info = whos('scan_2');
disp(['Scan 2 ',num2str(size(scan_2,4)),' volumes ',num2str(scan_2_info.bytes*1e-9),' GB'])
niftiwrite(scan_2,[save_dir,'/',file(1:end-4),'split_2'])
