/*
 * tb.v — Passive cocotb toplevel for Sound-to-Light Rhythm Visualizer
 *
 * This file ONLY instantiates the DUT and exposes its ports.
 * ALL stimulus, clocking, and assertions are driven by test.py via cocotb.
 * Do NOT add any initial blocks, always blocks, or clock generation here.
 */

`timescale 1us/1ns
`default_nettype none

module tb (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    tt_um_sound_to_light dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

endmodule
