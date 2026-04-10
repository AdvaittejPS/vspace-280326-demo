`default_nettype none
module tt_um_saanvi_ro_puf #(
    parameter CLOCKS_PER_SECOND = 24'd9_999_999
)(
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
    wire start_pause_btn = ui_in[0];
    wire [6:0] led_segments;
    assign uo_out[6:0] = led_segments;
    assign uo_out[7]   = 1'b0;

    reg [23:0] clock_counter;
    wire one_second_pulse = (clock_counter == CLOCKS_PER_SECOND);
    always @(posedge clk or posedge reset_active) begin
        if (reset_active) clock_counter <= 0;
        else if (start_pause_btn) begin
            if (one_second_pulse) clock_counter <= 0;
            else clock_counter <= clock_counter + 1;
        end
    end

    reg [3:0] current_digit;
    always @(posedge clk or posedge reset_active) begin
        if (reset_active) current_digit <= 0;
        else if (start_pause_btn && one_second_pulse) begin
            if (current_digit == 9) current_digit <= 0;
            else current_digit <= current_digit + 1;
        end
    end

    reg [6:0] decoded_leds;
    assign led_segments = decoded_leds;
    always @(*) begin
        case (current_digit)
            4'd0: decoded_leds = 7'b0111111;
            4'd1: decoded_leds = 7'b0000110;
            4'd2: decoded_leds = 7'b1011011;
            4'd3: decoded_leds = 7'b1001111;
            4'd4: decoded_leds = 7'b1100110;
            4'd5: decoded_leds = 7'b1101101;
            4'd6: decoded_leds = 7'b1111101;
            4'd7: decoded_leds = 7'b0000111;
            4'd8: decoded_leds = 7'b1111111;
            4'd9: decoded_leds = 7'b1101111;
            default: decoded_leds = 7'b0000000;
        endcase
    end
endmodule
