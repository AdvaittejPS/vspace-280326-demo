tt_um_traffic_smart
`ifndef GL_TEST
#(
    .CLOCKS_PER_SECOND(24'd9)
)
`endif
uut (

`ifdef GL_TEST
    .VPWR(VPWR),
    .VGND(VGND),
`endif

    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
);