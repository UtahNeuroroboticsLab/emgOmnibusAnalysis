function [omnibus] = plotSNR(omnibus_path, save_path)
%PLOTSNR plots the SNR across time measured from
%Omnibus bus recordings in "folder_path". Additionally plots the signal and
%noise values in time. Saves files to save_path if provided.
%
% MAT 20260507

%% DEFINE INPUTS
arguments (Input)
    omnibus_path char % mandatory input
    save_path string = "" % default to no path
end

%% GET DATA
[omnibus] = iemgDatasetAnalysis(omnibus_path);

%% GATHER DATA

% loop through omnibus data
for kk = 1:length(omnibus)

    % get active electrodes from omnibus data
    snrs = omnibus(kk).snr;
    sigs = omnibus(kk).signal;
    noise = omnibus(kk).noise;

    % add to data table
    temp_table = table(repmat(omnibus(kk).dsi,[size(snrs,1) 1]),snrs,sigs,noise);
    if exist('emg_table')
        emg_table = [emg_table; temp_table];
    else
        emg_table = temp_table;
    end

end% looping through omnibus


% sort by date
emg_table = sortrows(emg_table);

%% PLOT SNR DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(emg_table.Var1, emg_table.snrs);

xlabel('Days since Implant');
ylabel('SNR');
title('SNR Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\snrDSI-emg.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\snrDSI-emg.png'];
    saveas(gcf, fname, 'png');
end

%% PLOT SIGNAL DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(emg_table.Var1, emg_table.sigs);

corrcoef(emg_table.Var1, emg_table.sigs)

xlabel('Days since Implant');
ylabel('Amplitude');
title('Signal Amp Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\pkSignalDS-emg.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\pkSignalDS-emg.png'];
    saveas(gcf, fname, 'png');
end

%% PLOT SNR DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(emg_table.Var1, emg_table.noise);

corrcoef(emg_table.Var1, emg_table.sigs);

xlabel('Days since Implant');
ylabel('Noise');
title('Noise Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\noiseDSI-emg.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\noiseDSI-emg.png'];
    saveas(gcf, fname, 'png');
end
end