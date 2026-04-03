/ output_scan.v
// Serialises four 16-bit accumulator values into a 1-bit output stream.
// When load_parallel=1, captures the 4 accumulators.
// Then shifts out 64 bits MSB-first, one bit per clock.
module output_scan (
input wire clk,
input wire rst_n,
input wire load_parallel, // capture accumulators now
input wire shift, // shift one bit out
input wire [15:0] accum0, accum1, accum2, accum3,
output wire serial_out
);
reg [63:0] shift_reg;
always @(posedge clk or negedge rst_n) begin
if (!rst_n)
shift_reg <= 64'b0;
else if (load_parallel)
// Pack all 4 results into one 64-bit shift register
// accum0 in bits [63:48], accum1 in [47:32], etc.
shift_reg <= {accum0, accum1, accum2, accum3};
NeurAcc — MAC Accelerator Guide | Page 14
else if (shift)
// Shift left: MSB goes out, zeros fill from right
shift_reg <= {shift_reg[62:0], 1'b0};
end
// Serial output is always the MSB of the shift register
assign serial_out = shift_reg[63];
endmodule
