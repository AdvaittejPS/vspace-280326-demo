module tt_um_traffic_smart (
    input wire clk,
    input wire rst_n,
    input wire [7:0] ui_in,
    output reg [7:0] uo_out
);

    wire reset = ~rst_n;

    // Inputs
    wire pedestrian = ui_in[0];
    wire night_mode = ui_in[1];
    wire emergency  = ui_in[2];

    // Clock divider (approx slow tick)
    reg [23:0] clk_div;
    wire tick = (clk_div == 24'd10_000_000);

    always @(posedge clk or posedge reset) begin
        if (reset)
            clk_div <= 0;
        else if (tick)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end

    // FSM States
    reg [2:0] state;
    reg [3:0] timer;

    parameter RED     = 3'b000;
    parameter GREEN   = 3'b001;
    parameter YELLOW  = 3'b010;
    parameter NIGHT   = 3'b011;
    parameter EMERG   = 3'b100;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= RED;
            timer <= 0;
        end else if (tick) begin

            // Emergency override
            if (emergency)
                state <= EMERG;

            else if (night_mode)
                state <= NIGHT;

            else begin
                timer <= timer + 1;

                case (state)
                    RED: begin
                        if (timer == 5) begin
                            state <= GREEN;
                            timer <= 0;
                        end
                    end

                    GREEN: begin
                        if (pedestrian || timer == 5) begin
                            state <= YELLOW;
                            timer <= 0;
                        end
                    end

                    YELLOW: begin
                        if (timer == 2) begin
                            state <= RED;
                            timer <= 0;
                        end
                    end
                endcase
            end
        end
    end

    // Output logic
    always @(*) begin
        case (state)
            RED:    uo_out = 8'b00000001;
            GREEN:  uo_out = 8'b00000100;
            YELLOW: uo_out = 8'b00000010;

            // Night mode → blinking yellow
            NIGHT:  uo_out = clk_div[23] ? 8'b00000010 : 8'b00000000;

            // Emergency → all red
            EMERG:  uo_out = 8'b00000001;

            default: uo_out = 8'b00000000;
        endcase
    end

endmodule