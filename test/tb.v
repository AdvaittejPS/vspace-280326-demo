`timescale 1ns/1ps
module tb;

  reg clk;
  reg rst_n;
  reg [7:0] ui_in;   // [4]=clear,[3]=read_out,[2]=compute,[1]=load_weights,[0]=serial_in
  reg [7:0] uio_in;  // data_in
  wire [7:0] uo_out;
  wire [7:0] uio_out, uio_oe;

  initial begin clk=0; rst_n=0; ui_in=0; uio_in=0; end
  always #5 clk = ~clk;

  tt_um_neuracc dut (
    .clk(clk), .rst_n(rst_n), .ui_in(ui_in), .uo_out(uo_out),
    .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(1'b1)
  );

  task wait_cycles(input integer n);
    integer i; for (i=0; i<n; i=i+1) @(posedge clk);
  endtask

  integer bit_idx;
  reg [15:0] weight_bits;  // 4 units x 4-bit = 16 bits
  reg [39:0] result_bits;  // 4 units x 10-bit = 40 bits
  reg [9:0]  accum0, accum1, accum2, accum3;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    @(posedge clk); rst_n=0; wait_cycles(3); rst_n=1; wait_cycles(2);

    // Load weights [1,2,3,4] — 16 bits MSB-first: {4,3,2,1}
    weight_bits = {4'd4, 4'd3, 4'd2, 4'd1};
    $display("Loading weights: 1, 2, 3, 4");

    @(negedge clk); ui_in = 8'b00000010;              // load_weights=1
    @(negedge clk); ui_in = {7'b0, weight_bits[15]};  // drop load_weights, first bit

    for (bit_idx=14; bit_idx>=0; bit_idx=bit_idx-1) begin
      @(negedge clk); ui_in = {7'b0, weight_bits[bit_idx]};
    end
    @(negedge clk); ui_in=0;
    wait_cycles(3);

    // Compute with inputs 10, 20, 30
    $display("Computing with inputs: 10, 20, 30");
    @(negedge clk); uio_in=8'd10; ui_in=8'b00000100;
    @(negedge clk); uio_in=0;     ui_in=0;
    @(negedge clk); uio_in=8'd20; ui_in=8'b00000100;
    @(negedge clk); uio_in=0;     ui_in=0;
    @(negedge clk); uio_in=8'd30; ui_in=8'b00000100;
    @(negedge clk); uio_in=0;     ui_in=0;
    wait_cycles(3);

    // Read out 40 bits MSB-first.
    // Protocol:
    //   PA: FSM sees read_out → state=READOUT, bit_cnt=0. serial_out = accum_bus[39] combinationally.
    //   negedge after PA: sample bit 39.
    //   PB: bit_cnt=1. serial_out = accum_bus[38].
    //   negedge after PB: sample bit 38.
    //   ... repeat for 40 bits total (bit_cnt 0..39).
    $display("Reading results...");
    @(negedge clk); ui_in=8'b00001000;  // read_out=1
    @(negedge clk); ui_in=0;
    // PA happened between the two negedges above: FSM entered READOUT, bit_cnt=0.
    result_bits=0;
    for (bit_idx=39; bit_idx>=0; bit_idx=bit_idx-1) begin
      @(negedge clk);                    // sample after each posedge (bit_cnt increments on posedge)
      result_bits[bit_idx] = uo_out[0];
      if (bit_idx > 0) @(posedge clk);  // advance bit_cnt (skip last to avoid over-counting)
    end

    accum0 = result_bits[39:30];
    accum1 = result_bits[29:20];
    accum2 = result_bits[19:10];
    accum3 = result_bits[9:0];

    $display("accum0 = %0d (expected 60)",  accum0);
    $display("accum1 = %0d (expected 120)", accum1);
    $display("accum2 = %0d (expected 180)", accum2);
    $display("accum3 = %0d (expected 240)", accum3);

    if (accum0==60 && accum1==120 && accum2==180 && accum3==240)
      $display("PASS: All accumulators match expected values!");
    else
      $display("FAIL: Mismatch detected.");

    $finish;
  end
endmodule
