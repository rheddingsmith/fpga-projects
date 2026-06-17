`timescale 1ns/1ps
module uart_tx_tb;
    localparam CLKS_PER_BIT = 87;
    localparam BIT_PERIOD = 870;

    reg clk = 0;
    reg tx_dv = 0;
    reg [7:0] tx_byte = 0;
    wire tx_active, tx_serial, tx_done;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .i_clk(clk), .i_tx_dv(tx_dv), .i_tx_byte(tx_byte),
        .o_tx_active(tx_active), .o_tx_serial(tx_serial), .o_tx_done(tx_done)
    );

    always #5 clk = ~clk;

    reg [7:0] rx_byte; integer i; integer errors = 0;

    task check_byte(input [7:0] expected);
        begin
            @(negedge tx_serial);
            #(BIT_PERIOD + BIT_PERIOD/2);
            for (i = 0; i < 8; i = i + 1) begin
                rx_byte[i] = tx_serial;
                #(BIT_PERIOD);
            end
            if(rx_byte === expected)
                $display("PASS: sent %02h, recovered %02h", expected, rx_byte);
            else begin
                $display("FAIL: sent %02h, recovered %02h", expected, rx_byte);
                errors = errors + 1;
            end
        end
    endtask

    initial begin 
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        @(posedge clk);
        tx_byte = 8'hA5; tx_dv = 1; @(posedge clk); tx_dv = 0;
        check_byte(8'hA5);

        @(posedge clk);
        tx_byte = 8'h3C; tx_dv = 1; @(posedge clk); tx_dv = 0;
        check_byte(8'h3C);

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule