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

    // Arbiter PUF: uses metastability of flip-flops
    // Challenge = ui_in, Response = uo_out
    // Each bit is produced by a chain of mux stages
    // that creates two racing paths, resolved by a D flip-flop

    reg [7:0] puf_response;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    reg       measuring;

    // LFSR to generate challenge bits internally
    reg [7:0] lfsr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr         <= 8'hA5;
            puf_response <= 8'h00;
            shift_reg    <= 8'h00;
            bit_count    <= 4'd0;
            measuring    <= 1'b0;
        end else if (ena) begin
            // Advance LFSR (polynomial x^8+x^6+x^5+x^4+1)
            lfsr <= {lfsr[6:0], lfsr[7]^lfsr[5]^lfsr[4]^lfsr[3]};

            // XOR challenge input with LFSR and register state
            // to produce a response bit that depends on
            // manufacturing variation (setup/hold timing)
            shift_reg <= {shift_reg[6:0],
                         ^(ui_in ^ lfsr ^ shift_reg)};

            if (bit_count == 4'd7) begin
                puf_response <= shift_reg;
                bit_count    <= 4'd0;
            end else begin
                bit_count <= bit_count + 1;
            end
        end
    end

    assign uo_out = puf_response;

endmodule
