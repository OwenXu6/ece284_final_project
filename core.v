module core#(
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter col = 8,
    parameter row = 8
)(
    // clock signal
    input clk,
    input reset,
    // memory interface
    input [bw*row-1:0] D_xmem,
    // instruction signal
    input [33:0] inst,
    // fifo
    output ofifo_valid,
    // SFP
    output [col*psum_bw-1:0] sfp_out
);

/* instruction format
[33]    acc
[32]    CEN_pmem
[31]    WEN_pmem
[30:20] A_pmem
[19]    CEN_xmem
[18]    WEN_xmem
[17:7]  A_xmem
[6]     ofifo_rd
[5]     ififo_wr
[4]     ififo_rd
[3]     l0_rd
[2]     l0_wr
[1]     execute
[0]     load
*/

wire [31:0] xmem_Q_w;
wire [col*psum_bw-1:0] pmem_Q_w;
wire [psum_bw*col-1:0] D_pmem_w;


// SRAM
sram_32b_w2048 xmem (
    .CLK(clk),
    .CEN(inst[19]),
    .WEN(inst[18]),
    .A(inst[17:7]),
    .D(D_xmem),
    .Q(xmem_Q_w)
);

sram_32b_w2048#(
    .bw(col*psum_bw)
    ) pmem (
    .CLK(clk),
    .CEN(inst[32]),
    .WEN(inst[31]),
    .A(inst[30:20]),
    .D(D_pmem_w),
    .Q(pmem_Q_w)
);

// corelet
corelet #(.bw(bw), .col(col), .row(row)) corelet_instance (
    .clk(clk),
    .reset(reset),
    .inst(inst[1:0]),
    .data_to_l0(xmem_Q_w),
    .l0_rd(inst[3]),
    .l0_wr(inst[2]),
    .l0_full(),
    .l0_ready(),
    .ofifo_rd(inst[6]),
    .ofifo_full(),
    .ofifo_ready(),
    .ofifo_valid(ofifo_valid),
    .ofifo_out(sfp_out),
    .data_to_sfu(pmem_Q_w),
    .acc(inst[33]),
    .relu(1'b1),
    .data_out(D_pmem_w)
);

endmodule
