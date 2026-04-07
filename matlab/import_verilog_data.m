% Project Cerberus Data Importer
clear; clc;
if exist('simulation_results.csv', 'file')
    data = readtable('simulation_results.csv');
else
    error('File simulation_results.csv not found! Run ModelSim/Vivado first.');
end

Ts_sim = 0.0005;
time_vec = (0:size(data,1)-1) * Ts_sim;

% Convert Q16.16 Fixed-Point to Double Precision
y_reported_vec = double(data.y_reported) / 65536;
y_clean_vec = double(data.y_clean) / 65536;
alpha_hat_vec = double(data.alpha_hat) / 65536;
u_out_vec = double(data.u_out) / 65536;

fprintf('Data Import Complete: %d simulation steps loaded.\n', length(time_vec));