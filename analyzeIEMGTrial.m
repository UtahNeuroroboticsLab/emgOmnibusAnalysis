function [snr, noise_rms, mean_peaks, ports, date] = analyzeIEMGTrial(file_path, vis, usea)
%%% MAT 20260417
%%% reads an individual omnibus file and returns SNR of the iEMG 
%%% electrodes.

%% DECLARE INPUTS
arguments (Input)
    file_path
    vis = 0 % assume no plotting unless otherwise stated
    usea = ''; % assume all useas unless otherwise stated
end

%% CONSTANTS
win_size = 990;

%% READ FILE
[ns5_header, ns5_data] = fastNSxRead('File', string(file_path)); % read file
date = ns5_header.TimeOrigin;

%% GEN TIME
Fs = ns5_header.Fs;
nip_time = 1:size(ns5_data,2);
time = nip_time./Fs;

%% SEPARATE NEURAL DATA

[ports] = parseOmnibusFname(file_path);

% separate data by port value
data_indx = [];
for port_num = 1:length(ports) 
    if contains(ports{port_num},'USEA')
        if isempty(usea) % check if a usea was specified
            if ~isempty(data_indx)
                data_indx = [data_indx data_indx(end)+1:data_indx(end)+96];
            else
                data_indx = [1:96];
            end % catch empty array
        else % specific usea desired
            if contains(ports{port_num},caseInsensitivePattern(usea)) % if current array is the specified array
                if ~isempty(data_indx)
                    data_indx = [data_indx data_indx(end)+1:data_indx(end)+96];
                else
                    data_indx = [1:96];
                end % catch empty array
            end
        end

    elseif contains(ports{port_num},'iEMG')
        if ~isempty(data_indx)
            % data_indx = [data_indx data_indx(end)+1:data_indx(end)+32];
        else
            % data_indx = [1:32];
        end % catch empty array
    end
end

neural_data = ns5_data(data_indx,:);
chan_count = length(data_indx);

% trim off excess
neural_data = neural_data(:,1:39*Fs);
global_time = time(1:39*Fs);

%% REMOVE BADA DATA SETS
if sum(any(abs(neural_data)>2*10^4,2)) == chan_count
    display('Bad data set...')
    error('Bad data set...')

elseif size(neural_data,2) < 39*30000

    display('Not enough data...')
    error('Not enough data...')
end

%% FILTER NEURAL DATA

% setup filter 
[filt_b,filt_a] = butter(4,750/(Fs/2),'high'); %butterworth filter (high-pass 750Hz) to use with FilterM (mex function for filtering)
% [filt_b,filt_a] = butter(4,[750/(Fs/2) 1500/(Fs/2)],'bandpass'); %butterworth filter (high-pass 750Hz) to use with FilterM (mex function for filtering)
[neural_data] = filter(filt_b,filt_a,neural_data);

%% SPLIT DATA INTO SECTIONS
rest_section = find(and(global_time > 32, global_time < 40)); % reste between 32 and 40 s
wrist_section = find(and(global_time > 21, global_time <= 32));
not_wrist = find(or(global_time < 20, global_time >= 32));

% %% TRIM BAD SECTIONS
% % remove wrist section
neural_data = neural_data(:,not_wrist);
global_time = global_time(:,not_wrist); % update global time
avg_data = movmean(neural_data,990,2); % calculate new average for visual

% motion artifact removal
neural_data = neural_data - avg_data;

%recompute avg
avg_data = movmean(neural_data,990,2); % calculate new average

% trim sections with motion artifacts (where mean exceeds a threshold)
motion = abs(avg_data) > 400; % find motion artifacts
no_motion = find(~(sum(motion,1) > 0));
% neural_data = neural_data(:,no_motion); % remove motion artifacts
% global_time = global_time(:,no_motion); % update global time
avg_data = movmean(neural_data,990,2); % calculate new average for visual


%% SPLIT DATA INTO SECTIONS AGAIN
rest_section = find(and(global_time > 31, global_time < 39)); % reste between 31 and 39 s
active_section = find(global_time < 29);

% split data
rest_data = neural_data(:,rest_section);
active_data = neural_data(:,active_section);

%% GET RESTING NOISE
noise_rms = std(rest_data,0,2);
thresh_rms = -5*noise_rms;

%% SPIKE COUNT

% offline spike count active data
[spikes,spike_count,peaks,my_thresh] = spikeCountOfflineMex(active_data,thresh_rms);

% offline spike count rest data
[~,rest_spike_count,~,~] = spikeCountOfflineMex(rest_data,thresh_rms);

%% SNR

% init var for storing peaks
mean_peaks = zeros([size(peaks,1),1]);
% calculate mean amplitude by channel
for ch = 1:size(peaks,1)
    ch_peaks = peaks(ch,:);
    ch_peaks(ch_peaks == 0) = [];
    if isempty(ch_peaks) % if no APs set to zero
        mean_peaks(ch) = 0;
    else % otherwise average channels
        mean_peaks(ch) = mean(ch_peaks);
    end
end

% SNR calculation from George JNER 2020. Not sure why the noise is
% halved?
snr = mean_peaks./(noise_rms.*2);


%% FIND ACTIVE ELECTRODES

% avg number of aps during rest
rest_spike_avg = mean(rest_spike_count);

% active electrodes are those that have more than 5*rest_spike_avg (GEORGE,
% JNER, 2020)
active_electrodes = and(spike_count > 5*rest_spike_avg, spike_count > 1);


%% VISUALIZE
% if date(2) == 6
%     vis_data = true;
% else
%     vis_data = false;
% end

% vis = 0; % override for debugging
if vis

    % analyze all data
    % offline spike count all data
    [spikes_all,spike_count_all,~,thresh_all] = spikeCountOfflineMex(neural_data,thresh_rms);

    for chan = 1:chan_count % loop over channels

        % check if channel has no active electrodes
        if ~active_electrodes(chan)
            continue; % if so skip
        end

        my_fig = figure();

        % plottin
        tiledlayout(2,1)
        ax1 = nexttile;
        hold on
        plot(global_time, neural_data(chan,:));
        plot(global_time, avg_data(chan,:));
        plot([0 40],[thresh_rms(chan) thresh_rms(chan)]);
        % plot(global_time(990:990:end),my_thresh(channel(end-chan),:));
        hold off
        ax2 = nexttile;
        hold on
        [ap_corr] = neuralXcorr(neural_data(chan,:));
        plot(global_time, ap_corr);
        plot(global_time(990:990:end),spikes_all(chan,:));
        hold off
        linkaxes([ax1 ax2],'x');

        % wait for key
        disp('Press "x" for a bad recording, otherwise press "n" for next...');
        key_val = char(' ');
        while (key_val ~= 'x' && key_val ~= 'n') % loop while waiting for x or c
            waitforbuttonpress;
            key_val = char(double(get(gcf,'CurrentCharacter')));
            if isempty(key_val) % for non character entries
                key_val = char(' ');
            end
        end
        if char(key_val) == 'x'
            active_electrodes(chan) = 0;
            disp('Channel removed...')
        end
        close(my_fig);
    end
end



end