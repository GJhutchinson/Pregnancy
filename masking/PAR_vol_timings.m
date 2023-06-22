function t = PAR_vol_timings(fpt)
%fpt = 'R:\DRS-SWIRL\Activity 2 MRI\SWIRL_005\PARREC\SWIRL_005_WIP_contractions_MB2_6mm_16_1.PAR'; % absolute or relative path to where the file is saved.
fileID = fopen(fpt);
%Scan through PAR file until the dynamic timings start
%Just let this be a non empty array
line_ex = ['a'];
%Check for this line
while ~strcmpi(line_ex,"#  sl ec  dyn ph ty    idx pix scan% rec size                (re)scale              window        angulation              offcentre        thick   gap   info      spacing     echo     dtime   ttime    diff  avg  flip    freq   RR-int  turbo delay b grad cont anis         diffusion       L.ty  contagent   controute  contvolume  conttime  contdose  contingr  contingrconcen")
    line_ex = fgetl(fileID);
end
%That line signifies the start of the timing information
%Next line is blank
line_ex = fgetl(fileID);
%This is the first line of data
line_ex = fgetl(fileID);
%Preset dynamic number 1 and loop counter
dyn(1) = 1;
c = 2;
while ~isempty(line_ex)~=0 %Until you reach the end
    if dyn(c-1) ~= str2double(line_ex(10:12))%If this is a new dynamic
        dyn(c) = str2double(line_ex(10:12));%Save dynamic #
        t(c)=  str2double(line_ex(182:189));%Save time
        c = c+1;
    end
  line_ex = fgetl(fileID);%Next line
end
fclose(fileID);