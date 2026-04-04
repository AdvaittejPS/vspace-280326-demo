`timescale 1ns/1ps
module tb (
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] ui_in,
  output wire [7:0] uo_out,
  input  wire [7:0] uio_in,
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe,
  input  wire       ena
);

`ifdef COCOTB_SIM
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
  end
`endif

  tt_um_neuracc dut (
    .clk(clk),
    .rst_n(rst_n),
    .ui_in(ui_in),
    .uo_out(uo_out),
    .uio_in(uio_in),
    .uio_out(uio_out),
    .uio_oe(uio_oe),
    .ena(ena)
  );

endmodule
