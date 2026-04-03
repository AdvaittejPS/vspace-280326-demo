// mac_unit.v
// One multiply-accumulate unit with a weight register and accumulator.
// weight is 8-bit unsigned. data_in is 8-bit unsigned.
// accumulator is 16-bit to hold the product without overflow.
module mac_unit (
input wire clk,
input wire rst_n, // active-low reset
input wire load_w_bit, // shift one bit into weight register
input wire w_bit_in, // the bit to shift in
input wire compute, // do one MAC step this cycle
input wire clear, // reset accumulator to zero
input wire [7:0] data_in, // 8-bit input value
output wire [15:0] accum_out, // accumulated result
output wire [7:0] weight_out // current weight value (for chaining)
);
reg [7:0] weight;
reg [15:0] accum;
wire [15:0] product;
// Multiply: data_in (8-bit) x weight (8-bit) = product (16-bit)
assign product = data_in * weight;
always @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
weight <= 8'b0;
accum <= 16'b0;
end else begin
// Weight loading: shift one bit in from MSB end
if (load_w_bit)
weight <= {weight[6:0], w_bit_in};
// Accumulator: clear takes priority over compute
if (clear)
accum <= 16'b0;
else if (compute)
accum <= accum + product;
end
end
assign accum_out = accum;
NeurAcc — MAC Accelerator Guide | Page 12
assign weight_out = weight;
endmodule
