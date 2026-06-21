// i2c_master.v - single-byte WRITE I2C master (no clock stretching)
// open-drain SCL/SDA; the testbench provides external pull-ups
module i2c_master #(
    parameter CLKS_PER_QUARTER = 25     // SCL period = 4*CLKS_PER_QUARTER clks
)(
    input            i_clk,
    input            i_rst,
    input            i_start,           // pulse: write i_data to slave i_addr
    input      [6:0] i_addr,
    input      [7:0] i_data,
    output reg       o_busy,
    output reg       o_done,            // 1-cycle pulse at end
    output reg       o_ack_error,       // 1 if a slave didn't ACK
    inout            io_scl,
    inout            io_sda
);
    // open-drain drivers: *_low=1 -> pull LOW ; *_low=0 -> release (pull-up -> HIGH)
    reg scl_low = 1'b0, sda_low = 1'b0;
    assign io_scl = scl_low ? 1'b0 : 1'bz;
    assign io_sda = sda_low ? 1'b0 : 1'bz;
    wire sda_in = io_sda;               // read the line (for ACK)

    // quarter-bit tick
    reg [15:0] qcount = 0; reg tick = 0;
    always @(posedge i_clk) begin
        if (qcount < CLKS_PER_QUARTER-1) begin qcount<=qcount+1; tick<=0; end
        else                            begin qcount<=0;        tick<=1; end
    end

    localparam IDLE=4'd0, START=4'd1, ADDR=4'd2, ADDR_ACK=4'd3,
               DATA=4'd4, DATA_ACK=4'd5, STOP=4'd6, DONE=4'd7;
    reg [3:0] state = IDLE;
    reg [1:0] phase = 0;                 // quarter within current bit (wraps 3->0)
    reg [3:0] bit_index;
    reg [7:0] shift, data_reg;

    always @(posedge i_clk) begin
        if (i_rst) begin
            state<=IDLE; scl_low<=0; sda_low<=0;
            o_busy<=0; o_done<=0; o_ack_error<=0; phase<=0;
        end else begin
            o_done <= 1'b0;
            if (state==IDLE) begin
                scl_low<=0; sda_low<=0; o_busy<=0; phase<=0;
                if (i_start) begin
                    o_busy<=1; o_ack_error<=0;
                    shift    <= {i_addr,1'b0};    // addr + R/W=0 (write)
                    data_reg <= i_data;
                    state    <= START;
                end
            end else if (tick) begin
                case (state)
                    START: begin                    // SDA falls while SCL high
                        case (phase)
                            0: begin sda_low<=0; scl_low<=0; end  // both released high
                            1: sda_low<=1;                        // SDA low, SCL high = START
                            2: scl_low<=1;                        // SCL low -> begin clocking
                            3: begin bit_index<=7; state<=ADDR; end
                        endcase
                        phase <= phase + 1;
                    end
                    ADDR: begin
                        case (phase)
                            0: begin scl_low<=1; sda_low<=~shift[7]; end // SCL low, drive bit
                            1: scl_low<=0;                                // SCL high (sample)
                            2: ;                                          // SCL high (hold)
                            3: begin
                                 scl_low<=1;
                                 shift <= {shift[6:0],1'b0};
                                 if (bit_index==0) state<=ADDR_ACK;
                                 else bit_index<=bit_index-1;
                               end
                        endcase
                        phase <= phase + 1;
                    end
                    ADDR_ACK: begin
                        case (phase)
                            0: begin scl_low<=1; sda_low<=0; end  // release SDA: slave drives ACK
                            1: scl_low<=0;
                            2: if (sda_in) o_ack_error<=1;        // low=ACK, high=NACK
                            3: begin scl_low<=1; bit_index<=7; shift<=data_reg; state<=DATA; end
                        endcase
                        phase <= phase + 1;
                    end
                    DATA: begin
                        case (phase)
                            0: begin scl_low<=1; sda_low<=~shift[7]; end
                            1: scl_low<=0;
                            2: ;
                            3: begin
                                 scl_low<=1;
                                 shift <= {shift[6:0],1'b0};
                                 if (bit_index==0) state<=DATA_ACK;
                                 else bit_index<=bit_index-1;
                               end
                        endcase
                        phase <= phase + 1;
                    end
                    DATA_ACK: begin
                        case (phase)
                            0: begin scl_low<=1; sda_low<=0; end
                            1: scl_low<=0;
                            2: if (sda_in) o_ack_error<=1;
                            3: begin scl_low<=1; state<=STOP; end
                        endcase
                        phase <= phase + 1;
                    end
                    STOP: begin                       // SDA rises while SCL high
                        case (phase)
                            0: begin scl_low<=1; sda_low<=1; end  // SCL low, SDA low
                            1: scl_low<=0;                        // SCL high (SDA still low)
                            2: sda_low<=0;                        // SDA released high = STOP
                            3: state<=DONE;
                        endcase
                        phase <= phase + 1;
                    end
                    DONE: begin o_done<=1; o_busy<=0; state<=IDLE; end
                endcase
            end
        end
    end
endmodule