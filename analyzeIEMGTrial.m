function [snr, ports, date] = analyzeIEMGTrial(file_path, vis)
%%% MAT 20260417
%%% reads an individual omnibus file and returns SNR of the iEMG 
%%% electrodes.

%% DECLARE INPUTS
arguments (Input)
    file_path
    vis = 0 % assume no plotting unless otherwise stated
end

%% READ FILE

% get data organization
[ports] = parseOmnibusFname(file_path);

% skip dataset if no iEMG
if ~any(contains(ports,'EMG'))
    error(['No iEMG in ' file_path '...']);
end

[ns5_header, ns5_data] = fastNSxRead('File', string(file_path)); % read file
date = ns5_header.TimeOrigin;

%% GEN TIME
Fs = ns5_header.Fs;
nip_time = 1:size(ns5_data,2);
time = nip_time./Fs;

%% SEPARATE NEURAL DATA



% separate data by port value
data_indx = [];
for port_num = 1:length(ports) 
    if contains(ports{port_num},'USEA')
        if ~isempty(data_indx)
            data_indx = [data_indx data_indx(end)+1:data_indx(end)+96];
        else
            data_indx = [1:96];
        end % catch empty array

    elseif contains(ports{port_num},'iEMG')
        if ~isempty(data_indx)
            % now toss all prior channel
            data_indx = [data_indx(end)+1:data_indx(end)+32];
        else
            data_indx = [1:32];
        end % catch empty array
    end
end

% get emg chans
emg_data = ns5_data(data_indx,:);

% get only relevant emg chans - only 20 implanted
emg_data = emg_data(1:20,:);

chan_count = length(data_indx);

% trim off excess
emg_data = emg_data(:,1:39*Fs);
global_time = time(1:39*Fs);

%% REMOVE BADA DATA SETS
if sum(any(abs(emg_data)>2*10^4,2)) == chan_count
    display('Bad data set...')
    error('Bad data set...')

elseif size(emg_data,2) < 39*Fs

    display('Not enough data...')
    error('Not enough data...')
end

%% FILTER NEURAL DATA

% setup high pass filter 
[filt_b,filt_a] = butter(6,15/(Fs/2),'high'); %butterworth filter (high-pass 15Hz)
[emg_data] = filter(filt_b,filt_a,emg_data);

% setup low pass filter 
[filt_b,filt_a] = butter(4,375/(Fs/2),'low'); %butterworth filter (low-pass 375Hz)
[emg_data] = filter(filt_b,filt_a,emg_data);

% setup notch filter 
filt_d = designfilt("notchiir", ...
    FilterOrder=[6 6 6],CenterFrequency=[60 120 180], ...
    QualityFactor=[5 5 5],PassbandRipple=1, ...
    SampleRate=Fs,SystemObject=true);
[emg_data] = filt_d(emg_data);

%% SPLIT DATA INTO SECTIONS
rest_section = find(and(global_time > 32, global_time < 40)); % reste between 32 and 40 s
wrist_section = find(and(global_time > 21, global_time <= 32));
not_wrist = find(or(global_time < 20, global_time >= 32));


%% SPLIT DATA INTO SECTIONS AGAIN
rest_section = find(and(global_time > 31, global_time < 39)); % reste between 31 and 39 s
active_section = find(global_time < 29);

% split data
rest_data = emg_data(:,rest_section);
active_data = emg_data(:,active_section);

%% GET RESTING NOISE
noise_rms = std(rest_data,0,2);
thresh_rms = -5*noise_rms;

%% MAV

mav = [];
sample = 1;

% loop over data computing mav for chunks of 33 ms
for kk = 1:0.033*Fs:size(emg_data,2)-0.033*Fs
    
    mav(:,sample) = mean(abs(emg_data(:,kk:kk+0.033*Fs)),2);
    sample = sample + 1;

end % looping mav calc

%% SNR

snr = max(mav,[],2)./min(mav,[],2);


end