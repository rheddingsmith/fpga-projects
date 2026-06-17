`timescale 1ns/1ps
module counter_tb;
	reg clk, rst, en;
	wire [3:0] count;

	counter dut (.clk(clk), .rst(rst), .en(en), .count(count));

	initial clk = 0;
	always #5 clk = ~clk;
	
	initial begin
		$dumpfile("counter.vcd");
		$dumpvars(0, counter_tb);

		rst = 1; en = 0;
		@(posedge clk);
		@(posedge clk);
		rst = 0; en = 1;

		repeat (20) @(posedge clk);

		$display("Final count = %0d", count);
		$finish;
	end

	always @(count) $display("t=%0t count=%0d", $time, count);
endmodule
