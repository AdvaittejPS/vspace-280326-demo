`default_nettype none

module tt_um_jonathan_tanmay_logic_lock (
    input  wire [7:0] ui_in,    // [0]: key_data, [1]: key_shift
    output wire [7:0] uo_out,   // [0]: unlocked_led, [1]: blinker
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // --- I/O ASSIGNMENTS ---
    wire key_data;
    wire key_shift;
    assign key_data  = ui_in[0];
    assign key_shift = ui_in[1];
    assign uio_oe = 8'b0;
    assign uio_out = 8'b0;

    // --- SYNCHRONOUS KEY LOADING ---
    parameter [15:0] MASTER_KEY = 16'hA5C3; 
    reg [15:0] shift_reg;
    reg last_shift_state;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 16'h0000;
            last_shift_state <= 1'b0;
        end else if (ena) begin
            last_shift_state <= key_shift;
            // Rising edge detection
            if (key_shift == 1'b1 && last_shift_state == 1'b0) begin
                shift_reg <= {shift_reg[14:0], key_data};
            end
        end
    end

    // Comparison Logic
    wire is_locked;
    assign is_locked = (shift_reg != MASTER_KEY);
    
    // Status Outputs
    assign uo_out[0] = !is_locked; 
    assign uo_out[2] = 1'b0;
    assign uo_out[3] = 1'b0;
    assign uo_out[4] = 1'b0;
    assign uo_out[5] = 1'b0;
    assign uo_out[6] = 1'b0;
    assign uo_out[7] = 1'b0;

    // --- OBFUSCATED 24-BIT COUNTER ---
    reg [7:0]  lower_count;
    reg [15:0] upper_count;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            lower_count <= 8'b0;
        end else if (ena) begin
            lower_count <= lower_count + 1'b1;
        end
    end

    wire standard_carry;
    assign standard_carry = (lower_count == 8'hFF);

    wire poisoned_carry;
    assign poisoned_carry = standard_carry ^ is_locked;

    always @(posedge clk) begin
        if (!rst_n) begin
            upper_count <= 16'b0;
        end else if (ena && poisoned_carry) begin
            upper_count <= upper_count + 1'b1;
        end
    end

    assign uo_out[1] = upper_count[15];

endmodule
