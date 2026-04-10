`default_nettype none
`timescale 1ns / 1ps

module tb_logic_lock();
    reg clk;
    reg rst_n;
    reg ena;             
    reg [7:0] ui_in;
    reg [7:0] uio_in;    
    wire [7:0] uo_out;
    wire [7:0] uio_out;  
    wire [7:0] uio_oe;   

    // Instantiate with VCD dumping
    initial begin
        $display("Starting Logic Lock Standalone Test...");
        $dumpfile("logic_lock.vcd"); // Added: Target VCD file
        $dumpvars(0, tb_logic_lock);  // Added: Dumps full hierarchy
    end

    tt_um_logic_lock uut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

endmodule
