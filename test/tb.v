`timescale 1ns/1ps
module tb (
  input  wire clk,
  input  wire rst_n,
  input  wire ena,
  input  wire [7:0] ui_in,
  output wire [7:0] uo_out,
  input  wire [7:0] uio_in,
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe
);

  // Cocotb drives all inputs; this file is just the DUT wrapper.
  tt_um_neuracc dut (
    .clk(clk), .rst_n(rst_n), .ena(ena),
    .ui_in(ui_in), .uo_out(uo_out),
    .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe)
  );

endmodule