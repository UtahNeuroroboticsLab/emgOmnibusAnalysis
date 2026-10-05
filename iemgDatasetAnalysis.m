function [omnibus] = iemgDatasetAnalysis(omnibus_path)
%%% MAT 20260417
%%% parses all ns5 files files located in the [omnibus_path] directory and
%%% sub directories and computes the snr for the iemg channels

%% CHECK SAVED DATA
try
    load(fullfile(omnibus_path, 'iemg_data.mat'));
    % finished paths (skip if already analyzed)
    fin_files = {omnibus.path};
    fin_files(cellfun('isempty',fin_files))=[];

catch
    display('No data found...')
    display('Running from scratch...')
    fin_files = {'none'};
    omnibus = struct();
    omnibus.snr = [];
    omnibus.noise = [];
    omnibus.signal = [];
    omnibus.ports = [];
    omnibus.date = [];
    omnibus.dsi = [];
    omnibus.path = [];
end


%% PARSE PATH

folder_list = dir(omnibus_path); % get list of folders
folder_list(1:2) = []; % clear pathing paths
folder_list([folder_list.isdir]==0) = []; % clear irrelevant file paths
folder_list(contains({folder_list.name},'bad_data')) = [];

%% LOOP THROUGH FOLDERS

for curr_rec = 1:length(folder_list)
    
    % get path
    subfolder_path = fullfile(folder_list(curr_rec).folder, folder_list(curr_rec).name);

    display(['Parsing Omnibus from date ' folder_list(curr_rec).name]);
    
    % get ns5 file
    ns5_files = dir(subfolder_path);
    ns5_files(~contains({ns5_files.name},'ns5')) = [];

    % loop through ns5 files
    for file_indx = 1:length(ns5_files)

        % get current full path
        file_path = fullfile(ns5_files(file_indx).folder, ns5_files(file_indx).name);

        % check if file has already been analyzed and saved, if so skip
        if any(contains(fin_files,file_path))
            display(['Skipping Omnibus file ' ns5_files(file_indx).name]);
            continue;
        end

        display(['Parsing Omnibus file ' ns5_files(file_indx).name]);

        try
            % Load the ns5 file and analyze the active electrodes
            [snr, ports, date] = analyzeIEMGTrial(file_path,1); % turned on visualization for selecting bad recordings

            % generate temp struct
            temp.active_electrodes = active;
            temp.snr = snr;
            temp.ports = ports;
            temp.date = datetime(date([1,2,4,5,6,7]));
            temp.dsi = caldays(between(datetime('20260127','Format','yyyyMMdd'),temp.date,'days'));
            temp.path = file_path;

            % append to main data struct
            omnibus = [omnibus,temp];

        catch
            display('Errored out...')
        end

    end % looping through files in file_path
end % loop through folders

%% SAVE DATA
% clear empty entries
file_list = {omnibus.path};
omnibus(cellfun('isempty',file_list))=[];


save(fullfile(omnibus_path, 'omnibus_data.mat'), 'omnibus');

end