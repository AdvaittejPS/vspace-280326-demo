// project.v
// Top-level module for NeurAcc — Neural Network MAC Accelerator.
// Implements a 4-element weight-stationary systolic MAC array.
//
// Pin mapping:
// ui_in[7:0] = data_in (8-bit input for compute mode)
// ui_in[0] = serial_in (weight bit in load mode)
// ui_in[1] = load_weights (start loading weights)
// ui_in[2] = compute (do one MAC step)
// ui_in[3] = read_out (start reading results)
// ui_in[4] = clear_accum (reset accumulators)
// uo_out[0] = serial_out (result bit out)
// uo_out[1] = ready

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

  // Pin aliases
  wire       serial_in    = ui_in[0];
  wire       load_weights = ui_in[1];
  wire       compute      = ui_in[2];
  wire       read_out     = ui_in[3];
  wire       clear_accum  = ui_in[4];
  wire [7:0] data_in      = ui_in;

  // FSM states
  localparam IDLE     = 2'd0;
  localparam LOAD_W   = 2'd1;
  localparam READ_OUT = 2'd2;

  reg [1:0] state;
  reg [5:0] bit_cnt;

  // Control signals — combinational, no one-cycle delay
  reg load_w_bit_r;
  reg load_parallel_r;
  reg do_shift_r;

  // do_compute and do_clear are pure combinational
  wire do_compute    = (state == IDLE) && compute;
  wire do_clear      = (state == IDLE) && clear_accum;
  wire load_w_bit    = load_w_bit_r;
  wire load_parallel = load_parallel_r;
  wire do_shift      = do_shift_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state          <= IDLE;
      bit_cnt        <= 6'd0;
      load_w_bit_r   <= 1'b0;
      load_parallel_r<= 1'b0;
      do_shift_r     <= 1'b0;
    end else begin
      // Default all registered controls to 0
      load_w_bit_r    <= 1'b0;
      load_parallel_r <= 1'b0;
      do_shift_r      <= 1'b0;

      case (state)
        IDLE: begin
          if (load_weights) begin
            bit_cnt <= 6'd0;
            state   <= LOAD_W;
          end else if (read_out) begin
            load_parallel_r <= 1'b1;
            bit_cnt         <= 6'd0;
            state           <= READ_OUT;
          end
          // do_compute and do_clear are combinational — no action needed here
        end

        LOAD_W: begin
          load_w_bit_r <= 1'b1;
          if (bit_cnt == 6'd31) begin
            bit_cnt <= 6'd0;
            state   <= IDLE;
          end else begin
            bit_cnt <= bit_cnt + 1;
          end
        end

        READ_OUT: begin
          do_shift_r <= 1'b1;
          if (bit_cnt == 6'd63) begin
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

  // Module instantiations
  wire [15:0] accum0, accum1, accum2, accum3;
  wire        serial_out_wire;

  mac_array u_array (
    .clk(clk), .rst_n(rst_n),
    .load_w_bit(load_w_bit), .w_serial_in(serial_in),
    .compute(do_compute), .clear(do_clear),
    .data_in(data_in),
    .accum0(accum0), .accum1(accum1),
    .accum2(accum2), .accum3(accum3),
    .w_serial_out()
  );

  output_scan u_scan (
    .clk(clk), .rst_n(rst_n),
    .load_parallel(load_parallel), .shift(do_shift),
    .accum0(accum0), .accum1(accum1),
    .accum2(accum2), .accum3(accum3),
    .serial_out(serial_out_wire)
  );

  assign uo_out[0] = serial_out_wire;
  assign uo_out[1] = (state == IDLE);
  assign uo_out[7:2] = 6'b0;

endmodule
