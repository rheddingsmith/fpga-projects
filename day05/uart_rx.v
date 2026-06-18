// uart_rx.v - 8N1 UART receiver with 2-FF input synchronizer
module uart_rx #(parameter CLKS_PER_BIT = 87) (
    input            i_clk,
    input            i_rx_serial,    // raw async serial in
    output reg       o_rx_dv,        // pulses high 1 cycle when a byte is ready
    output reg [7:0] o_rx_byte       // the received byte
);
    localparam IDLE  = 3'd0,
               START = 3'd1,
               DATA  = 3'd2,
               STOP  = 3'd3,
               CLEAN = 3'd4;

    // --- 2-FF synchronizer: tame the asynchronous input ---
    reg rx_d1 = 1'b1, rx_sync = 1'b1;
    always @(posedge i_clk) begin
        rx_d1   <= i_rx_serial;
        rx_sync <= rx_d1;            // use rx_sync everywhere, never i_rx_serial directly
    end

    reg [2:0]  state     = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  rx_data   = 0;

    always @(posedge i_clk) begin
        o_rx_dv <= 1'b0;             // default: pulses for 1 cycle only

        case (state)
            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
                if (rx_sync == 1'b0) // line dropped -> start bit
                    state <= START;
            end

            START: begin             // confirm start at its midpoint
                if (clk_count == (CLKS_PER_BIT-1)/2) begin
                    if (rx_sync == 1'b0) begin
                        clk_count <= 0;       // realign: count from mid-start
                        state     <= DATA;
                    end else
                        state <= IDLE;        // glitch, not a real start
                end else
                    clk_count <= clk_count + 1;
            end

            DATA: begin              // sample each data bit at its midpoint
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count          <= 0;
                    rx_data[bit_index] <= rx_sync;   // LSB first
                    if (bit_index < 7)
                        bit_index <= bit_index + 1;
                    else begin
                        bit_index <= 0;
                        state     <= STOP;
                    end
                end
            end

            STOP: begin              // wait out the stop bit, then publish
                if (clk_count < CLKS_PER_BIT-1)
                    clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    o_rx_byte <= rx_data;
                    o_rx_dv   <= 1'b1;   // byte ready!
                    state     <= CLEAN;
                end
            end

            CLEAN:   state <= IDLE;
            default: state <= IDLE;
        endcase
    end
endmodule