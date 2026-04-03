`timescale 1ns/1ps
module tb;
// ── DUT ports ─────────────────────────────────────────────────
reg clk = 0, rst_n = 0;
reg [7:0] ui_in = 0;
wire [7:0] uo_out;
wire [7:0] uio_out, uio_oe;
// ── Instantiate design under test ────────────────────────────
tt_um_neuracc dut (
.clk(clk), .rst_n(rst_n),
.ui_in(ui_in), .uo_out(uo_out),
.uio_in(8'b0), .uio_out(uio_out),
.uio_oe(uio_oe), .ena(1'b1)
);
// Clock: flips every 5ns => 100 MHz
always #5 clk = ~clk;
// Helper task: wait N clock cycles
task wait_cycles(input integer n);
integer i;
for (i = 0; i < n; i = i + 1) @(posedge clk);
endtask
integer i, bit_idx;
reg [31:0] weight_bits; // 4 weights packed = 32 bits
reg [63:0] result_bits; // 4 x 16-bit results = 64 bits
reg [15:0] accum [0:3];
initial begin
$dumpfile("dump.vcd");
$dumpvars(0, tb);
// ── Reset ───────────────────────────────────────────────────
rst_n = 0; ui_in = 0;
wait_cycles(3);
rst_n = 1;
wait_cycles(2);
// ── STEP 1: Load weights [1, 2, 3, 4] ──────────────────────
// Pack into 32 bits: w0 in [31:24], w1 in [23:16], w2 in [15:8], w3 in
[7:0]
weight_bits = {8'd1, 8'd2, 8'd3, 8'd4};
$display('Loading weights: 1, 2, 3, 4');
ui_in[1] = 1; // assert load_weights to start FSM
@(posedge clk); // FSM sees load_weights, enters LOAD_W state
ui_in[1] = 0;
// Send 32 bits MSB-first into serial_in (ui_in[0])
for (bit_idx = 31; bit_idx >= 0; bit_idx = bit_idx - 1) begin
ui_in[0] = weight_bits[bit_idx];
@(posedge clk);
end
ui_in[0] = 0;
wait_cycles(2);
// ── STEP 2: Compute 3 MAC steps with inputs 10, 20, 30 ─────
$display('Computing with inputs: 10, 20, 30');
begin : compute_block
integer inputs [0:2];
inputs[0] = 10; inputs[1] = 20; inputs[2] = 30;
for (i = 0; i < 3; i = i + 1) begin
ui_in = inputs[i]; // set data_in
ui_in[2] = 1; // assert compute
@(posedge clk);
ui_in[2] = 0;
ui_in = 0;
@(posedge clk);
end
end
wait_cycles(2);
// ── STEP 3: Read out results ────────────────────────────────
$display('Reading results...');
ui_in[3] = 1; // assert read_out
@(posedge clk);
ui_in[3] = 0;
// Capture 64 bits of serial output MSB-first
for (bit_idx = 63; bit_idx >= 0; bit_idx = bit_idx - 1) begin
@(posedge clk);
result_bits[bit_idx] = uo_out[0];
end
// Unpack into 4 x 16-bit accumulators
accum[0] = result_bits[63:48];
accum[1] = result_bits[47:32];
accum[2] = result_bits[31:16];
accum[3] = result_bits[15:0];
$display('accum[0] = %0d (expected 60)', accum[0]);
$display('accum[1] = %0d (expected 120)', accum[1]);
$display('accum[2] = %0d (expected 180)', accum[2]);
$display('accum[3] = %0d (expected 240)', accum[3]);
if (accum[0]==60 && accum[1]==120 && accum[2]==180 && accum[3]==240)
$display('PASS: All accumulators match expected values!');
else
$display('FAIL: Mismatch detected. Check waveforms in GTKWave.');
$finish;
end
endmodule

