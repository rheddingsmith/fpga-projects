`timescale 1ns/1ps
module adder_tb;
	localparam N = 64;

	reg [7:0] a, b;
	wire [8:0] sum;
	reg [8:0] mem [0:3*N-1];
	reg [8:0] expected;
	integer i, errors = 0;

	adder dut (.a(a), .b(b), .sum(sum));

	initial begin
		$readmemh("vectors.hex", mem);

		for (i=0; i<N; i = i + 1) begin
			a = mem[3*i + 0][7:0];
			b = mem[3*i + 1][7:0];
			expected = mem[3*i + 2];

			if (sum !== expected) begin
				$display("Fail [%0d]: %0d + %0d = %0d (expected %0d)", i, a, b, sum, expected);
				errors = errors + 1;
			end
		end

		if (errors == 0) $display("All %0d VECTORS PASSED", N);
		else $display("%0d FAILURE(S)", errors);
		$finish;
	end
endmodule
