`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $display("Starting Logic Lock Simulation...");
    $dumpfile("tb.vcd");         // Added: Sets dump file name to VCD
    $dumpvars(0, tb);            // Added: Dumps all signals in the 'tb' hierarchy
    #1; 
  end

  // Standard Tiny Tapeout Signals
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Instantiate the Logic Lock Module [cite: 5, 13]
  tt_um_logic_lock user_project (
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

