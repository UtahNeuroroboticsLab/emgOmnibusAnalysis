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
[omnibus] = neuralSignalAnalysis(omnibus_path);

%% ORGANIZE DATA BY USEA

% loop through omnibus data
for kk = 1:length(omnibus)

    % clear electrode indx
    electrode_indx = 1;

    % loop through ports
    for port = 1:length(omnibus(kk).ports)
        % get current port
        curr_port = omnibus(kk).ports{port};

        % handle each option
        if contains(curr_port,'NA') %skip disconnected ports
            continue;

        elseif contains(curr_port,'USEA1')
            % get active electrodes from omnibus data
            snrs = omnibus(kk).snr(electrode_indx:electrode_indx+95);
            sigs = omnibus(kk).signal(electrode_indx:electrode_indx+95);
            noise = omnibus(kk).noise(electrode_indx:electrode_indx+95);

            % remove bad channels
            active_channels = omnibus(kk).active_electrodes(electrode_indx:electrode_indx+95);
            snrs = snrs(active_channels);
            sigs = sigs(active_channels);
            noise = noise(active_channels);

            % remove inactive channels
            sigs(snrs == -1) = [];
            sigs(snrs == 0) = [];
            noise(snrs == -1) = [];
            noise(snrs == 0) = [];
            snrs(snrs == -1) = [];
            snrs(snrs == 0) = [];
            
            % add to data for usea1
            temp_table = table(repmat(omnibus(kk).dsi,[size(snrs,1) 1]),snrs,sigs,noise);
            if exist('usea1_table')
                usea1_table = [usea1_table; temp_table];
            else
                usea1_table = temp_table;
            end

            % update electrode indx
            electrode_indx = electrode_indx + 96;

        elseif contains(curr_port,'USEA2')
            % get active electrodes from omnibus data
            snrs = omnibus(kk).snr(electrode_indx:electrode_indx+95);
            sigs = omnibus(kk).signal(electrode_indx:electrode_indx+95);
            noise = omnibus(kk).noise(electrode_indx:electrode_indx+95);

            % remove bad channels
            active_channels = omnibus(kk).active_electrodes(electrode_indx:electrode_indx+95);
            snrs = snrs(active_channels);
            sigs = sigs(active_channels);
            noise = noise(active_channels);

            % remove inactive channels
            sigs(snrs == -1) = [];
            sigs(snrs == 0) = [];
            noise(snrs == -1) = [];
            noise(snrs == 0) = [];
            snrs(snrs == -1) = [];
            snrs(snrs == 0) = [];
            
            % add to data for usea2
            temp_table = table(repmat(omnibus(kk).dsi,[size(snrs,1) 1]),snrs,sigs,noise);
            if exist('usea2_table')
                usea2_table = [usea2_table; temp_table];
            else
                usea2_table = temp_table;
            end

            % update electrode indx
            electrode_indx = electrode_indx + 96;


        elseif contains(curr_port,'USEA3')
            % get active electrodes from omnibus data
            snrs = omnibus(kk).snr(electrode_indx:electrode_indx+95);
            sigs = omnibus(kk).signal(electrode_indx:electrode_indx+95);
            noise = omnibus(kk).noise(electrode_indx:electrode_indx+95);

            % remove bad channels
            active_channels = omnibus(kk).active_electrodes(electrode_indx:electrode_indx+95);
            snrs = snrs(active_channels);
            sigs = sigs(active_channels);
            noise = noise(active_channels);

            % remove inactive channels
            sigs(snrs == -1) = [];
            sigs(snrs == 0) = [];
            noise(snrs == -1) = [];
            noise(snrs == 0) = [];
            snrs(snrs == -1) = [];
            snrs(snrs == 0) = [];

            % add to data for usea3
            temp_table = table(repmat(omnibus(kk).dsi,[size(snrs,1) 1]),snrs,sigs,noise);
            if exist('usea3_table')
                usea3_table = [usea3_table; temp_table];
            else
                usea3_table = temp_table;
            end

            % update electrode indx
            electrode_indx = electrode_indx + 96;



        elseif contains(curr_port,'iEMG')
            % skip iEMG spiking
            % update electrode indx
            % electrode_indx = electrode_indx + 32;


        end % if else for different arrays


    end % looping through ports


end% looping through omnibus


% sort by date
usea1_table = sortrows(usea1_table);
usea1_table = sortrows(usea1_table);
usea1_table = sortrows(usea1_table);

%% PLOT SNR DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(usea1_table.Var1, usea1_table.snrs);
boxchart(usea2_table.Var1, usea2_table.snrs);
boxchart(usea3_table.Var1, usea3_table.snrs);

xlabel('Days since Implant');
ylabel('SNR');
title('SNR Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\snrDSI.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\snrDSI.png'];
    saveas(gcf, fname, 'png');
end

%% PLOT SIGNAL DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(usea1_table.Var1, usea1_table.sigs);
boxchart(usea2_table.Var1, usea2_table.sigs);
boxchart(usea3_table.Var1, usea3_table.sigs);

corrcoef(usea1_table.Var1, usea1_table.sigs)
corrcoef(usea2_table.Var1, usea2_table.sigs)
corrcoef(usea3_table.Var1, usea3_table.sigs)


xlabel('Days since Implant');
ylabel('Amplitude');
title('Signal Amp Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\pkSignalDS.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\pkSignalDS.png'];
    saveas(gcf, fname, 'png');
end

%% PLOT SNR DATA
figure()
% Plot active electrodes for each USEA
hold on;
boxchart(usea1_table.Var1, usea1_table.noise);
boxchart(usea2_table.Var1, usea2_table.noise);
boxchart(usea3_table.Var1, usea3_table.noise);

corrcoef(usea1_table.Var1, usea1_table.noise)
corrcoef(usea2_table.Var1, usea2_table.noise)
corrcoef(usea3_table.Var1, usea3_table.noise)


xlabel('Days since Implant');
ylabel('Noise');
title('Noise Over Time');
legend show;
hold off;

% save plot if given a save path
if save_path ~= ""
    fname = [char(save_path) '\noiseDSI.svg'];
    saveas(gcf, fname, 'svg');
    fname = [char(save_path) '\noiseDSI.png'];
    saveas(gcf, fname, 'png');
end
end