module uart_tx #(parameter CLKS_PER_BIT = 87) (
    input i_clk,
    input i_tx_dv,
    input [7:0] i_tx_byte,
    output reg o_tx_active,
    output reg o_tx_serial,
    output reg o_tx_done
);

    localparam IDLE = 3'd0,
               START = 3'd1,
               DATA = 3'd2,
               STOP = 3'd3,
               CLEAN = 3'd4;

    reg [2:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_data = 0;

    always @(posedge i_clk) begin
        o_tx_done <= 1'b0;

        case (state)
            IDLE: begin
                o_tx_serial <= 1'b1;
                o_tx_active <= 1'b0;
                clk_count <= 0;
                bit_index <= 0;
                if(i_tx_dv) begin
                    tx_data <= i_tx_byte;
                    state <= START;
                end
            end

            START: begin
                o_tx_active <= 1'b1;
                o_tx_serial <= 1'b0;
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    state <= DATA;
                end
            end

            DATA: begin
                o_tx_serial <= tx_data[bit_index];
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    if (bit_index < 7)
                        bit_index <= bit_index + 1;
                    else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                o_tx_serial <= 1'b1;
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count+1;
                else begin
                    clk_count <= 0;
                    o_tx_done <= 1'b1;
                    o_tx_active <= 1'b0;
                    state <= CLEAN;
                end
            end

            CLEAN: begin
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
endmodule