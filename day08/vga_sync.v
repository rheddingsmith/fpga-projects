module vga_sync(
    input wire clk,
    input wire rst,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,
    output wire p_tick
);

    localparam H_DISPLAY=640, H_FP=16, H_SYNC=96, H_BP=48, H_TOTAL=800;
    localparam V_DISPLAY=480, V_FP=10, V_SYNC=2, V_BP=33, V_TOTAL=525;

    reg[1:0] clk_div=0;
    always @(posedge clk) clk_div <= clk_div + 1'b1;
    wire tick = (clk_div == 2'b11);

    reg [9:0] h_count = 0, v_count = 0;
    always @(posedge clk) begin
        if(rst) begin
            h_count <=0; v_count <= 0;
        end else if (tick) begin
            if(h_count == H_TOTAL-1) begin
                h_count <= 0;
                if (v_count == V_TOTAL-1) v_count <=0;
                else    v_count <= v_count + 1'b1;
            end else
                h_count <= h_count + 1'b1;
            end
        end

    assign hsync    = ~((h_count >= H_DISPLAY+H_FP) && (h_count < H_DISPLAY+H_FP+H_SYNC));
    assign vsync    = ~((v_count >= V_DISPLAY+V_FP) && (v_count < V_DISPLAY+V_FP+V_SYNC));
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    assign pixel_x  = h_count;
    assign pixel_y  = v_count;
    assign p_tick   = tick;
endmodule

