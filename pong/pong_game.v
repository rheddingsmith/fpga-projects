// pong_game.v - Pong state: ball physics, paddle, score. Updates on frame_tick.
module pong_game (
    input             clk,
    input             rst,
    input             frame_tick,   // one pulse per frame
    input             btn_up,
    input             btn_dn,
    output reg [9:0]  ball_x,
    output reg [9:0]  ball_y,
    output reg [9:0]  paddle_y,
    output reg [7:0]  score
);
    localparam BALL=16, PADDLE_H=80, PADDLE_X=600,
               SPEED=2, PSPEED=4,
               SCRW=640, SCRH=480;

    reg dir_x, dir_y;   // 1 = moving in + direction (right / down)

    always @(posedge clk) begin
        if (rst) begin
            ball_x<=320; ball_y<=240; dir_x<=0; dir_y<=1;
            paddle_y<=200; score<=0;
        end else if (frame_tick) begin
            // --- move the ball ---
            ball_x <= dir_x ? ball_x + SPEED : ball_x - SPEED;
            ball_y <= dir_y ? ball_y + SPEED : ball_y - SPEED;

            // --- bounce off top / bottom walls ---
            if (ball_y <= SPEED)                 dir_y <= 1;   // hit top -> go down
            else if (ball_y >= SCRH-BALL-SPEED)  dir_y <= 0;   // hit bottom -> go up

            // --- bounce off left wall (single-player) ---
            if (ball_x <= SPEED)                 dir_x <= 1;   // -> go right

            // --- right side: paddle hit, or a miss ---
            if (ball_x >= PADDLE_X-BALL) begin
                if ((ball_y+BALL >= paddle_y) && (ball_y <= paddle_y+PADDLE_H))
                    dir_x <= 0;                                // hit paddle -> go left
                else if (ball_x >= SCRW-BALL) begin            // missed -> reset + score++
                    ball_x<=320; ball_y<=240; dir_x<=0;
                    score <= score + 1'b1;
                end
            end

            // --- move the paddle (clamped to screen) ---
            if (btn_up && paddle_y > PSPEED)
                paddle_y <= paddle_y - PSPEED;
            else if (btn_dn && paddle_y < SCRH-PADDLE_H-PSPEED)
                paddle_y <= paddle_y + PSPEED;
        end
    end
endmodule