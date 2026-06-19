`timescale 1ns/1ps
module spi_master_tb;
    localparam CLKS_PER_HALF_BIT = 4;

    reg        clk = 0, rst = 1, start = 0;
    reg  [7:0] tx_byte = 0;
    wire       busy, done, sclk, mosi, cs_n;
    wire [7:0] rx_byte;
    integer    errors = 0;

    wire miso;
    assign miso = mosi;            // loopback: slave echoes master

    spi_master #(.CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)) dut (
        .i_clk(clk), .i_rst(rst), .i_start(start), .i_tx_byte(tx_byte),
        .o_busy(busy), .o_done(done), .o_rx_byte(rx_byte),
        .o_sclk(sclk), .o_mosi(mosi), .o_cs_n(cs_n), .i_miso(miso));

    always #5 clk = ~clk;

    task send_and_check(input [7:0] b);
        begin
            @(posedge clk); tx_byte = b; start = 1;
            @(posedge clk); start = 0;
            @(posedge done);              // wait for transfer complete
            @(posedge clk);
            if (rx_byte === b)
                $display("PASS: TX 0x%02h -> RX 0x%02h", b, rx_byte);
            else begin
                $display("FAIL: TX 0x%02h -> RX 0x%02h", b, rx_byte);
                errors = errors + 1;
            end
            wait (busy == 1'b0);          // DUT readiness before next (your UART lesson!)
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("spi_master.vcd");
        $dumpvars(0, spi_master_tb);

        rst = 1; @(posedge clk); @(posedge clk); rst = 0;   // release reset
        @(posedge clk);

        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'hFF);
        send_and_check(8'h01);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule