// uart_tx.v - 8N1 UART transmitter
module uart_tx #(parameter CLKS_PER_BIT = 87) (
    input        i_clk,
    input        i_tx_dv,      // "data valid": pulse high 1 cycle to start a send
    input  [7:0] i_tx_byte,    // the byte to transmit
    output reg   o_tx_active,  // high while a frame is in progress
    output reg   o_tx_serial,  // THE wire: serial output
    output reg   o_tx_done     // pulses high 1 cycle when the frame finishes
);
    localparam IDLE  = 3'd0,
               START = 3'd1,
               DATA  = 3'd2,
               STOP  = 3'd3,
               CLEAN = 3'd4;

    reg [2:0]  state     = IDLE;
    reg [15:0] clk_count = 0;    // counts clocks within one bit
    reg [2:0]  bit_index = 0;    // which data bit (0..7)
    reg [7:0]  tx_data   = 0;    // latched copy of the byte

    always @(posedge i_clk) begin
        o_tx_done <= 1'b0;                       // default: only pulses

        case (state)
            IDLE: begin
                o_tx_serial <= 1'b1;             // line idles HIGH
                o_tx_active <= 1'b0;
                clk_count   <= 0;
                bit_index   <= 0;
                if (i_tx_dv) begin               // start requested
                    tx_data <= i_tx_byte;        // capture the byte
                    state   <= START;
                end
            end

            START: begin                         // drive start bit = 0
                o_tx_active <= 1'b1;
                o_tx_serial <= 1'b0;
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    state     <= DATA;
                end
            end

            DATA: begin                          // drive 8 data bits, LSB first
                o_tx_serial <= tx_data[bit_index];
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    if (bit_index < 7)
                        bit_index <= bit_index + 1;
                    else begin
                        bit_index <= 0;
                        state     <= STOP;
                    end
                end
            end

            STOP: begin                          // drive stop bit = 1
                o_tx_serial <= 1'b1;
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count   <= 0;
                    o_tx_done   <= 1'b1;
                    o_tx_active <= 1'b0;
                    state       <= CLEAN;
                end
            end

            CLEAN: begin
                state <= IDLE;                    // one cycle of breathing room
            end

            default: state <= IDLE;
        endcase
    end
endmodule