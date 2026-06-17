// mux2_tb.v — testbench for mux2
`timescale 1ns/1ps
module mux2_tb;
    reg  a, b, sel;     // 'reg' holds values we drive from the testbench
    wire out;           // we observe the DUT's output here

    // instantiate the Device Under Test, connecting ports by name
    mux2 dut (.a(a), .b(b), .sel(sel), .out(out));

    integer errors = 0;
    task check(input exp);              // helper: compare actual vs expected
        if (out !== exp) begin
            $display("FAIL: a=%b b=%b sel=%b -> out=%b (expected %b)", a,b,sel,out,exp);
            errors = errors + 1;
        end
    endtask

    initial begin
        $dumpfile("mux2.vcd");          // record waveform for GTKWave
        $dumpvars(0, mux2_tb);

        a=0; b=1; sel=0; #1 check(0);   // sel=0 -> pick a (=0)
        a=0; b=1; sel=1; #1 check(1);   // sel=1 -> pick b (=1)
        a=1; b=0; sel=0; #1 check(1);   // sel=0 -> pick a (=1)
        a=1; b=0; sel=1; #1 check(0);   // sel=1 -> pick b (=0)

        if (errors==0) $display("ALL TESTS PASSED");
        else           $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule