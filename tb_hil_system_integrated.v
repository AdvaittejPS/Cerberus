`timescale 1ns / 1ps

module tb_hil_system_integrated();

    reg clk;
    reg reset;
    reg signed [31:0] target_speed;
    reg [31:0] challenge_from_arm;
    reg [31:0] signed_hash_from_arm;

    wire [31:0] puf_response;
    wire signed [31:0] u_out;
    wire alarm;
    wire authenticated;
    wire signed [31:0] alpha_hat;

    // --- NEW: Physical Plant (Dummy Motor) Variables ---
    reg signed [31:0] y_reported;
    reg signed [31:0] y_current_reported;
    reg signed [31:0] attack_drift;
    reg signed [63:0] next_speed, next_current;
    reg signed [31:0] real_speed, real_current;

    // 1. PUF
    ro_puf #(.SEED(32'h55AA55AA)) puf_unit (
        .challenge(challenge_from_arm),
        .response(puf_response)
    );

    assign authenticated = (signed_hash_from_arm == puf_response);

    // 2. Defense Controller
    hil_defense dut (
        .clk(clk),
        .reset(reset),
        .y_reported(y_reported),
        .y_current_reported(y_current_reported),
        .target_speed(target_speed),
        .authenticated(authenticated),
        .u_out(u_out),
        .alarm(alarm),
        .alpha_hat(alpha_hat)
    );

    // --- 3. THE DUMMY MOTOR (Realistic Physics) ---
    always @(posedge clk) begin
        if (reset || !authenticated) begin
            real_speed <= 0;
            real_current <= 0;
        end else begin
            // Calculates motor physics based on the U_out voltage applied
            next_speed = (65533 * real_speed) + (175 * real_current);
            next_current = (-524 * real_speed) + (49807 * real_current) + (6554 * u_out);
            real_speed <= next_speed[47:16];
            real_current <= next_current[47:16];
        end
    end

    // The sensor reports the actual motor speed + any hacker drift
    always @(*) begin
        y_reported = real_speed + attack_drift;
        y_current_reported = real_current;
    end

    // --- 4. CSV LOGGING ---
    // --- CSV LOGGING LOGIC (THE BRIDGE TO MATLAB) ---
    integer data_file;
    reg logging_active; // NEW: Control flag for the loop

    initial begin
        logging_active = 1;
        data_file = $fopen("simulation_results.csv", "w");
        if (data_file == 0) begin
            $display("ERROR: Could not open file for writing.");
            $finish;
        end
        $fdisplay(data_file, "time,y_reported,y_clean,alpha_hat,u_out");
        
        // Use a while loop instead of forever
        while (logging_active) begin
            #10;
            // Double check flag to prevent race condition on the exact cycle it stops
            if (logging_active) begin
                $fdisplay(data_file, "%d,%d,%d,%d,%d", $time, y_reported, dut.y_clean, alpha_hat, u_out);
            end
        end
    end

    always #5 clk = ~clk;

    // --- 5. REALISTIC TIMELINE SCENARIO ---
    initial begin
        clk = 0; reset = 1;
        target_speed = 32'd6553600; // 100.0 rad/s
        challenge_from_arm = 32'h12345678;
        signed_hash_from_arm = 0;
        attack_drift = 0;

        #100 reset = 0;
        $display("--- Starting Physically Accurate HIL Test ---");

        // SCENARIO 1: UNAUTHORIZED (0.05s)
        repeat(100) #10; 

        // SCENARIO 2: AUTHENTICATE & SPIN UP
        signed_hash_from_arm = puf_response;
        $display("Authenticated. Motor spinning up to 100 rad/s (Takes ~2.5 seconds)...");
        
        // Let it naturally reach steady state (5000 steps = 2.5 seconds in MATLAB)
        repeat(5000) #10;

        // SCENARIO 3: FDI DRIFT ATTACK (50 rad/s^2)
        $display("Time %0t: Injecting 50 rad/s^2 Drift Attack!", $time);
        
        // 50 rad/s^2 * 0.0005s per step = 0.025 rad/s added per clock cycle.
        // 0.025 in Q16.16 = 1638.
        repeat(5000) begin
            #10 attack_drift = attack_drift + 32'd1638; 
        end

        // SCENARIO 4: RECOVERY HOLD
        repeat(1800) #10;

	// --- SCENARIO 5: DENIAL OF SERVICE (DOS) SENSOR DROPOUT ---
        $display("\nTime %0t: Injecting DoS Attack (Sensor wire cut)...", $time);
        
        // Force the sensor to read exactly 0 rad/s to simulate a cut wire
        repeat(500) begin
            #10 attack_drift = -real_speed; 
        end

        // Let the system recover again
        $display("Time %0t: Sensor reconnected. Recovering...", $time);
        attack_drift = 0;
        repeat(1000) #10;

        // --- SAFE SHUTDOWN SEQUENCE ---
        logging_active = 0;  // 1. Turn off the logging loop
        #10;                 // 2. Wait one clock cycle for the loop to exit
        $fclose(data_file);  // 3. Safely close the file
        
        $display("\n--- Simulation Complete ---");
        $stop;
    end
endmodule