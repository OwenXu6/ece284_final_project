
// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
// Modified for Part 2: Dual Weight Loading
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, simd, OS, os_output_flg, os_valid);
    parameter bw = 4;
    parameter psum_bw = 16;
    parameter kij_max = 9; // max kernel size
    parameter input_ch = 8; // number of input channels
    parameter cnt_max = kij_max * input_ch; // max accumulation count for OS

    output [psum_bw-1:0] out_s;
    input  [bw-1:0] in_w; // input feature
    output [bw-1:0] out_e; 
    input  [1:0] inst_w; // [1]:execute, [0]:kernel loading
    output [1:0] inst_e;
    input  [psum_bw-1:0] in_n; // input partial sum(WS); input weight (OS)
    input  clk;
    input  reset;
    input  simd, OS; // control signals

    input os_output_flg; // get output passed to ofifo sequentially, externally controlled
    output reg os_valid; // OS valid signal

    reg [1:0] inst_q;
    reg [bw-1:0] a_q;
    reg [bw-1:0] b_q0; // Weight 0
    reg [bw-1:0] b_q1; // Weight 1
    reg [psum_bw-1:0] c_q;
    
    // Weight Loading Control: 0=Done, 1=Load W0, 2=Load W1 (SIMD only)
    reg [1:0] load_state; 
    // output stationary accumulation counter
    reg [7: 0] cnt;

    // input preprocessing
    wire [bw-1: 0] activation;
    wire [bw-1: 0] weight0, weight1;
    assign activation = in_w;
    assign weight0 = OS ? in_n[bw-1:0] : in_w;
    assign weight1 = OS ? in_n[2*bw-1:bw] : in_w;

    wire [psum_bw-1:0] mac_out;

    // output assignments
    assign out_e = a_q;
    assign inst_e = inst_q;
    // OS mode pass weight or output value to south
    assign out_s = OS ? (os_output_flg ? c_q : {8'b0, b_q0, b_q1}) : mac_out;

    always @(posedge clk) begin
        if (reset) begin
            {inst_q, a_q, b_q0, b_q1, c_q, load_state, cnt, os_valid} <= 0;
            // Reset logic: In 4-bit mode (mode=0), we need to load 1 weight.
            // In 2-bit mode (mode=1), we need to load 2 weights.
            // Let's use a counter: 0 means ready to load.
        end
        else begin
            inst_q[1] <= inst_w[1];
            case(OS)
            0: begin // WS
                c_q <= in_n; // store psum
                if (inst_w[0] || inst_w[1])
                    a_q <= activation;
                if (inst_w[0] || load_state == 0) begin
                    b_q0 <= weight0;
                    if (simd) begin 
                       load_state <= 1; // Need one more
                       inst_q[0]  <= 0; // Don't pass instruction
                    end
                    else begin
                       load_state <= 2; // Done
                       inst_q[0] <= 0;
                    end
                end
                else if (inst_w[0] && load_state == 1) begin
                    b_q1 <= weight1;
                    load_state <= 2; // Done
                    inst_q[0] <= 0; // pass instruction now
                end
                else begin
                    inst_q[0] <= inst_w[0];
                end
            end
            1: begin // OS
                if(!os_output_flg) begin // calculation phase
                    if(inst_w) begin // load weight and activation simultaneously
                        a_q <= activation;
                        b_q0 <= weight0;
                        b_q1 <= weight1;
                    end
                    if (inst_q[1]) begin // mac start to output
                        if(cnt != (cnt_max - 1) && !os_valid) begin
                            c_q <= mac_out;
                            cnt <= cnt + 1;
                        end
                        else begin
                            cnt <= 0;
                            os_valid <= 1;
                        end
                    end
                end
                else begin // output passing phase
                    c_q <= in_n; 
                end
            end
            default: begin // same as reset
                {inst_q, a_q, b_q0, b_q1, c_q, load_state, cnt, os_valid} <= 0;
            end
            endcase
        end
    end

    mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b0(b_q0),
        .b1(b_q1),
        .c(c_q),
        .simd(simd),
        .out(mac_out)
    );
endmodule