// mac_array.v
// Four MAC units connected in a weight-loading chain.
// Weight bits arrive serially and shift through all 4 units.
// All 4 units compute in parallel on the same data_in.
module mac_array (
input wire clk,
input wire rst_n,
input wire load_w_bit, // shift one weight bit into chain
input wire w_serial_in, // weight bit from outside
input wire compute, // compute one MAC step
input wire clear, // clear all accumulators
input wire [7:0] data_in, // shared input to all 4 units
output wire [15:0] accum0, accum1, accum2, accum3, // 4 results
output wire w_serial_out // weight bit exiting unit 3 (unused)
);
// Internal wires connecting weight shift chain
wire [7:0] w_out0, w_out1, w_out2, w_out3;
// Unit 0: receives weight bits from outside
mac_unit u0 (
.clk(clk), .rst_n(rst_n),
.load_w_bit(load_w_bit), .w_bit_in(w_serial_in),
.compute(compute), .clear(clear),
.data_in(data_in),
.accum_out(accum0), .weight_out(w_out0)
);
// Unit 1: receives weight bits from unit 0's MSB
mac_unit u1 (
.clk(clk), .rst_n(rst_n),
.load_w_bit(load_w_bit), .w_bit_in(w_out0[7]),
.compute(compute), .clear(clear),
.data_in(data_in),
.accum_out(accum1), .weight_out(w_out1)
);
// Unit 2: receives weight bits from unit 1's MSB
mac_unit u2 (
.clk(clk), .rst_n(rst_n),
.load_w_bit(load_w_bit), .w_bit_in(w_out1[7]),
.compute(compute), .clear(clear),
.data_in(data_in),
.accum_out(accum2), .weight_out(w_out2)
);
// Unit 3: receives weight bits from unit 2's MSB
mac_unit u3 (
.clk(clk), .rst_n(rst_n),
.load_w_bit(load_w_bit), .w_bit_in(w_out2[7]),
.compute(compute), .clear(clear),
.data_in(data_in),
.accum_out(accum3), .weight_out(w_out3)
);
assign w_serial_out = w_out3[7];
endmodule
