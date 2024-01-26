function t = PAR_vol_timings(fpt)
%This function is for reading in the timings from the contractions scan
%from the .PAR file directly. Note sometimes this code can hang, if it is
%taking longer than 2/3 minutes kill the code and send me a message (George.Hutchinson1@nottingham.ac.uk)
%I can look into it for you

%Format: t = PAR_vol_timings(fpt)
% fpt is the path+name of the .PAR file you are trying to get times
%from. 
%t is a 1xn array containing the time that each dynamic was
%Example Usage:  time = PAR_vol_timings('My_scan.PAR')

%This isn't the most efficient implementation; it simply scans through each
%line of text looking for specific lines. The issue is there will be an
%unkown number of lines of text; but each PAR file should be identical so
%it should be fine.



fileID = fopen(fpt);
%Scan through PAR file until the dynamic timings start
%Just let this be a non empty array
line_ex = ['a'];
%Check for this line
while ~strcmpi(line_ex,"# === IMAGE INFORMATION ==========================================================")
    line_ex = fgetl(fileID);
end
%That line signifies the start of the timing information
%Next line is blank
line_ex = fgetl(fileID);
line_ex = fgetl(fileID);
%This is the first line of data
line_ex = fgetl(fileID);
%Preset dynamic number 1 and loop counter
dyn(1) = 1;
c = 2;
while ~isempty(line_ex)~=0 %Until you reach the end
    if dyn(c-1) ~= str2double(line_ex(10:12))%If this is a new dynamic
        %After the 100th dynamic the time gets shifted by a column to
        %accomodate the extra digit 
        if str2double(line_ex(10:12)) < 100
            dyn(c) = str2double(line_ex(10:12));%Save dynamic #
            t(c)=  str2double(line_ex(182:189));%Save time
            c = c+1;
        else
            dyn(c) = str2double(line_ex(10:12));%Save dynamic #
            t(c)=  str2double(line_ex(183:190));%Save time
            c = c+1;
        end
    end
  line_ex = fgetl(fileID);%Next line
end
fclose(fileID);