`timescale 1ns/1ps
module tb;

  reg clk = 0, rst_n = 0;
  reg [7:0] ui_in = 0;
  wire [7:0] uo_out;
  wire [7:0] uio_out, uio_oe;

  tt_um_neuracc dut (
    .clk(clk), .rst_n(rst_n),
    .ui_in(ui_in), .uo_out(uo_out),
    .uio_in(8'b0), .uio_out(uio_out),
    .uio_oe(uio_oe), .ena(1'b1)
  );

  always #5 clk = ~clk;

  task wait_cycles(input integer n);
    integer i;
    for (i = 0; i < n; i = i + 1) @(posedge clk);
  endtask

  // Declarations at module level — not inside blocks
  integer i, bit_idx;
  reg [31:0] weight_bits;
  reg [63:0] result_bits;
  reg [15:0] accum0, accum1, accum2, accum3;
  integer input_vals [0:2];   // array at module level

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset
    rst_n = 0; ui_in = 0;
    wait_cycles(3);
    rst_n = 1;
    wait_cycles(2);

    // STEP 1: Load weights [1, 2, 3, 4]
    weight_bits = {8'd1, 8'd2, 8'd3, 8'd4};
    $display("Loading weights: 1, 2, 3, 4");

    ui_in = 8'b00000010;   // set load_weights bit high
    @(posedge clk);
    ui_in = 8'b00000000;

    // Send 32 bits MSB-first into serial_in (ui_in[0])
    for (bit_idx = 31; bit_idx >= 0; bit_idx = bit_idx - 1) begin
      ui_in = {7'b0, weight_bits[bit_idx]};
      @(posedge clk);
    end
    ui_in = 0;
    wait_cycles(2);

    // STEP 2: Compute 3 MAC steps with inputs 10, 20, 30
    $display("Computing with inputs: 10, 20, 30");
    input_vals[0] = 10;
    input_vals[1] = 20;
    input_vals[2] = 30;

    for (i = 0; i < 3; i = i + 1) begin
      // data_in = input value, compute bit (bit 2) = 1
      ui_in = input_vals[i] | 8'b00000100;
      @(posedge clk);
      ui_in = 0;
      @(posedge clk);
    end
    wait_cycles(2);

    // STEP 3: Read out results
    $display("Reading results...");
    ui_in = 8'b00001000;   // read_out = bit 3
    @(posedge clk);
    ui_in = 0;

    result_bits = 0;
    for (bit_idx = 63; bit_idx >= 0; bit_idx = bit_idx - 1) begin
      @(posedge clk);
      result_bits[bit_idx] = uo_out[0];
    end

    // Unpack — use individual regs, not array indexing with part-select
    accum0 = result_bits[63:48];
    accum1 = result_bits[47:32];
    accum2 = result_bits[31:16];
    accum3 = result_bits[15:0];

    $display("accum0 = %0d (expected 60)",  accum0);
    $display("accum1 = %0d (expected 120)", accum1);
    $display("accum2 = %0d (expected 180)", accum2);
    $display("accum3 = %0d (expected 240)", accum3);

    if (accum0==60 && accum1==120 && accum2==180 && accum3==240)
      $display("PASS: All accumulators match expected values!");
    else
      $display("FAIL: Mismatch detected. Check waveforms in GTKWave.");

    $finish;
  end

endmodule
