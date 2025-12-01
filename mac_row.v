// organize tile_alpha to a row
module mac_row (clk, in_n, out_s, in_w, inst_w, reset, simd, OS, os_output_flg, valid);
    parameter bw = 4;
    parameter psum_bw = 16;
    parameter kij_max = 9; // max kernel size
    parameter input_ch = 8; // number of input channels
    parameter cnt_max = kij_max * input_ch; // max accumulation count for OS

    parameter col = 8; // number of columns in a row

    input clk, reset, simd, OS, os_output_flg;

    input  [col*psum_bw-1:0] in_n; // input partial sum(WS); input weight (OS)
    output [col*psum_bw-1:0] out_s;
    input  [col*bw-1:0] in_w; // input feature
    input  [1:0] inst_w;
    output [col-1:0] valid;

    wire  [(col+1)*bw-1:0] temp;
    wire  [(col+1)*2-1: 0] inst_temp;
    assign temp[bw-1:0]   = in_w;
    assign inst_temp[1: 0] = inst_w;

    wire [col-1:0] os_valid;

    genvar i;
    generate
        for (i = 0; i < col; i = i + 1) begin : mac_tiles
            mac_tile #(
                .bw(bw),
                .psum_bw(psum_bw),
                .kij_max(kij_max),
                .input_ch(input_ch)
            ) mac_tile_inst (
                .clk(clk),
                .out_s(out_s[(i+1)*psum_bw-1:i*psum_bw]),
                .in_w(temp[(i+1)*bw-1:i*bw]),
                .out_e(temp[(i+2)*bw-1:(i+1)*bw]),
                .in_n(in_n[(i+1)*psum_bw-1:i*psum_bw]),
                .inst_w(inst_temp[2*(i+1)-1:2*i]),
                .inst_e(inst_temp[2*(i+2)-1: 2*(i+1)]),
                .reset(reset),
                .simd(simd),
                .OS(OS),
                .os_output_flg(os_output_flg),
                .os_valid(os_valid[i])
            );

            assign valid[i] = OS ? os_valid[i] : inst_temp[2*(i+1)-1];
        end
    endgenerate
endmodule