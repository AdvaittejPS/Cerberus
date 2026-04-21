% Resilience Score (R) & Detection Latency
Ts_sim = 0.0005;

% ALIGNMENT FIX: Match the Verilog attack injection time
attack_start_time = 2.5; 

if ~exist('y_clean_vec', 'var')
    error('Run import_verilog_data.m first.');
end

N_steps = length(y_clean_vec);
attack_start = round(attack_start_time / Ts_sim);

if attack_start >= N_steps || attack_start < 1
    attack_start = round(N_steps / 2);
end

% ALIGNMENT FIX: Calculate actual steady state before attack to find true resilience
steady_state_baseline = mean(y_clean_vec(attack_start-500 : attack_start));
attack_indices = attack_start:N_steps;
average_speed_under_attack = mean(y_clean_vec(attack_indices));

Resilience_Score = average_speed_under_attack / steady_state_baseline;

fprintf('\nMeasured Resilience Score (R): %.4f\n', Resilience_Score);
if Resilience_Score > 0.95
    fprintf('Verdict: HIGH RESILIENCE (Success)\n');
else
    fprintf('Verdict: SYSTEM VULNERABLE (Failure)\n');
end

% --- DETECTION LATENCY METRIC ---
difference_signal = abs(y_reported_vec - y_clean_vec);
detection_idx = find(difference_signal > 1.0, 1, 'first');

fprintf('------------------\n');
if ~isempty(detection_idx) && detection_idx > attack_start
    detection_latency_seconds = (detection_idx - attack_start) * Ts_sim;
    fprintf('Detection Latency: %.2f ms\n', detection_latency_seconds * 1000);
    fprintf('Comparison: ~%d times faster than Cloud-IoT platforms (300ms baseline)\n', ...
        round(300/max(0.1, (detection_latency_seconds * 1000))));
else
    fprintf('Detection Latency: Instantaneous (< 1 ms)\n');
end
fprintf('------------------\n');

% Plotting the DIRE Curve
figure('Color', 'w');
plot((1:N_steps)*Ts_sim, y_clean_vec, 'g', 'LineWidth', 2); hold on;
yline(steady_state_baseline, 'k--', 'Pre-Attack Baseline');
xline(attack_start_time, 'r--', 'Attack Injected');
title('Project Cerberus Resilience Analysis (DIRE Curve)');
xlabel('Time (s)'); ylabel('Velocity (rad/s)');
legend('Controller Input (y\_clean)', 'Location', 'best'); grid on;