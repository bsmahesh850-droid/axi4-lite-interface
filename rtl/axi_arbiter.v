// =============================================================================
// 3-MASTER AXI4-LITE BUS ARBITER (BUS CONTROLLER)
// Decides which Master gets access when multiple requests arrive together.
// =============================================================================
module axi_arbiter (
    input  wire       clk,
    input  wire       rst_n,

    // Request lines from 3 Masters
    input  wire [2:0] req,        // req[0]=CPU (High), req[1]=DMA (Med), req[2]=Peripheral (Low)

    // Grant outputs (Hot-one encoding)
    output reg  [2:0] grant,      // grant[0]=1 means Master 0 gets the bus

    // Busy signal from Slave (indicates transaction in progress)
    input  wire       bus_busy
);

    localparam IDLE  = 1'b0;
    localparam BUSY  = 1 me;
    localparam BUSY  = 1'b1;
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 3'b000;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    // Priority Arbitration Logic (Fixed Priority: M0 > M1 > M2)
                    if (req[0]) begin
                        grant <= 3'b001; // Grant to Master 0
                        state <= BUSY;
                    end else if (req[1]) begin
                        grant <= 3'b010; // Grant to Master 1
                        state <= BUSY;
                    end else if (req[2]) begin
                        grant <= 3'b100; // Grant to Master 2
                        state <= BUSY;
                    end else begin
                        grant <= 3'b000;
                    end
                end

                BUSY: begin
                    // Hold grant until current transaction completes
                    if (!bus_busy) begin
                        grant <= 3'b000;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
