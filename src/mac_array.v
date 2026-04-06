// mac_array.v
// Four MAC units, 4-bit weights, 8-bit data, 10-bit accumulators.
module mac_array (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        load_w_bit,
  input  wire        w_serial_in,
  input  wire        compute,
  input  wire        clear,
  input  wire [7:0]  data_in,
  output wire [9:0]  accum0, accum1, accum2, accum3
);
  wire w_msb0, w_msb1, w_msb2;

  mac_unit u0 (.clk(clk), .rst_n(rst_n), .load_w_bit(load_w_bit), .w_bit_in(w_serial_in),
               .compute(compute), .clear(clear), .data_in(data_in),
               .accum_out(accum0), .w_msb_out(w_msb0));

  mac_unit u1 (.clk(clk), .rst_n(rst_n), .load_w_bit(load_w_bit), .w_bit_in(w_msb0),
               .compute(compute), .clear(clear), .data_in(data_in),
               .accum_out(accum1), .w_msb_out(w_msb1));

  mac_unit u2 (.clk(clk), .rst_n(rst_n), .load_w_bit(load_w_bit), .w_bit_in(w_msb1),
               .compute(compute), .clear(clear), .data_in(data_in),
               .accum_out(accum2), .w_msb_out(w_msb2));

  /* verilator lint_off PINCONNECTEMPTY */
  mac_unit u3 (.clk(clk), .rst_n(rst_n), .load_w_bit(load_w_bit), .w_bit_in(w_msb2),
               .compute(compute), .clear(clear), .data_in(data_in),
               .accum_out(accum3), .w_msb_out());
  /* verilator lint_on PINCONNECTEMPTY */
endmodule
