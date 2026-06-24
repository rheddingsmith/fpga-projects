// pong_top.v - FPGA Pong on Basys 3
module pong_top (
    input  wire       clk,        // 100 MHz, W5
    input  wire       btnU,       // paddle up
    input  wire       btnD,       // paddle down
    input  wire       btnC,       // reset
    output wire       Hsync,
    output wire       Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire [7:0] led         // score
);
    localparam PADDLE_X=600, PADDLE_W=8, PADDLE_H=80, BALL=16;

    wire        video_on, p_tick;
    wire [9:0]  x, y;
    wire [9:0]  ball_x, ball_y, paddle_y;
    wire [7:0]  score;

    vga_sync u_vga (
        .clk(clk), .rst(btnC),
        .hsync(Hsync), .vsync(Vsync),
        .video_on(video_on), .pixel_x(x), .pixel_y(y), .p_tick(p_tick));

    // one update pulse per frame, during vertical blanking (no tearing)
    wire frame_tick = p_tick && (x==10'd0) && (y==10'd481);

    pong_game u_game (
        .clk(clk), .rst(btnC), .frame_tick(frame_tick),
        .btn_up(btnU), .btn_dn(btnD),
        .ball_x(ball_x), .ball_y(ball_y), .paddle_y(paddle_y), .score(score));

    // --- rendering: is the current pixel inside an object? ---
    wire ball_on   = (x>=ball_x)   && (x<ball_x+BALL) &&
                     (y>=ball_y)   && (y<ball_y+BALL);
    wire paddle_on = (x>=PADDLE_X) && (x<PADDLE_X+PADDLE_W) &&
                     (y>=paddle_y) && (y<paddle_y+PADDLE_H);

    reg [11:0] rgb;
    always @(*) begin
        if (!video_on)      rgb = 12'h000;   // blanking -> black
        else if (paddle_on) rgb = 12'hFFF;   // white paddle
        else if (ball_on)   rgb = 12'h0F0;   // green ball
        else                rgb = 12'h001;   // dark background
    end
    assign {vgaRed, vgaGreen, vgaBlue} = rgb;
    assign led = score;
endmodule