// save as test/test_mac_unit.v
`timescale 1ns/1ps
module test_mac_unit;
  reg clk = 0, rst_n = 0;
  reg load_w_bit = 0, w_bit_in = 0;
  reg compute = 0, clear = 0;
  reg [7:0] data_in = 0;
  wire [15:0] accum_out;
  wire [7:0] weight_out;

  mac_unit dut (
    .clk(clk), .rst_n(rst_n),
    .load_w_bit(load_w_bit), .w_bit_in(w_bit_in),
    .compute(compute), .clear(clear),
    .data_in(data_in), .accum_out(accum_out),
    .weight_out(weight_out)
  );

  always #5 clk = ~clk;

  integer i;
  initial begin
    // Reset
    rst_n = 0; @(posedge clk); @(posedge clk);
    rst_n = 1; @(posedge clk);

    // Load weight = 3 (binary 00000011)
    for (i = 7; i >= 0; i = i - 1) begin
      load_w_bit = 1;
      w_bit_in   = (8'd3 >> i) & 1;
      @(posedge clk);
    end
    load_w_bit = 0;
    @(posedge clk);
    $display("Weight after loading: %0d (expected 3)", weight_out);

    // Compute with data_in = 10
    data_in = 8'd10;
    compute = 1; @(posedge clk);
    compute = 0; @(posedge clk);
    $display("Accum after 1 compute: %0d (expected 30)", accum_out);

    // Compute with data_in = 20
    data_in = 8'd20;
    compute = 1; @(posedge clk);
    compute = 0; @(posedge clk);
    $display("Accum after 2 computes: %0d (expected 90)", accum_out);

    $finish;
  end
endmodule
