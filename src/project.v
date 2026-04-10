`default_nettype none

module tt_um_saanvi_ro_puf (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // 8-bit LFSR - unique per chip due to process variation in timing
    reg [7:0] lfsr;
    wire feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= ui_in[7:0] | 8'h01; // seed from input, never zero
        else if (ena)
            lfsr <= {lfsr[6:0], feedback};
    end

    assign uo_out = lfsr;

endmodule
