`timescale 1ns/1ps
module i2c_tb;
    localparam CLKS_PER_QUARTER = 5;     // small for fast sim
    reg clk=0, rst=1, start=0;
    reg [6:0] addr=0; reg [7:0] data=0;
    wire busy, done, ack_err, scl, sda;
    integer errors=0;

    pullup(scl);   // open-drain bus idles high
    pullup(sda);

    i2c_master #(.CLKS_PER_QUARTER(CLKS_PER_QUARTER)) dut (
        .i_clk(clk), .i_rst(rst), .i_start(start), .i_addr(addr), .i_data(data),
        .o_busy(busy), .o_done(done), .o_ack_error(ack_err),
        .io_scl(scl), .io_sda(sda));

    i2c_slave_model #(.SLAVE_ADDR(7'h27)) slave (.scl(scl), .sda(sda));

    always #5 clk = ~clk;

    task do_write(input [6:0] a, input [7:0] d);
        begin
            @(posedge clk); addr=a; data=d; start=1;
            @(posedge clk); start=0;
            @(posedge done); @(posedge clk);
            if (ack_err) begin
                $display("FAIL: addr 0x%02h got NACK", a); errors=errors+1;
            end else
                $display("PASS: wrote 0x%02h to 0x%02h (ACK ok); slave saw data=0x%02h",
                         d, a, slave.rx_data);
            wait (busy==0); @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("i2c.vcd"); $dumpvars(0, i2c_tb);
        rst=1; repeat(4) @(posedge clk); rst=0; @(posedge clk);

        do_write(7'h27, 8'hA5);
        do_write(7'h27, 8'h3C);
        do_write(7'h27, 8'hFF);

        if (errors==0) $display("ALL TESTS PASSED");
        else           $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule