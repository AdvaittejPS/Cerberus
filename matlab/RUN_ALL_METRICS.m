% PROJECT CERBERUS: MASTER ANALYTICS SCRIPT
clc; close all;
fprintf('======================================\n');
fprintf(' CERBERUS-DRIVE SYSTEM BENCHMARK SUITE \n');
fprintf('======================================\n\n');

run('digital_twin_observer_benchmark.m');

fprintf('--- 1. Importing Hardware Data ---\n');
run('import_verilog_data.m');

fprintf('\n--- 2. Resilience Score Calculation ---\n');
run('Resilience_score_calculation.m');

fprintf('\n--- 3. Computational Fidelity Check ---\n');
run('Computational_Fidelity.m');

fprintf('\n--- 4. Forensic Accuracy Tracker ---\n');
run('Forensic_Accuracy.m');

fprintf('\n--- 5. DoS Survivability Metric ---\n');
run('DoS_Survivability_Metric.m');

fprintf('\n--- 6. SMO Smoothness Metric ---\n');
run('SMO_Smoothness_Metric.m');


fprintf('\n======================================\n');
fprintf('ALL TESTS COMPLETE. GRAPHS GENERATED FOR REPORT.\n');
fprintf('======================================\n');