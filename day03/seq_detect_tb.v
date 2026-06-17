`timescale 1ns/1ps
module seq_detect_tb;
	reg clk, rst, din;
	wire detected;

	seq_detect dut (.clk(clk), .rst(rst), .din(din), .detected(detected));

	initial clk = 0;
	always #5 clk = ~clk;

	task send(input b);
		begin
			din = b;
			@(posedge clk);
			#1;
		end
	endtask

	integer count = 0;
	always @(posedge clk) if (detected) begin
		count = count + 1;
		$display("t=%0t DETECTED #%0d", $time, count);
	end

	initial begin
		$dumpfile("seq_detect.vcd");
		$dumpvars(0, seq_detect_tb);

		rst = 1; din = 0; @(posedge clk); #1;
		rst = 0;

		send(1); send(0); send(1); send(1);
		send(0);
		send(1); send(1);
		send(1); send(0); send(1); send(1);

		repeat (2) @(posedge clk);
		$display("Total detections = %0d (expected 3)", count);
		$finish;
	end
endmodule
