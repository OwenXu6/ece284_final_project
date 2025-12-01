git@github.com:OwenXu6/ece284_final_project.git
iverilog -o compiled_sim \
core_tb.v \
core.v \
corelet.v \
mac_array.v \
mac_row.v \
mac_tile.v \
mac.v \
l0.v \
ofifo.v \
sfu.v \
fifo_depth64.v \
fifo_depth8.v \
fifo_mux_16_1.v \
fifo_mux_8_1.v \
fifo_mux_2_1.v \
sram_32b_w2048.v
