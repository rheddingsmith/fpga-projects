`timescale 1ns/1ps
module vga_sync_tb;
    reg        clk = 0, rst = 1;
    wire       hsync, vsync, video_on, p_tick;
    wire [9:0] x, y;
    integer    errors = 0, ticks = 0;

    vga_sync dut (.clk(clk), .rst(rst), .hsync(hsync), .vsync(vsync),
                  .video_on(video_on), .pixel_x(x), .pixel_y(y), .p_tick(p_tick));

    always #5 clk = ~clk;   // 100 MHz

    // at every pixel tick, recompute expected timing from the exposed counters
    reg exp_hsync, exp_von;
    always @(posedge clk) if (!rst && p_tick) begin
        exp_hsync = ~((x >= 656) && (x < 752));   // 640+16=656, +96=752
        exp_von   = (x < 640) && (y < 480);
        if (hsync !== exp_hsync) begin
            $display("HSYNC mismatch @x=%0d: got %b exp %b", x, hsync, exp_hsync);
            errors = errors + 1;
        end
        if (video_on !== exp_von) begin
            $display("video_on mismatch @x=%0d y=%0d", x, y);
            errors = errors + 1;
        end
        ticks = ticks + 1;
        if (ticks == 2000) begin     // ~2.5 lines: enough to cross sync pulses
            if (errors == 0) $display("ALL TESTS PASSED (%0d pixels checked)", ticks);
            else             $display("%0d FAILURE(S)", errors);
            $finish;
        end
    end

    initial begin
        $dumpfile("vga.vcd"); $dumpvars(0, vga_sync_tb);
        rst = 1; repeat(4) @(posedge clk); rst = 0;
    end
endmodule