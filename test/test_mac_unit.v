// test_mac_unit.v — standalone unit test for mac_unit
`timescale 1ns/1ps
module test_mac_unit;
  reg clk = 0, rst_n = 0;
  reg load_w_bit = 0, w_bit_in = 0;
  reg compute = 0, clear = 0;
  reg [7:0] data_in = 0;
  wire [9:0] accum_out;   // 10-bit accumulator
  wire       w_msb_out;   // MSB of weight (daisy-chain)

  mac_unit dut (
    .clk(clk), .rst_n(rst_n),
    .load_w_bit(load_w_bit), .w_bit_in(w_bit_in),
    .compute(compute), .clear(clear),
    .data_in(data_in),
    .accum_out(accum_out),
    .w_msb_out(w_msb_out)
  );

  always #5 clk = ~clk;

  integer i;
  initial begin
    // Reset
    rst_n = 0; @(posedge clk); @(posedge clk);
    rst_n = 1; @(posedge clk);

    // Load weight = 3 (4-bit: 0011), MSB-first
    for (i = 3; i >= 0; i = i - 1) begin
      load_w_bit = 1;
      w_bit_in   = (4'd3 >> i) & 1;
      @(posedge clk);
    end
    load_w_bit = 0;
    @(posedge clk);

    // Compute with data_in = 10  → accum = 0 + 10*3 = 30
    @(posedge clk); #1; data_in = 8'd10; compute = 1;
    @(posedge clk); #1; compute = 0;
    @(posedge clk);
    $display("Accum after compute(10): %0d (expected 30)", accum_out);

    // Compute with data_in = 20  → accum = 30 + 20*3 = 90
    @(posedge clk); #1; data_in = 8'd20; compute = 1;
    @(posedge clk); #1; compute = 0;
    @(posedge clk);
    $display("Accum after compute(20): %0d (expected 90)", accum_out);

    // Clear
    @(posedge clk); #1; clear = 1;
    @(posedge clk); #1; clear = 0;
    @(posedge clk);
    $display("Accum after clear: %0d (expected 0)", accum_out);

    $finish;
  end
endmodule
