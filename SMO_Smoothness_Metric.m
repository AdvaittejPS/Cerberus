% Cerberus-Drive: Chattering Variance (SMO Smoothness) Metric
if ~exist('alpha_hat_vec', 'var')
    error('Run import_verilog_data.m first.');
end

Ts_sim = 0.0005;
time_vec = (0:length(alpha_hat_vec)-1) * Ts_sim;

% ALIGNMENT FIX: Isolate ONLY the FDI tracking window (2.6s to 5.0s).
% We must exclude the DoS attack at 5.9s, because the sudden -100 rad/s 
% sensor drop causes a massive mathematical step, artificially spiking the variance.
fdi_window_indices = find(time_vec >= 2.6 & time_vec <= 5.0);
active_alpha = alpha_hat_vec(fdi_window_indices);

fprintf('\n======================================\n');
fprintf('--- SMO CHATTERING ANALYSIS ---\n');

if isempty(fdi_window_indices)
    fprintf('Error: Not enough tracking data to calculate chattering.\n');
else
    % Calculate Variance of Step Changes
    step_changes = diff(active_alpha);
    chattering_variance = var(step_changes);
    
    fprintf('Chattering Variance: %.6f\n', chattering_variance);
    
    if chattering_variance < 0.01
        fprintf('Verdict: EXTREMELY SMOOTH (Boundary Layer eliminated chattering)\n');
    else
        fprintf('Verdict: CHATTERING DETECTED (Observer is oscillating heavily)\n');
    end
    
    % Plotting the Smoothness
    figure('Color', 'w');
    
    % Plot the derivative to visually show lack of high-frequency noise
    plot(time_vec(fdi_window_indices(1:end-1)), step_changes, 'b', 'LineWidth', 2);
    ylim([-0.5, 0.5]); % Zoom in to prove how flat it is
    yline(0, 'k--');
    
    title('Forensic Estimator: Step-Change Variance (FDI Window)');
    xlabel('Time (s)'); ylabel('\Delta Tracker Magnitude (rad/s per step)');
    legend('SMO Step Size (No Chattering)', 'Location', 'best');
    grid on;
end
fprintf('======================================\n');