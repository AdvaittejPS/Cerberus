% Digital Twin Observer Benchmark
clear; clc; close all;

% System Parameters
R = 2.4; L = 0.005; J = 0.015; b = 0.001; K = 0.08; Ts = 0.0005;
Ac = [-b/J K/J; -K/L -R/L]; Bc = [0; 1/L]; Cc = [1 0; 0 1];
A = eye(2) + Ac*Ts; B = Bc*Ts; C = Cc;

target_speed = 100;
Kp = 4.5; Ki = 35; Kd = 0.15; max_voltage = 24;
integral_error = 0; prev_error = 0;

L_obs = [0, 0; 0, 0.01]; L_sm = 200;
x_hat = [0; 0]; alpha_hat = 0;

steps = 12000; attack_start = 4000;

y_clean = zeros(1, steps); alpha_plot = zeros(1, steps);
residual = zeros(1, steps); threshold = 5.0;
x = [0; 0]; y_true = zeros(2, steps);
y_reported = zeros(2, steps); u = zeros(1, steps); drift_rate = 50;

for k = 1:steps-1
    y_true(:, k) = C * x(:, k) + [0.05; 0.01] .* randn(2,1);
    y_reported(:, k) = y_true(:, k);
    
    if k >= attack_start
        y_reported(1, k) = y_true(1, k) + drift_rate * (k - attack_start) * Ts;
    end
    
    y_pred = C(1,:) * x_hat;
    residual(k) = abs(y_reported(1, k) - y_pred);
    error_val = (y_reported(1, k) - y_pred) - alpha_hat;
    boundary_layer = 1.0;
    
    if error_val > boundary_layer
        alpha_hat = alpha_hat + L_sm * Ts;
    elseif error_val < -boundary_layer
        alpha_hat = alpha_hat - L_sm * Ts;
    else
        alpha_hat = alpha_hat + (L_sm / boundary_layer) * error_val * Ts;
    end
    
    alpha_plot(k) = alpha_hat;
    
    if residual(k) > threshold && k > 1000
        y_clean(k) = y_pred;
    else
        y_clean(k) = y_reported(1, k);
    end
    
    err = target_speed - y_clean(k);
    derivative = (err - prev_error) / Ts;
    u_ideal = Kp*err + Ki*integral_error + Kd*derivative;
    u(k) = max(min(u_ideal, max_voltage), -max_voltage);
    
    if u_ideal == u(k)
        integral_error = integral_error + (err * Ts);
    end
    
    prev_error = err;
    obs_err = y_reported(:, k) - (C*x_hat);
    x_hat = A * x_hat + B * u(k) + L_obs * obs_err;
    x(:, k+1) = A * x(:, k) + B * u(k);
end

figure('Color', 'w', 'Position', [100 50 800 900]);

% 1. Velocity Tracking
subplot(3,1,1);
plot((1:steps)*Ts, y_true(1,:), 'b', 'LineWidth', 2.5); hold on;
plot((1:steps)*Ts, y_reported(1,:), 'r--', 'LineWidth', 1.5);
plot((1:steps)*Ts, y_clean, 'g:', 'LineWidth', 2.5);
title('1. Velocity Tracking Baseline'); ylabel('Velocity (rad/s)'); 
legend('Actual Speed', 'Attacked Sensor', 'Controller Input (Cleaned)', 'Location', 'northwest'); grid on;

% 2. Attack Magnitude Estimation
subplot(3,1,2);
real_alpha_arr = zeros(1, steps);
real_alpha_arr(attack_start:end) = drift_rate * (0:steps-attack_start) * Ts;
plot((1:steps)*Ts, real_alpha_arr, 'r--', 'LineWidth', 2); hold on;
plot((1:steps)*Ts, alpha_plot, 'b', 'LineWidth', 1.5);
title('2. Attack Magnitude Estimation'); ylabel('Drift Magnitude (rad/s)'); 
legend('Actual FDI Attack', 'Digital Twin Estimate', 'Location', 'northwest'); grid on;

% 3. Detection Signal (Residual)
subplot(3,1,3);
plot((1:steps)*Ts, residual, 'm', 'LineWidth', 1.5); hold on;
yline(threshold, 'k--', 'Alarm Threshold', 'LineWidth', 2, 'Color', 'k');
title('3. Detection Signal (Residual)'); xlabel('Time (s)'); ylabel('Absolute Error'); 
legend('Residual Difference', 'Threshold Boundary', 'Location', 'northwest'); grid on;