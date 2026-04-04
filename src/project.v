// project.v — NeurAcc, 4-element weight-stationary MAC accelerator.
// ui_in[0]=serial_in, [1]=load_weights, [2]=compute, [3]=read_out, [4]=clear_accum
// uio_in[7:0]=data_in
// uo_out[0]=serial_out, [1]=ready
`timescale 1ns/1ps

module tt_um_neuracc (
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

  wire serial_in    = ui_in[0];
  wire load_weights = ui_in[1];
  wire compute      = ui_in[2];
  wire read_out     = ui_in[3];
  wire clear_accum  = ui_in[4];
  wire [7:0] data_in = uio_in;

  localparam IDLE    = 2'd0;
  localparam LOAD_W  = 2'd1;
  localparam READOUT = 2'd2;

  reg [1:0] state;
  reg [5:0] bit_cnt;
  reg       load_par_r;

  // Combinational: fire in the same cycle as the state is active
  wire do_compute = (state == IDLE)   && compute;
  wire do_clear   = (state == IDLE)   && clear_accum;
  wire load_w_bit = (state == LOAD_W);
  wire do_shift   = (state == READOUT);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= IDLE;
      bit_cnt    <= 6'd0;
      load_par_r <= 1'b0;
    end else begin
      load_par_r <= 1'b0;

      case (state)
        IDLE: begin
          if (load_weights) begin
            bit_cnt <= 6'd0;
            state   <= LOAD_W;
          end else if (read_out) begin
            load_par_r <= 1'b1;
            bit_cnt    <= 6'd0;
            state      <= READOUT;
          end
        end

        LOAD_W: begin
          if (bit_cnt == 6'd15) begin
            bit_cnt <= 6'd0;
            state   <= IDLE;
          end else begin
            bit_cnt <= bit_cnt + 1;
          end
        end

        READOUT: begin
          if (bit_cnt == 6'd39) begin
            bit_cnt <= 6'd0;
            state   <= IDLE;
          end else begin
            bit_cnt <= bit_cnt + 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  wire [9:0] accum0, accum1, accum2, accum3;
  wire       serial_out_wire;

  mac_array u_array (
    .clk(clk), .rst_n(rst_n),
    .load_w_bit(load_w_bit), .w_serial_in(serial_in),
    .compute(do_compute), .clear(do_clear),
    .data_in(data_in),
    .accum0(accum0), .accum1(accum1), .accum2(accum2), .accum3(accum3),
    .w_serial_out()
  );

  output_scan u_scan (
    .clk(clk), .rst_n(rst_n),
    .load_parallel(load_par_r),
    .shift(do_shift),
    .accum0(accum0), .accum1(accum1), .accum2(accum2), .accum3(accum3),
    .serial_out(serial_out_wire),
    .bit_idx(bit_cnt)
  );

  assign uo_out[0] = serial_out_wire;
  assign uo_out[1] = (state == IDLE);
  assign uo_out[7:2] = 6'b0;

endmodule
