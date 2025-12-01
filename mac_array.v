// use row*mac_row to build an array
module mac_array (clk, in_n, out_s, in_w, inst_w, reset, simd, OS, os_output_flg, valid);
    parameter bw = 4;
    parameter psum_bw = 16;
    parameter kij_max = 9; // max kernel size
    parameter input_ch = 8; // number of input channels
    parameter cnt_max = kij_max * input_ch; // max accumulation count for OS

    parameter row = 8; // number of rows in an array
    parameter col = 8; // number of columns in a row

    input clk, reset, simd, OS, os_output_flg;
    output [col-1:0] valid;

    input  [col*psum_bw-1:0] in_n; // input partial sum(WS); input weight (OS)
    output [col*psum_bw-1:0] out_s;
    input  [row*bw-1:0] in_w; // input feature
    input  [1:0] inst_w;

    wire [(row+1)*(psum_bw*col)-1: 0]psum_temp;
    assign psum_temp[psum_bw*col-1: 0] = in_n;

    reg [2*row-1: 0] arr_inst;

    always @ (posedge clk) begin
        // inst_w flows to row0 to row7
        arr_inst <= {arr_inst[2*row-3: 0], inst_w};
    end

    genvar i;
    generate
        for (i=1; i < row+1 ; i=i+1) begin : row_num
            mac_row #(
                .bw(bw),
                .psum_bw(psum_bw),
                .kij_max(kij_max),
                .input_ch(input_ch)
            ) mac_row_instance (
                .clk(clk),
                .reset(reset),
                .in_w(in_w[bw*i-1: bw*(i-1)]),
                .inst_w(arr_inst[i*2-1: i*2-2]),
                .in_n(psum_temp[i*psum_bw*col-1:(i-1)*psum_bw*col]),
                .out_s(psum_temp[(i+1)*psum_bw*col-1: i*psum_bw*col]),
                .simd(simd),
                .OS(OS),
                .os_output_flg(os_output_flg),
                .valid(valid[i-1])
            );
        end
    endgenerate

    assign out_s = psum_temp[(row+1)*psum_bw*col-1: row*psum_bw*col];
endmodule

    