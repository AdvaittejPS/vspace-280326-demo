// mac_unit.v
// 4-bit weight, 8-bit data, 10-bit accumulator.
module mac_unit (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       load_w_bit,
  input  wire       w_bit_in,
  input  wire       compute,
  input  wire       clear,
  input  wire [7:0] data_in,
  output wire [9:0] accum_out,
  output wire       w_msb_out   // MSB of weight register for daisy-chain
);
  reg [3:0] weight;
  reg [9:0] accum;

  wire [11:0] product = data_in * weight;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      weight <= 4'b0;
      accum  <= 10'b0;
    end else begin
      if (load_w_bit)
        weight <= {weight[2:0], w_bit_in};
      if (clear)
        accum <= 10'b0;
      else if (compute)
        accum <= accum + product[9:0];
    end
  end

  assign accum_out = accum;
  assign w_msb_out = weight[3];
endmodule
