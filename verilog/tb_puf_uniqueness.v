`timescale 1ns / 1ps

module tb_puf_uniqueness();
    reg [31:0] challenge;
    wire [31:0] resp_a, resp_b;
    integer i, diff_bits;

    // Instantiate two different "chips"
    ro_puf #(.SEED(32'hA1B2C3D4)) chip_a (
        .challenge(challenge),
        .response(resp_a)
    );
    ro_puf #(.SEED(32'h55AA55AA)) chip_b (
        .challenge(challenge),
        .response(resp_b)
    );

    initial begin
        challenge = 32'h12345678;
        #10;
        diff_bits = 0;
        for (i = 0; i < 32; i = i + 1) begin
            if (resp_a[i] != resp_b[i]) diff_bits = diff_bits + 1;
        end
        $display("=================================");
        $display("Uniqueness Metric: %d bits different out of 32", diff_bits);
        $display("Percentage: %f%%", (diff_bits/32.0)*100);
        $display("=================================");
        $stop;
    end
endmodule