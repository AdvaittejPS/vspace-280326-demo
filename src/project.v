/*
 * Sound-to-Light Rhythm Visualizer with Spike Filter
 * Tiny Tapeout compatible design
 *
 * Inputs  (ui_in[7:0]):
 *   ui_in[5:0]  - 6-bit audio level from envelope comparator
 *   ui_in[6]    - bypass spike filter (1 = raw, 0 = filtered)
 *   ui_in[7]    - unused
 *
 * Outputs (uo_out[7:0]):
 *   uo_out[5:0] - 6 LED outputs (bar graph)
 *   uo_out[7:6] - always 0
 *
 * Pipeline: inputs are registered each clock; output is combinational
 * from the registered values. So uo_out reflects ui_in from the
 * PREVIOUS clock cycle.
 *
 * Gate budget: ~700-900 gates
 */

`default_nettype none

module tt_um_sound_to_light (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // -------------------------------------------------------------------------
    // Tie off unused ports
    // -------------------------------------------------------------------------
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // -------------------------------------------------------------------------
    // Registered inputs — latch ui_in on every rising edge
    // -------------------------------------------------------------------------
    reg [5:0] reg_level;    // registered audio level (current sample, T)
    reg       reg_bypass;   // registered bypass flag

    // Shift register: stores previous samples
    reg [5:0] sample_r1;    // T-1 (one cycle ago)
    reg [5:0] sample_r2;    // T-2

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_level  <= 6'd0;
            reg_bypass <= 1'b0;
            sample_r1  <= 6'd0;
            sample_r2  <= 6'd0;
        end else if (ena) begin
            reg_level  <= ui_in[5:0];
            reg_bypass <= ui_in[6];
            sample_r1  <= reg_level;   // reg_level becomes T-1
            sample_r2  <= sample_r1;   // sample_r1 becomes T-2
        end
    end

    // -------------------------------------------------------------------------
    // Spike detector (combinational from registered values)
    // Spike = |reg_level - sample_r1| > SPIKE_THRESH
    // Uses unsigned comparison to avoid subtraction overflow
    // -------------------------------------------------------------------------
    localparam [6:0] SPIKE_THRESH = 7'd16;

    // Widen to 7 bits before adding to prevent 6-bit overflow
    wire spike_up   = ({1'b0, reg_level} > {1'b0, sample_r1} + SPIKE_THRESH);
    wire spike_down = ({1'b0, sample_r1} > {1'b0, reg_level} + SPIKE_THRESH);
    wire is_spike   = spike_up | spike_down;

    // -------------------------------------------------------------------------
    // Filtered output: if spike detected, hold previous sample (sample_r1)
    // -------------------------------------------------------------------------
    wire [5:0] filtered_level = is_spike ? sample_r1 : reg_level;

    // -------------------------------------------------------------------------
    // Bypass MUX
    // -------------------------------------------------------------------------
    wire [5:0] display_level = reg_bypass ? reg_level : filtered_level;

    // -------------------------------------------------------------------------
    // Level-to-LED mapper (thermometer bar graph, 6 LEDs)
    // Thresholds divide 0-63 into 6 bands
    // -------------------------------------------------------------------------
    wire led0 = (display_level >= 6'd1 );
    wire led1 = (display_level >= 6'd11);
    wire led2 = (display_level >= 6'd21);
    wire led3 = (display_level >= 6'd32);
    wire led4 = (display_level >= 6'd42);
    wire led5 = (display_level >= 6'd52);

    assign uo_out = {2'b00, led5, led4, led3, led2, led1, led0};

endmodule
