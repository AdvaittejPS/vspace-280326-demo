`timescale 1ns/1ps
module tb;

  reg clk;
  reg rst_n;
  reg [7:0] ui_in;   // control signals only: [4]=clear,[3]=read_out,[2]=compute,[1]=load_weights,[0]=serial_in
  reg [7:0] uio_in;  // data input for MAC compute steps
  wire [7:0] uo_out;
  wire [7:0] uio_out, uio_oe;

  initial begin
    clk    = 0;
    rst_n  = 0;
    ui_in  = 0;
    uio_in = 0;
  end

  always #5 clk = ~clk;

  tt_um_neuracc dut (
    .clk(clk), .rst_n(rst_n),
    .ui_in(ui_in), .uo_out(uo_out),
    .uio_in(uio_in), .uio_out(uio_out),
    .uio_oe(uio_oe), .ena(1'b1)
  );

  task wait_cycles(input integer n);
    integer i;
    for (i = 0; i < n; i = i + 1) @(posedge clk);
  endtask

  integer bit_idx;
  reg [31:0] weight_bits;
  reg [63:0] result_bits;
  reg [15:0] accum0, accum1, accum2, accum3;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset
    @(posedge clk);
    rst_n = 0;
    wait_cycles(3);
    rst_n = 1;
    wait_cycles(2);

    // -------------------------------------------------------
    // STEP 1: Load weights [1, 2, 3, 4]
    // Send MSB-first: {w3=4, w2=3, w1=2, w0=1} so that after
    // 32 serial shifts, unit0 holds weight=1, unit1=2, unit2=3, unit3=4.
    // -------------------------------------------------------
    weight_bits = {8'd4, 8'd3, 8'd2, 8'd1};
    $display("Loading weights: 1, 2, 3, 4");

    // Assert load_weights for one cycle to enter LOAD_W state
    @(negedge clk); ui_in = 8'b00000010;  // load_weights=1
    // Drop load_weights and present first bit simultaneously —
    // the first load_w_bit pulse fires on the next posedge
    @(negedge clk); ui_in = {7'b0, weight_bits[31]};

    // Send remaining 31 bits
    for (bit_idx = 30; bit_idx >= 0; bit_idx = bit_idx - 1) begin
      @(negedge clk);
      ui_in = {7'b0, weight_bits[bit_idx]};
    end
    @(negedge clk); ui_in = 0;
    wait_cycles(3);

    // -------------------------------------------------------
    // STEP 2: Compute — data on uio_in, compute strobe on ui_in[2]
    // Data and compute can be asserted simultaneously since they
    // are on separate buses.
    // -------------------------------------------------------
    $display("Computing with inputs: 10, 20, 30");

    @(negedge clk); uio_in = 8'd10; ui_in = 8'b00000100;  // compute with data=10
    @(negedge clk); uio_in = 0;     ui_in = 0;

    @(negedge clk); uio_in = 8'd20; ui_in = 8'b00000100;  // compute with data=20
    @(negedge clk); uio_in = 0;     ui_in = 0;

    @(negedge clk); uio_in = 8'd30; ui_in = 8'b00000100;  // compute with data=30
    @(negedge clk); uio_in = 0;     ui_in = 0;

    wait_cycles(3);

    // -------------------------------------------------------
    // STEP 3: Read out 64-bit result serially
    // Pulse read_out → FSM loads shift register one cycle later
    // (load_parallel_r is registered). Then 63 shift pulses follow.
    // Sample serial_out right after the load posedge for bit63,
    // then after each subsequent shift posedge for bits 62..0.
    // -------------------------------------------------------
    $display("Reading results...");
    @(negedge clk); ui_in = 8'b00001000;  // read_out=1
    @(negedge clk); ui_in = 0;

    // Next posedge: load_parallel fires, shift_reg = {accum0,accum1,accum2,accum3}
    // serial_out = shift_reg[63] = accum0[15] right after this edge
    @(posedge clk);
    result_bits = 0;
    result_bits[63] = uo_out[0];  // capture bit63 before first shift

    // Each subsequent posedge shifts left; capture the new MSB
    for (bit_idx = 62; bit_idx >= 0; bit_idx = bit_idx - 1) begin
      @(posedge clk);
      result_bits[bit_idx] = uo_out[0];
    end

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
      $display("FAIL: Mismatch detected.");

    $finish;
  end
endmodule
