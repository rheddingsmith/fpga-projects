module snake_top (
	input wire clk, btnU, btnD, btnL, btnR, btnC,
	output wire Hsync, Vsync,
	output wire [3:0] vgaRed, vgaGreen, vgaBlue,
	output wire [7:0] led
);
	localparam GW=40, GH=30, MAXLEN=64, STEP_FRAMES=8;

	wire video_on, p_tick; wire [9:0] x,y;
	vga_sync u_vga(.clk(clk), .rst(btnC), .hsync(Hsync), .vsync(Vsync), .video_on(video_on), .pixel_x(x), .pixel_y(y), .p_tick(p_tick));

	wire frame_tick = p_tick && (x==10'd0) && (y==10'd481);

	reg[3:0] fdiv; reg step;
	always @(posedge clk) begin
		step <= 1'b0;
		if (btnC) fdiv <= 0;
		else if (frame_tick) begin
			if (fdiv==STEP_FRAMES-1) begin fdiv<=0; step<=1'b1; end
			else fdiv<=fdiv+1'b1;
		end
	end

	wire [6:0] length; wire game_over;
	wire [5:0] food_x; wire [4:0] food_y;
	wire [MAXLEN*6-1:0] bx_flat; wire [MAXLEN*5-1:0] by_flat;

	snake_logic #(.GW(GW), .GH(GH), .MAXLEN(MAXLEN)) u_game ( .clk(clk, .rst(btnC), .frame_tick(frame_tick, .step(step), .bU(btnU), .bD(btnD), .bL(btnL), .bR(btnR), .length(length), .game_over(game_over), .food_x(food_x), .food_y(food_y), .bx_flat(bx_flat,.by_flat(by_flat));

	wire [5:0] cx = x[9:4];
	wire [4:0] cy = y[9:4];

	integer j; reg snake_on;
	always @(*) begin
		snake_on = 1'b0;
		for (j=0; j<MAXLEN; j=j+1)
			if (j<length && bx_flat[j*6 +: 6]==cx && by_flat[j*5 +: 5]==cy)
				snake_on = 1'b1;
	end

	wire food_on = (cx==food_x) && (cy==food_y);
	reg [11:0] rgb;
	always @(*) begin
		if (!video_on) rgb = 12'h000;
		else if (game_over) rgb = 12'h400;
		else if (food_on) rgb = 12'hF00;
		else if (snake_on) rgb = 12'h0F0;
		else	rgb = 12'h001;
	end
	assign {vgaRed, vgaGren, vgaBlue} = rgb;
	assign led = length[7:0];
endmodule 
