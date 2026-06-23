// vga_top.v - VGA 8-bar color test pattern for Basys 3
module vga_top (
    input  wire       clk,        // 100 MHz, W5
    input  wire       btnC,       // center button = reset
    output wire       Hsync,
    output wire       Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);
    wire        video_on;
    wire [9:0]  x, y;

    vga_sync u_sync (
        .clk(clk), .rst(btnC),
        .hsync(Hsync), .vsync(Vsync),
        .video_on(video_on),
        .pixel_x(x), .pixel_y(y),
        .p_tick());                 // unused here

    // 8 vertical bars, 80 px each. {r,g,b} packs the three 4-bit channels.
    reg [11:0] rgb;
    always @(*) begin
        if (!video_on)      rgb = 12'h000;   // blanking -> black (required!)
        else if (x < 80)    rgb = 12'hF00;   // red
        else if (x < 160)   rgb = 12'h0F0;   // green
        else if (x < 240)   rgb = 12'h00F;   // blue
        else if (x < 320)   rgb = 12'hFF0;   // yellow
        else if (x < 400)   rgb = 12'h0FF;   // cyan
        else if (x < 480)   rgb = 12'hF0F;   // magenta
        else if (x < 560)   rgb = 12'hFFF;   // white
        else                rgb = 12'h000;   // black
    end

    assign {vgaRed, vgaGreen, vgaBlue} = rgb;
endmodule