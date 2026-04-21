% Forensic Convergence Tracker
if ~exist('alpha_hat_vec', 'var')
    error('Run import_verilog_data.m first.');
end

Ts = 0.0005; 
N_steps = length(alpha_hat_vec); 
time_vec = (0:N_steps-1) * Ts;
drift_rate = 50; 

% ALIGNMENT FIX: Match the Verilog simulation timeline
attack_start_time = 2.5; 
attack_duration = 2.5; 

alpha_real = zeros(1, N_steps);
for k = 1:N_steps
    curr_time = (k-1) * Ts;
    
    % ALIGNMENT FIX: Stop the theoretical attack after 2.5s to match Verilog's plateau
    if curr_time >= attack_start_time && curr_time <= (attack_start_time + attack_duration)
        alpha_real(k) = drift_rate * (curr_time - attack_start_time);
    elseif curr_time > (attack_start_time + attack_duration)
        alpha_real(k) = drift_rate * attack_duration; 
    end
end

attack_start_idx = round(attack_start_time / Ts);
error_signal = abs(alpha_real(attack_start_idx:end)' - alpha_hat_vec(attack_start_idx:end));
conv_rel_idx = find(error_signal < 1.0, 1, 'first');

if ~isempty(conv_rel_idx)
    convergence_time = conv_rel_idx * Ts;
    fprintf('Forensic Convergence Time = %.4f seconds\n', convergence_time);
else
    fprintf('Tracker is still converging...\n');
end

% Plotting
figure('Color', 'w');
plot(time_vec, alpha_real, 'r--', 'LineWidth', 2); hold on;
plot(time_vec, alpha_hat_vec, 'b', 'LineWidth', 1.5);
title('Forensic Tracker Accuracy: Cerberus');
xlabel('Time (s)'); ylabel('Drift Magnitude (rad/s)');
legend('Actual FDI Attack', 'Hardware Forensic Estimate', 'Location', 'northwest'); grid on;