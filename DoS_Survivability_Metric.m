% Cerberus-Drive: Denial of Service (DoS) Survivability Metric
if ~exist('y_clean_vec', 'var')
    error('Run import_verilog_data.m first.');
end

Ts_sim = 0.0005;
time_vec = (0:length(y_clean_vec)-1) * Ts_sim;

% 1. Detect the DoS Window 
% Finds where reported speed drops to 0 after initial spin-up
dos_indices = find(abs(y_reported_vec) < 0.5 & time_vec' > 1.0);

fprintf('\n======================================\n');
fprintf('--- DoS SURVIVABILITY METRIC ---\n');

if isempty(dos_indices)
    fprintf('Error: No DoS attack detected. Ensure Scenario 4 ran in Verilog.\n');
else
    % 2. Calculate Maximum Deviation during the blackout
    baseline_speed = y_clean_vec(dos_indices(1) - 1);
    dos_speeds = y_clean_vec(dos_indices);
    max_deviation = max(abs(dos_speeds - baseline_speed));
    
    fprintf('DoS Attack Window: %.4f s to %.4f s\n', time_vec(dos_indices(1)), time_vec(dos_indices(end)));
    fprintf('Pre-Attack Baseline Speed: %.2f rad/s\n', baseline_speed);
    fprintf('Maximum Deviation during DoS: %.2f rad/s\n', max_deviation);
    
    if max_deviation < 5.0
        fprintf('Verdict: SYSTEM SURVIVED (Digital Twin masked the blackout)\n');
    else
        fprintf('Verdict: SYSTEM CRASHED (Deviation too high)\n');
    end
    
    % 3. Plotting the DoS Ride-Through
    figure('Color', 'w');
    plot(time_vec, y_reported_vec, 'r--', 'LineWidth', 1.5); hold on;
    plot(time_vec, y_clean_vec, 'g', 'LineWidth', 2.5);
    
    % Zoom in on the attack window for better visual proof
    zoom_window = 0.5; % seconds before and after
    xlim([max(0, time_vec(dos_indices(1)) - zoom_window), min(time_vec(end), time_vec(dos_indices(end)) + zoom_window)]);
    ylim([0, 120]);
    
    title('Denial of Service (DoS) Survivability');
    xlabel('Time (s)'); ylabel('Velocity (rad/s)');
    legend('Hacked Sensor (Wire Cut / 0 rad/s)', 'Digital Twin Output (Maintains Control)', 'Location', 'south');
    grid on;
end
fprintf('======================================\n');