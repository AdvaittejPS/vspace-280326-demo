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

    wire reset_active = !rst_n;
    wire start = ui_in[0];

    reg [7:0] cnt_a, cnt_b;
    reg [7:0] window;
    reg       measuring;
    reg [7:0] response_reg;

    // Ring oscillator outputs (process variation = PUF fingerprint)
    wire ro_a, ro_b;
    ro_cell roa (.out(ro_a));
    ro_cell rob (.out(ro_b));

    always @(posedge clk or posedge reset_active) begin
        if (reset_active) begin
            cnt_a <= 0; cnt_b <= 0;
            window <= 0; measuring <= 0;
            response_reg <= 0;
        end else if (start && !measuring) begin
            cnt_a <= 0; cnt_b <= 0;
            window <= 8'd255; measuring <= 1;
        end else if (measuring) begin
            if (ro_a) cnt_a <= cnt_a + 1;
            if (ro_b) cnt_b <= cnt_b + 1;
            window <= window - 1;
            if (window == 1) begin
                measuring <= 0;
                response_reg <= (cnt_a > cnt_b) ? 8'hAA : 8'h55;
            end
        end
    end

    assign uo_out = response_reg;
endmodule

(* keep *) module ro_cell (output wire out);
    wire w0,w1,w2,w3,w4;
    assign w1 = ~w0;
    assign w2 = ~w1;
    assign w3 = ~w2;
    assign w4 = ~w3;
    assign w0 = ~w4;
    assign out = w0;
endmodule
