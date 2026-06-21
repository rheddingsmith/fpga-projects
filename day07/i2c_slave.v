// i2c_slave_model.v - behavioral I2C slave (corrected ACK timing)
module i2c_slave_model #(parameter [6:0] SLAVE_ADDR = 7'h27) (
    input wire scl,
    inout wire sda
);
    reg       active  = 1'b0;
    reg [3:0] edgecnt = 0;       // SCL rising edges within current byte
    reg [1:0] bytecnt = 0;       // 0 = address, 1 = data
    reg [7:0] shreg   = 0;
    reg       acking  = 1'b0;    // 1 = pull SDA low for ACK
    reg [7:0] rx_addr = 8'hxx, rx_data = 8'hxx;

    // single open-drain driver: low only while ACKing, else released
    assign sda = acking ? 1'b0 : 1'bz;

    // START = SDA falls while SCL high ; STOP = SDA rises while SCL high
    always @(negedge sda) if (scl===1'b1) begin
        active<=1; edgecnt<=0; bytecnt<=0; acking<=0;
    end
    always @(posedge sda) if (scl===1'b1) begin
        active<=0; acking<=0;
    end

    // sample the 8 data bits on rising edges
    always @(posedge scl) if (active) begin
        if (edgecnt < 4'd8) begin
            shreg   <= {shreg[6:0], (sda===1'b0)?1'b0:1'b1};
            edgecnt <= edgecnt + 1'b1;
        end
    end

    // ACK handling happens on FALLING edges:
    //   8th falling edge -> capture byte, start driving ACK low
    //   9th falling edge -> release ACK, advance to next byte
    always @(negedge scl) if (active) begin
        if (edgecnt == 4'd8 && !acking) begin
            if (bytecnt==2'd0) begin
                rx_addr <= shreg;
                acking  <= (shreg[7:1] == SLAVE_ADDR);   // ACK only if address matches
            end else begin
                rx_data <= shreg;
                acking  <= 1'b1;                          // always ACK data
            end
        end else if (acking) begin
            acking  <= 1'b0;        // release after the 9th clock
            edgecnt <= 0;
            bytecnt <= bytecnt + 1'b1;
        end
    end
endmodule