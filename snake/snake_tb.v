`timescale 1ns/1ps
module snake_logic_tb;
    localparam GW=40, GH=30, MAXLEN=64;
    reg clk=0, rst=1, frame_tick=0, step=0, bU=0,bD=0,bL=0,bR=0;
    wire [6:0] length; wire game_over;
    wire [5:0] food_x; wire [4:0] food_y;
    wire [MAXLEN*6-1:0] bx_flat; wire [MAXLEN*5-1:0] by_flat;
    integer i, errors=0;

    snake_logic #(.GW(GW),.GH(GH),.MAXLEN(MAXLEN)) dut(
        .clk(clk),.rst(rst),.frame_tick(frame_tick),.step(step),
        .bU(bU),.bD(bD),.bL(bL),.bR(bR),
        .length(length),.game_over(game_over),
        .food_x(food_x),.food_y(food_y),.bx_flat(bx_flat),.by_flat(by_flat));

    always #5 clk=~clk;
    wire [5:0] head_x = bx_flat[5:0];
    wire [4:0] head_y = by_flat[4:0];

    task one_step; begin @(posedge clk) step=1; @(posedge clk) step=0; end endtask
    task press_down; begin
        bD=1; @(posedge clk) frame_tick=1; @(posedge clk) frame_tick=0; bD=0;
    end endtask

    initial begin
        $dumpfile("snake.vcd"); $dumpvars(0, snake_logic_tb);
        rst=1; repeat(3) @(posedge clk); rst=0; @(posedge clk);

        if (length!==3) begin $display("FAIL init length=%0d",length); errors=errors+1; end

        one_step;
        if (head_x!==21) begin $display("FAIL head_x=%0d exp21",head_x); errors=errors+1; end
        one_step;
        if (head_x!==22) begin $display("FAIL head_x=%0d exp22",head_x); errors=errors+1; end

        press_down; one_step;
        if (head_y!==16) begin $display("FAIL head_y=%0d exp16",head_y); errors=errors+1; end

        // drive into the right wall -> game_over
        rst=1; repeat(2) @(posedge clk); rst=0; @(posedge clk);
        for (i=0;i<60 && !game_over;i=i+1) one_step;
        if (!game_over) begin $display("FAIL: no wall game_over"); errors=errors+1; end
        else $display("OK: wall collision -> game_over");

        if (errors==0) $display("ALL TESTS PASSED");
        else           $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule