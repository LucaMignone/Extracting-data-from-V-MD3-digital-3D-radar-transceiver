1% This script plot the range-doppler map of selected file.

clear all
close all
clc

%% Open file
% Open the file, read it and extract the file size, then return at
% the beginning for future operations.

fileID = fopen('Record_2022-08-01_11-07-49.bin');
file = fread(fileID);
fileSize = ftell(fileID);       % File size

fseek(fileID,0,-1);             % Rewind at the begining

%% Startup Screen
Version = 'V-MD3_CTP-RFB-0104'; % Version that the script was developed on
fprintf(1,'Welcome to RFbeam V-MD3 Radar Reader %s\n',Version);
fprintf(1,'=======================================================\n');

%% Scroll through the file
% the while loop is useful to scroll through the file. If you don't use it,
% the cmd remain the first 4 characters'RPST'.

while ftell(fileID)<fileSize
    cmd = convertCharsToStrings(fread(fileID,4,'*char'));      % extract command
    length=fread(fileID,1,'int32');                            % expected length of data
    if((length>0)&&(length<1048576))                           % data length within 'useful' bounds (from user manual script)
        data=uint8(fread(fileID,length,'uint8'));
    end
    
    %% Test Header command
    % If cmd, formed by 4 characters, is not equal to RPST,PDAT,DONE, etc,
    % say 'Unknown header!'.

    if ~(strcmp(cmd,'RPST')||strcmp(cmd,'RADC')||strcmp(cmd,'RFFT')||...
         strcmp(cmd,'RMRD')||strcmp(cmd,'PDAT')||strcmp(cmd,'TDAT')||...
         strcmp(cmd,'DONE'))
        textprogressbar('Unknown header!')
        textprogressbar('Converting:     ');
    end

    %% Radar Configuration
    if strcmp(cmd,'RPST')
        soft_ver = convertCharsToStrings(char(data(1:19)));
        FPGA_ver = data(20);
        [mode,max_range,max_speed,samples,sweeps] = radar_setting(data(21));
        fprintf(1,'Application:    %s\n',soft_ver); % output information for user
        fprintf(1,'FPGA-Version:   %i\n',FPGA_ver);
        fprintf(1,'Mode:           %s\n',mode);
        fprintf(1,'Max Range:      %i m\n',max_range);
        fprintf(1,'Max Speed:      %i km/h\n',max_speed);
        fprintf(1,'Sweeps:         %i\n',sweeps); % Credo siano i chirp
        sens           = data(22); % Sensitivity
        fprintf(1,'Sensitivity:    %i\n',sens);
        
        textprogressbar('Converting:     ');
    end
    

    %% Averaged mean range Doppler map
    % Converts data after string RMRD in int16, then in double.
    % Initialize the RDmap, then reshape [data x sweeps x samples] in 
    % [samples x sweeps] from data and puts them in a 3D matrix:
    % samples x sweeps x frames (frames depends on acquisition).

    if strcmp(cmd,'RMRD')
        RMRDdata=double(typecast(data,'uint16'));                   
        
        if ~exist('RDmap','var')
            RDmap = zeros(128,sweeps);  % Averaged and logarithmized RD maps based on raw
            frameRD = 1;
        end

        RDmap(:,:,frameRD) = reshape(RMRDdata,sweeps,128).'; 
        frameRD = frameRD+1;
    end
   

    %% Frame number
    if strcmp(cmd,'DONE')                          
       if ~exist('frame','var')
        frameF = 1;
       end
       frame(frameF)=typecast(data(1:4),'uint32');
       frameF = frameF+1;
    end
   
    %% Update progress
    textprogressbar((ftell(fileID)/fileSize)*100);    

end % end of while loop
% 
fclose(fileID);
textprogressbar('');
fprintf(1,'Completed!\n');

%--------------------------------------------------------------------------



%% Plot results
% Plot the imagesc of the 1st frame of the RDmap, then with a for cycle
% plot the remaining frames.
% Notice that there is a minus before max_speed to get the match with the 
% control panel. 

fprintf(1,'=======================================================\n');
fprintf('Plotting results...\n');

% Range Dopple map
figRD = imagesc(-max_speed*(-sweeps/2:sweeps/2-1)/(sweeps/2),...
               max_range*(0:samples-1)/samples,...
               RDmap(:,:,1));
set(gca, 'YDir','normal')
colormap('jet')
xlabel('<--- Approaching      Speed [km/h]       Receding --->'), 
ylabel('Distance [m]')
xlim([-9.7, 10]), ylim([0, 6]) 

str=sprintf('Frame: %i',frame(1));
fgTitle=sgtitle(str);
pause(1)
     
 for ii=2:numel(frame)
     figRD.CData =  RDmap(:,:,ii);
     str=sprintf('Frame: %i',frame(ii));
     fgTitle.String=str;
     pause(0.05) % how fast frames are displayed
 end

fprintf('Done! \n');


% Radar Control panel: 3023 - 3178 = 155 frames
% Here 177 frames


