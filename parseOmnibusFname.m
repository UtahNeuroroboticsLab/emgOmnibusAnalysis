function [port_labels] = parseOmnibusFname(file_path)
%%% MAT 20260420
%%% reads ports from omnibus filename formatted as
%%% 'A_data+B_data+C_data+D_data.ns5'

% parse filename to figure out ports
ports = regexp(file_path, 'A_', 'split'); 
ports = ports{2};% split off path

ports = regexp(ports, '+B_', 'split'); 
port_labels{1} = ports{1}; % split off port A

ports = regexp(ports{2}, '+C_', 'split'); 
port_labels{2} = ports{1}; % split off port B

ports = regexp(ports{2}, '+D_', 'split'); 
port_labels{3} = ports{1}; % split off port C

ports = regexp(ports{2}, '.ns', 'split'); 
port_labels{4} = ports{1}; % split off port D


end