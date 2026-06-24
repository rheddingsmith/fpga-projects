`timescale 1ns/1ps
module pong_game_tb;
    reg        clk=0, rst=1, frame_tick=0, btn_up=0, btn_dn=0;
    wire [9:0] ball_x, ball_y, paddle_y; wire [7:0] score;
    integer    i, errors=0;

    pong_game dut(.clk(clk), .rst(rst), .frame_tick(frame_tick),
                  .btn_up(btn_up), .btn_dn(btn_dn),
                  .ball_x(ball_x), .ball_y(ball_y),
                  .paddle_y(paddle_y), .score(score));

    always #5 clk = ~clk;

    task frame; begin
        @(posedge clk); frame_tick=1;
        @(posedge clk); frame_tick=0;
        if (ball_x > 700 || ball_y > 500) begin   // never far off-screen
            $display("OUT OF BOUNDS: ball=(%0d,%0d)", ball_x, ball_y);
            errors=errors+1;
        end
    end endtask

    initial begin
        $dumpfile("pong.vcd"); $dumpvars(0, pong_game_tb);
        rst=1; repeat(3) @(posedge clk); rst=0;
        for (i=0;i<3000;i=i+1) frame;             // ~50 seconds of gameplay
        $display("Simulated 3000 frames; misses=%0d, errors=%0d", score, errors);
        if (errors==0) $display("ALL TESTS PASSED");
        else           $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule