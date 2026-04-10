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

    // 8 ring oscillators using LUT-based delay chains
    // Each RO is 5 inverter stages in a loop
    // Using (* keep *) to prevent optimization
    wire [7:0] ro_out;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ro_gen
            (* keep *) wire [4:0] ro_chain;
            assign ro_chain[0] = ~ro_chain[4] & ena;
            assign ro_chain[1] = ~ro_chain[0];
            assign ro_chain[2] = ~ro_chain[1];
            assign ro_chain[3] = ~ro_chain[2];
            assign ro_chain[4] = ~ro_chain[3];
            assign ro_out[i]   =  ro_chain[4];
        end
    endgenerate

    // 8 x 16-bit counters, one per RO
    reg [15:0] counters [0:7];
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < 8; j = j + 1)
                counters[j] <= 16'd0;
        end else if (ena) begin
            for (j = 0; j < 8; j = j + 1)
                counters[j] <= counters[j] + {15'd0, ro_out[j]};
        end
    end

    // Challenge: ui_in selects which pair of ROs to compare
    // Each output bit compares adjacent RO pair
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : cmp_gen
            assign uo_out[k] = (counters[k] > counters[(k+1) % 8]) ? 1'b1 : 1'b0;
        end
    endgenerate

endmodule
