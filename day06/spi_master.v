// spi_master.v - SPI Mode 0 master, 8-bit, MSB-first
module spi_master #(
    parameter CLKS_PER_HALF_BIT = 4   // SCLK period = 2*CLKS_PER_HALF_BIT system clocks
)(
    input            i_clk,
    input            i_rst,
    // control interface
    input            i_start,      // pulse to begin a transfer
    input      [7:0] i_tx_byte,    // byte to send
    output reg       o_busy,       // high during a transfer
    output reg       o_done,       // 1-cycle pulse when complete
    output reg [7:0] o_rx_byte,    // byte received
    // SPI bus
    output reg       o_sclk,
    output reg       o_mosi,
    output reg       o_cs_n,       // chip select, active LOW
    input            i_miso
);
    localparam IDLE = 2'd0, LOW_PHASE = 2'd1, HIGH_PHASE = 2'd2, FINISH = 2'd3;

    reg [1:0]  state;
    reg [15:0] count;       // half-bit timer
    reg [2:0]  bit_index;   // current bit, 7 down to 0 (MSB first)
    reg [7:0]  tx_data, rx_data;

    always @(posedge i_clk) begin
        o_done <= 1'b0;                       // default -> 1-cycle pulse

        if (i_rst) begin
            state  <= IDLE;
            o_sclk <= 1'b0;                   // CPOL=0: idle low
            o_cs_n <= 1'b1;                   // deselected
            o_mosi <= 1'b0;
            o_busy <= 1'b0;
            count  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_sclk <= 1'b0;
                    o_cs_n <= 1'b1;
                    o_busy <= 1'b0;
                    count  <= 0;
                    if (i_start) begin
                        tx_data   <= i_tx_byte;
                        o_mosi    <= i_tx_byte[7];  // MSB first; set up while SCLK low
                        bit_index <= 3'd7;
                        o_cs_n    <= 1'b0;          // select the slave
                        o_busy    <= 1'b1;
                        state     <= LOW_PHASE;
                    end
                end

                // SCLK low for half a bit, then rising edge -> sample MISO
                LOW_PHASE: begin
                    if (count < CLKS_PER_HALF_BIT-1)
                        count <= count + 1;
                    else begin
                        count              <= 0;
                        o_sclk             <= 1'b1;       // rising (leading) edge
                        rx_data[bit_index] <= i_miso;     // Mode 0: sample on rising edge
                        state              <= HIGH_PHASE;
                    end
                end

                // SCLK high for half a bit, then falling edge -> next bit
                HIGH_PHASE: begin
                    if (count < CLKS_PER_HALF_BIT-1)
                        count <= count + 1;
                    else begin
                        count  <= 0;
                        o_sclk <= 1'b0;                   // falling (trailing) edge
                        if (bit_index == 3'd0)
                            state <= FINISH;              // all 8 bits done
                        else begin
                            bit_index <= bit_index - 1;
                            o_mosi    <= tx_data[bit_index-1];  // present next bit
                            state     <= LOW_PHASE;
                        end
                    end
                end

                FINISH: begin
                    o_cs_n    <= 1'b1;        // deselect
                    o_busy    <= 1'b0;
                    o_rx_byte <= rx_data;     // publish received byte
                    o_done    <= 1'b1;        // pulse done
                    state     <= IDLE;
                end
            endcase
        end
    end
endmodule