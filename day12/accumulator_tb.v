`timescale 1ns/1ps
module accumulator_tb;
	reg clk, rst, en;
	reg [7:0] data_in;
	wire [7:0] acc;

	accumulator dut (.clk(clk), .rst(rst), .en(en), .data_in(data_in), .acc(acc));

	initial clk = 0;
	always #5 clk = ~clk;

	reg [7:0] model;
	integer errors = 0;

	task do_add (input [7:0] d);
		begin
			@(negedge clk);
			en = 1; data_in = d;
			@(negedge clk);
			en = 0;
			model = model + d;
		end
	endtask


	task check;
		begin
			if (acc != model) begin
				$display("FAIL @t=%0t: acc=%0d expected=%0d", $time, acc, model);
				errors = errors + 1;
			end else
				$display("ok @t=%0t: acc=%0d", $time, acc);
		end
	endtask

	initial begin
		$dumpfile("accumulator.vcd");
		$dumpvars(0, accumulator_tb);

		rst = 1; en = 0; data_in = 0; model = 0;
		@(negedge clk);
		@(negedge clk);
		rst = 0;

		do_add(8'd10); check;
		do_add(8'd5); check;
		do_add(8'd200); check;
		do_add(8'd100); check;

		if (errors == 0) $display("ALL CHECKS PASSED");
		else $display("%0d FAILURE(S)", errors);
		$finish;
	end
endmodule

