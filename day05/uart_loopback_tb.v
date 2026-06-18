`timescale 1ns/1ps
module uart_loopback_tb;
    localparam CLKS_PER_BIT = 87;

    reg        clk = 0, tx_dv = 0;
    reg  [7:0] tx_byte = 0;
    wire       tx_active, serial, tx_done, rx_dv;
    wire [7:0] rx_byte;
    integer    errors = 0;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) TX (
        .i_clk(clk), .i_tx_dv(tx_dv), .i_tx_byte(tx_byte),
        .o_tx_active(tx_active), .o_tx_serial(serial), .o_tx_done(tx_done));

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) RX (
        .i_clk(clk), .i_rx_serial(serial),       // <-- TX output feeds RX input
        .o_rx_dv(rx_dv), .o_rx_byte(rx_byte));

    always #5 clk = ~clk;

    task send_and_check(input [7:0] b);
    begin
        @(posedge clk);
        tx_byte = b; tx_dv = 1;
        @(posedge clk); tx_dv = 0;

        @(posedge rx_dv);             // RX captured a byte
        @(posedge clk);
        if (rx_byte === b)
            $display("PASS: TX 0x%02h -> RX 0x%02h", b, rx_byte);
        else begin
            $display("FAIL: TX 0x%02h -> RX 0x%02h", b, rx_byte);
            errors = errors + 1;
        end

        wait (tx_active == 1'b0);     // <-- NEW: let TX fully finish + return to IDLE
        @(posedge clk);
    end
endtask //second attempt: wait for tx to respond

    initial begin
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, uart_loopback_tb);

        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'hFF);
        send_and_check(8'h00);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule