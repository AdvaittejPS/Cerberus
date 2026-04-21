`timescale 1ns / 1ps

module ro_puf #(parameter SEED = 32'hA1B2C3D4) (
    input [31:0] challenge,
    output [31:0] response
);
    // Hardware-intrinsic XOR Challenge-Response
    assign response = challenge ^ SEED;

endmodule