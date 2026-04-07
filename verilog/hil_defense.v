`timescale 1ns / 1ps

module hil_defense (
    input clk,
    input reset,
    input signed [31:0] y_reported,         // Sensor 1: Velocity (Q16.16)
    input signed [31:0] y_current_reported, // NEW Sensor 2: Current (Q16.16)
    input signed [31:0] target_speed,       // Q16.16 Input
    input authenticated,                    // From PUF Logic
    output reg signed [31:0] u_out,         // Q16.16 Output
    output reg alarm,                       // High if attack detected
    output reg signed [31:0] alpha_hat      // NEW: Real-time Hacker Tracker
);
    // --- PHYSICS PARAMETERS (Q16.16) ---
    parameter signed [31:0] A11 = 32'd65533;  // 0.9999
    parameter signed [31:0] A12 = 32'd175;    // 0.0026
    parameter signed [31:0] A21 = -32'd524;   // -0.0080 
    parameter signed [31:0] A22 = 32'd49807;  // 0.7600
    parameter signed [31:0] B2  = 32'd6554;   // 0.1000
    
    // --- CONTROL PARAMETERS (Q16.16) ---
    parameter signed [31:0] Kp  = 32'd294912;
    parameter signed [31:0] Ki  = 32'd2293760;
    parameter signed [31:0] V_MAX = 32'd1572864; // 24V
    parameter signed [31:0] THRESHOLD = 32'd327680; // 5.0 
    
    // --- NEW: RESEARCH FEATURES PARAMETERS ---
    parameter signed [31:0] L22 = 32'd655;       // 0.01 (Closed-Loop Gain)
    parameter signed [31:0] ALPHA_STEP = 32'd327680; // 5.0 (Sliding Mode Step)
    parameter [31:0] STARTUP_CYCLES = 32'd50;    // 500ns for simulation

    // --- REGISTERS ---
    reg signed [31:0] x_hat_1, x_hat_2;
    reg signed [31:0] integral_err;
    reg [31:0] startup_cnt; // NEW: Startup masking counter
    
    // 64-bit intermediate DSP math variables
    reg signed [63:0] full_u;
    reg signed [63:0] x_hat_1_calc;
    reg signed [63:0] x_hat_2_calc;
    reg signed [63:0] obs_correction;

    wire signed [31:0] residual;
    wire signed [31:0] y_clean;
    wire system_ready;
    wire attack_detected;

    // 1. Startup Logic
    assign system_ready = (startup_cnt >= STARTUP_CYCLES);

    // 2. Detection (Absolute Value)
    assign residual = (y_reported > x_hat_1) ? (y_reported - x_hat_1) : (x_hat_1 - y_reported);

    // 3. Mitigation Switch (Only trigger if system is fully spun up, or if unauthenticated)
    assign attack_detected = (residual > THRESHOLD) && system_ready;
    assign y_clean = (attack_detected || !authenticated) ? x_hat_1 : y_reported;

    always @(posedge clk) begin
        if (reset) begin
            x_hat_1 <= 0;
            x_hat_2 <= 0;
            integral_err <= 0;
            u_out <= 0;
            alarm <= 0;
            full_u <= 0;
            x_hat_1_calc <= 0;
            x_hat_2_calc <= 0;
            obs_correction <= 0;
            startup_cnt <= 0;
            alpha_hat <= 0;
        end else begin
            
            // Increment Startup Mask Counter
            if (startup_cnt < STARTUP_CYCLES) begin
                startup_cnt <= startup_cnt + 1;
            end

            // --- THE GATEKEEPER ---
            if (!authenticated) begin
                u_out <= 0;
                integral_err <= 0; 
            end else begin
                // PID with Anti-Windup
                full_u = (Kp * (target_speed - y_clean)) + (Ki * integral_err);
                if (full_u[47:16] > V_MAX) begin
                    u_out <= V_MAX;
                end else if (full_u[47:16] < -V_MAX) begin
                    u_out <= -V_MAX;
                end else begin
                    u_out <= full_u[47:16];
                    integral_err <= integral_err + ((target_speed - y_clean) >>> 11);
                end
            end
            
            // --- NEW: FORENSIC SLIDING MODE ESTIMATOR (With Boundary Layer) ---
            // We use a local signed variable to calculate the true tracking error
            // (y_reported - x_hat_1) is the physical error. Subtracting alpha_hat closes the loop.
            begin : SMO_BLOCK
                reg signed [31:0] tracking_error;
                tracking_error = (y_reported - x_hat_1) - alpha_hat;
                
                // Use $signed() to force Verilog to keep the math signed!
                if (tracking_error > $signed(32'd65536)) begin
                    alpha_hat <= alpha_hat + ALPHA_STEP;
                end else if (tracking_error < -$signed(32'd65536)) begin
                    alpha_hat <= alpha_hat - ALPHA_STEP;
                end else begin
                    // Smooth tracking inside the boundary layer (no chattering)
                    alpha_hat <= alpha_hat + (tracking_error >>> 3); 
                end
            end

            // --- NEW: CLOSED-LOOP OBSERVER ---
            // Calculate the L22 correction factor based on the physical current sensor
            obs_correction = L22 * (y_current_reported - x_hat_2);
            x_hat_1_calc = (A11 * x_hat_1) + (A12 * x_hat_2);
            // Add the correction factor to x_hat_2_calc
            x_hat_2_calc = (A21 * x_hat_1) + (A22 * x_hat_2) + (B2 * u_out) + obs_correction;
            
            x_hat_1 <= x_hat_1_calc[47:16];
            x_hat_2 <= x_hat_2_calc[47:16];
            
            alarm <= attack_detected;
        end
    end
endmodule