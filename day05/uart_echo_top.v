// uart_echo_top.v - receive a byte over USB-UART, echo it back, show it on LEDs
module uart_echo_top (
    input  wire       clk,        // 100 MHz, pin W5
    input  wire       RsRx,       // serial in  from PC
    output wire       RsTx,       // serial out to  PC
    output wire [7:0] led         // last received byte (bonus visual)
);
    localparam CLKS_PER_BIT = 868;   // 100,000,000 / 115200 -- REAL hardware value

    wire       rx_dv;
    wire [7:0] rx_byte;
    wire       tx_active, tx_serial, tx_done;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) RX (
        .i_clk(clk), .i_rx_serial(RsRx),
        .o_rx_dv(rx_dv), .o_rx_byte(rx_byte));

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) TX (
        .i_clk(clk), .i_tx_dv(rx_dv), .i_tx_byte(rx_byte),  // echo: RX feeds TX
        .o_tx_active(tx_active), .o_tx_serial(tx_serial), .o_tx_done(tx_done));

    assign RsTx = tx_serial;        // TX idles high, so this is safe to drive directly
    assign led  = rx_byte;          // show the byte's bits on LED0-7
endmodule