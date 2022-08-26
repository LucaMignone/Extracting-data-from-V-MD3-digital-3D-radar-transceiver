% This script plot all the sweeps of raw ADC data

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
        fprintf(1,'Sweeps:         %i\n',sweeps);
        sens           = data(22); % Sensitivity
        fprintf(1,'Sensitivity:    %i\n',sens);
        
        textprogressbar('Converting:     ');
    end
    
%% Raw ADC data
% Create the variable 'signal' and fills it with real and imaginary part of data.
% signal: samples x chirps x channels x frames = 128 x 64 x 4 x 157(frames depending on file size) 

    if strcmp(cmd,'RADC')
        RAWdata=double(typecast(data,'int16'));       % ADC data is signed 16bit
              
        if ~exist('signal','var')
            signal = zeros(128,sweeps,4);             % Signal captured in a frame with structure: IQ samples X Sweep X Channels 
            frameS = 1;
            ch = 1;
        end

        tempStart = 1;                                % Initialise loop
        tempEnd = 256;                                % Samples * 2
        for sw=1:sweeps
            for ch=1:4
                signal(:,sw,ch,frameS) = RAWdata(tempStart:2:tempEnd)-1i*RAWdata(tempStart+1:2:tempEnd);
                tempStart = tempEnd+1;
                tempEnd = tempStart+255;
            end
        end

        frameS = frameS+1;

    end

    %% Frame number
    % If cmd = DONE, get the number of frames.   
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

fclose(fileID);
textprogressbar('');
fprintf(1,'Completed!\n');
%--------------------------------------------------------------------------


%% Plot results
% The matlab legend for plot shows 50 chirps instead of 64, it's a matlab
% limit.
fprintf(1,'=======================================================\n');
fprintf('\n            Plot of raw ADC data\n');
% Change the 3rd element to see 1,2,3 or 4th channel.
question1 = input('\nChoose the channel (1, 2, 3, 4): ');
switch question1
    case 1
        channel = 1;
    case 2
        channel = 2;
    case 3
        channel = 3;
    case 4
        channel = 4;
    otherwise
        fprintf('\nERROR ... Channel value out of range!');
end

signal_ch = squeeze(signal(:,:,channel,:));

question2 = input('\nEnter 1 for real part, 2 for imaginary part: ');
switch question2
    case 1
        signal_iq = real(signal_ch);
    case 2
        signal_iq = imag(signal_ch);
    otherwise
        fprintf('\nERROR ... Enter 1 or 2!');
end

plot(signal_iq(:,:,1))
xlabel('ADC sample number [km/h]'), ylabel('ADC sample number')
xlim([0, 128])

fprintf('\nPlotting results...\n');

str=sprintf('Frame: %i',frame(1));
fgTitle=sgtitle(str);
pause(1)

for ii=2:numel(frame)
    plot(signal_iq(:,:,ii))
    xlabel('ADC sample number'), ylabel('ADC bit value')
    xlim([0, 128])
    str=sprintf('Frame: %i',frame(ii));
    fgTitle.String=str;
    pause(0.01)
end

fprintf('\nDone! \n');
