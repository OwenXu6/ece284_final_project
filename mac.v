// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
// Modified by handsome Owen X
// Modified for Part 2: SIMD & Reconfigurable MAC
module mac (out, a, b0, b1, c, simd);
    parameter bw = 4;
    parameter psum_bw = 16;

    output signed [psum_bw-1:0] out;
    input signed [bw-1:0] a;      // Activation
    input signed [bw-1:0] b0;     // Weight 0
    input signed [bw-1:0] b1;     // Weight 1 (Used in SIMD mode)
    input signed [psum_bw-1:0] c; // Partial Sum In
    input simd;                   // 0: 4-bit mode, 1: 2-bit SIMD mode

    wire signed [1:0] mult1_op_a;
    wire signed [bw-1:0] mult1_op_b;
    wire signed [1:0] mult2_op_a;
    wire signed [bw-1:0] mult2_op_b;

    wire signed [bw+1:0] product1; // 2-bit * 4-bit = 6-bit (max)
    wire signed [bw+1:0] product2;

    wire signed [psum_bw-1:0] psum_simd;
    wire signed [psum_bw-1:0] psum_4b;
    
    // Multiplier 1:
    assign mult1_op_a = a[1:0];
    assign mult1_op_b = b0;
    assign product1 = mult1_op_a * mult1_op_b;

    // Multiplier 2:
    assign mult2_op_a = (simd) ? a[1:0] : a[3:2];
    assign mult2_op_b = (simd) ? b1     : b0;
    assign product2 = mult2_op_a * mult2_op_b;

    // 4-bit Mode: Result = (High_part << 2) + Low_part + C
    wire signed [2*bw-1:0] product_4b;
    assign product_4b = (product2 << 2) + product1; 
    assign psum_4b = product_4b + c;

    // 2-bit SIMD Mode: 
    //   Low Lane (psum[7:0]): product1 + c[7:0]
    //   High Lane (psum[15:8]): product2 + c[15:8]
    wire signed [7:0] psum_simd_lo;
    wire signed [7:0] psum_simd_hi;

    assign psum_simd_lo = product1 + c[7:0];
    assign psum_simd_hi = product2 + c[15:8];
    assign psum_simd = {psum_simd_hi, psum_simd_lo};

    // final output
    assign out = (simd) ? psum_simd : psum_4b;

endmodule
