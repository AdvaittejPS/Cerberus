`timescale 1ns / 1ps

module cerberus_top (
    input sysclk,               // 125MHz Clock from FPGA
    input [3:0] sw,             // Switches for manual reset
    output [3:0] led,           // Physical LEDs for Alarm/Auth status
    input [31:0] s_axi_wdata,   // AXI-Lite Signals
    output [31:0] s_axi_rdata
);

    wire clk = sysclk;
    wire reset = sw[0];
    wire [31:0] y_reported, target_speed, u_out, alpha_hat;
    wire authenticated, alarm;
    wire [31:0] puf_response;

    // 1. Instantiate the Security Identity (PUF)
    ro_puf #(.SEED(32'h55AA55AA)) puf_inst (
        .challenge(32'h12345678),
        .response(puf_response)
    );

    // 2. Instantiate the Core Defense
    hil_defense defense_inst (
        .clk(clk),
        .reset(reset),
        .y_reported(y_reported),
        .y_current_reported(32'd0),
        .target_speed(target_speed),
        .authenticated(authenticated),
        .u_out(u_out),
        .alarm(alarm),
        .alpha_hat(alpha_hat)
    );

    // Physical Feedback
    assign led[0] = authenticated; // Green LED: System Secure
    assign led[1] = alarm;         // Red LED: Attack Detected

endmodule