% Computational Fidelity Analysis
if ~exist('data', 'var')
    error('Run import_verilog_data.m first.');
end

Ts = 0.0005; target = 100;
y_verilog = double(data.y_clean) / 65536;
steps = length(y_verilog); time_vec = (0:steps-1) * Ts;

% Ideal Physics Constants
R = 2.4; L = 0.005; J = 0.015; b = 0.001; K = 0.08;
Ac = [-b/J K/J; -K/L -R/L]; Bc = [0; 1/L]; Cc = [1 0];
A = eye(2) + Ac*Ts; B = Bc*Ts; C = Cc;

x_state = [0; 0]; y_matlab = zeros(1, steps);

for k = 1:steps-1
    y_matlab(k) = C * x_state(:,k);
    
    % ALIGNMENT FIX: Feed the exact hardware voltage into MATLAB's physics
    % instead of the hardcoded 12V from the original PDF.
    u_ideal = data.u_out(k) / 65536; 
    
    x_state(:, k+1) = A * x_state(:, k) + B * u_ideal;
end

y_matlab_v = y_matlab(:); y_verilog_v = y_verilog(:);
min_len = min(length(y_matlab_v), length(y_verilog_v));
error_signal = y_matlab_v(1:min_len) - y_verilog_v(1:min_len);
rmse_val = sqrt(mean(error_signal.^2));

fidelity = (1 - (rmse_val / target)) * 100;
fprintf('Root Mean Square Error: %.4f rad/s\n', rmse_val);
fprintf('Computational Fidelity: %.2f%%\n', fidelity);

% Plotting
figure('Color', 'w');
plot(time_vec(1:min_len), y_matlab_v(1:min_len), 'b', 'LineWidth', 2); hold on;
plot(time_vec(1:min_len), y_verilog_v(1:min_len), 'r--', 'LineWidth', 1.5);
title('Fidelity Analysis: MATLAB vs. Verilog');
xlabel('Time (s)'); ylabel('Velocity (rad/s)'); 
legend('Float64 (MATLAB)', 'Fixed32 (FPGA)', 'Location', 'best'); grid on;