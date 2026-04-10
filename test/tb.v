`default_nettype none
`timescale 1ns / 1ps

module tb ();
    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
        #1;
    end

    reg clk;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

`ifdef GL_TEST
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
`endif

    tt_um_saanvi_ro_puf
`ifndef GL_TEST
    #()
`endif
    user_project (
`ifdef GL_TEST
        .VPWR(VPWR),
        .VGND(VGND),
`endif
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    always #5 clk = ~clk;

    initial begin
        clk    = 0;
        rst_n  = 0;
        ena    = 0;
        ui_in  = 8'b0;
        uio_in = 8'b0;

        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // Enable PUF measurement
        ena = 1;
        repeat(300) @(posedge clk);

        // Just check output is a valid 8-bit value (not X or Z)
        if (^uo_out === 1'bx) begin
            $display("FAIL: output has unknown bits");
            $fatal;
        end else begin
            $display("PASS: PUF response = %b (%h)", uo_out, uo_out);
        end

        $finish;
    end
endmodule
