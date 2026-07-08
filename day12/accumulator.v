module accumulator (
	input clk, rst, en,
	input [7:0] data_in,
	output reg [7:0] acc
);
	always @(posedge clk) begin
		if(rst) acc <= 8'd0;
		else if (en) acc <= acc + data_in;
	end
endmodule

