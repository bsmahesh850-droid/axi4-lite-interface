module axi4_lite_master #(
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_M_AXI_ADDR_WIDTH = 4
)(
    input  wire                              M_AXI_ACLK,
    input  wire                              M_AXI_ARESETN,
    output reg                               M_AXI_START,

    // Write Address Channel
    output reg  [C_M_AXI_ADDR_WIDTH-1:0]     M_AXI_AWADDR,
    output reg                               M_AXI_AWVALID,
    input  wire                              M_AXI_AWREADY,

    // Write Data Channel
    output reg  [C_M_AXI_DATA_WIDTH-1:0]     M_AXI_WDATA,
    output reg  [(C_M_AXI_DATA_WIDTH/8)-1:0] M_AXI_WSTRB,
    output reg                               M_AXI_WVALID,
    input  wire                              M_AXI_WREADY,

    // Write Response Channel
    input  wire [1:0]                        M_AXI_BRESP,
    input  wire                              M_AXI_BVALID,
    output reg                               M_AXI_BREADY,

    // Read Address Channel
    output reg  [C_M_AXI_ADDR_WIDTH-1:0]     M_AXI_ARADDR,
    output reg                               M_AXI_ARVALID,
    input  wire                              M_AXI_ARREADY,

    // Read Data Channel
    input  wire [C_M_AXI_DATA_WIDTH-1:0]     M_AXI_RDATA,
    input  wire [1:0]                        M_AXI_RRESP,
    input  wire                              M_AXI_RVALID,
    output reg                               M_AXI_RREADY
);

    // Simple FSM for testing transactions
    localparam IDLE        = 3'd0;
    localparam WRITE_CMD   = 3'd1;
    localparam WRITE_RESP  = 3'd2;
    localparam READ_CMD    = 3'd3;
    localparam READ_RESP   = 3'd4;
    localparam DONE        = 3'd5;

    reg [2:0] state;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            state         <= IDLE;
            M_AXI_AWADDR  <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WDATA   <= 0;
            M_AXI_WSTRB   <= 4'hF;
            M_AXI_WVALID  <= 0;
            M_AXI_BREADY  <= 0;
            M_AXI_ARADDR  <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    M_AXI_BREADY <= 1'b1;
                    M_AXI_RREADY <= 1'b1;
                    state        <= WRITE_CMD;
                end

                WRITE_CMD: begin
                    M_AXI_AWADDR  <= 4'h8; // Write to Data In register
                    M_AXI_AWVALID <= 1'b1;
                    M_AXI_WDATA   <= 32'h00000015; // Value: 21 (Decimal)
                    M_AXI_WVALID  <= 1'b1;
                    
                    if (M_AXI_AWREADY && M_AXI_AWVALID && M_AXI_WREADY && M_AXI_WVALID) begin
                        M_AXI_AWVALID <= 1'b0;
                        M_AXI_WVALID  <= 1'b0;
                        state         <= WRITE_RESP;
                    end
                end

                WRITE_RESP: begin
                    if (M_AXI_BVALID) begin
                        state <= READ_CMD;
                    end
                end

                READ_CMD: begin
                    M_AXI_ARADDR  <= 4'hC; // Read from Data Out register (accelerator output)
                    M_AXI_ARVALID <= 1'b1;
                    if (M_AXI_ARREADY && M_AXI_ARVALID) begin
                        M_AXI_ARVALID <= 1'b0;
                        state         <= READ_RESP;
                    end
                end

                READ_RESP: begin
                    if (M_AXI_RVALID) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    state <= DONE; // Stay finished
                end
            end case
        end
    end

endmodule
