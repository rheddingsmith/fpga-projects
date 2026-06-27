// snake_logic.v - Snake game state: body array, movement, growth, collisions
module snake_logic #(
    parameter GW=40, GH=30, MAXLEN=64
)(
    input  wire        clk, rst,
    input  wire        frame_tick,    // once per frame (sample direction)
    input  wire        step,          // once per game step (move the snake)
    input  wire        bU, bD, bL, bR,
    output reg  [6:0]  length,
    output reg         game_over,
    output reg  [5:0]  food_x,
    output reg  [4:0]  food_y,
    output wire [MAXLEN*6-1:0] bx_flat,   // body cell-x's, packed for rendering
    output wire [MAXLEN*5-1:0] by_flat    // body cell-y's
);
    localparam UP=2'd0, DOWN=2'd1, LEFT=2'd2, RIGHT=2'd3;

    reg [5:0] body_x [0:MAXLEN-1];   // cell x of each segment (0..39)
    reg [4:0] body_y [0:MAXLEN-1];   // cell y of each segment (0..29)
    reg [1:0] dir;
    reg [15:0] lfsr;
    integer i, k, j;

    // pack the body arrays into flat buses so the top module can render them
    genvar gi;
    generate for (gi=0; gi<MAXLEN; gi=gi+1) begin: FLAT
        assign bx_flat[gi*6 +: 6] = body_x[gi];
        assign by_flat[gi*5 +: 5] = body_y[gi];
    end endgenerate

    // head, next head, and collision flags (combinational)
    wire [5:0] hx = body_x[0];
    wire [4:0] hy = body_y[0];
    wire wall_hit = (dir==UP    && hy==0)     ||
                    (dir==DOWN  && hy==GH-1)  ||
                    (dir==LEFT  && hx==0)     ||
                    (dir==RIGHT && hx==GW-1);
    wire [5:0] nhx = (dir==LEFT)? hx-1 : (dir==RIGHT)? hx+1 : hx;
    wire [4:0] nhy = (dir==UP)?   hy-1 : (dir==DOWN)?  hy+1 : hy;

    reg self_hit;
    always @(*) begin
        self_hit = 1'b0;
        for (j=1; j<MAXLEN; j=j+1)                 // skip head (j=0)
            if (j < length && body_x[j]==nhx && body_y[j]==nhy) self_hit = 1'b1;
    end

    // pseudo-random food location from a free-running LFSR, clamped to the grid
    wire [5:0] fx_raw = lfsr[5:0];
    wire [4:0] fy_raw = lfsr[10:6];
    wire [5:0] new_fx = (fx_raw >= GW) ? fx_raw - GW : fx_raw;
    wire [4:0] new_fy = (fy_raw >= GH) ? fy_raw - GH : fy_raw;
    always @(posedge clk)
        lfsr <= rst ? 16'hACE1 : {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};

    always @(posedge clk) begin
        if (rst) begin
            length<=3; dir<=RIGHT; game_over<=0;
            body_x[0]<=20; body_y[0]<=15;          // a 3-cell snake, mid-screen
            body_x[1]<=19; body_y[1]<=15;
            body_x[2]<=18; body_y[2]<=15;
            for (i=3;i<MAXLEN;i=i+1) begin body_x[i]<=6'd63; body_y[i]<=5'd31; end // off-grid
            food_x<=30; food_y<=8;
        end else begin
            if (frame_tick) begin                  // sample buttons (no reversing)
                if      (bU && dir!=DOWN)  dir<=UP;
                else if (bD && dir!=UP)    dir<=DOWN;
                else if (bL && dir!=RIGHT) dir<=LEFT;
                else if (bR && dir!=LEFT)  dir<=RIGHT;
            end
            if (step && !game_over) begin
                if (wall_hit || self_hit)
                    game_over <= 1'b1;
                else begin
                    for (k=MAXLEN-1;k>0;k=k-1) begin   // shift body back one
                        body_x[k]<=body_x[k-1];
                        body_y[k]<=body_y[k-1];
                    end
                    body_x[0]<=nhx;  body_y[0]<=nhy;   // head to new cell
                    if (nhx==food_x && nhy==food_y) begin
                        if (length<MAXLEN) length<=length+1'b1;   // grow
                        food_x<=new_fx; food_y<=new_fy;           // respawn food
                    end
                end
            end
        end
    end
endmodule