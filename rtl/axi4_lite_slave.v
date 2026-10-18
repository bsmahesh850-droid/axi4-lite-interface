module axi4_lite_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)(
    // Global System Signals
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,

    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire [2:0]                        S_AXI_AWPROT,
    input  wire                              S_AXI_AWVALID,
    output reg                               S_AXI_AWREADY,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output reg                               S_AXI_AWREADY, // Wait, watch naming: S_AXI_WREADY
    output reg                               S_AXI_WREADY,

    // Write Response Channel
    output reg  [1:0]                        S_AXI_BRESP,
    output reg                               S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,

    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire [2:0]                        S_AXI_ARPROT,
    input  wire                              S_AXI_ARVALID,
    output reg                               S_AXI_ARREADY,

    // Read Data Channel
    output reg  [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output reg  [1:0]                        S_AXI_RRESP,
    output reg                               S_AXI_RVALID,
    input  wire                              S_AXI_RREADY
);

    // Internal Register Map
    // 0x00: Control Register
    // 0x04: Status Register
    // 0x08: Data Input Register
    // 0x0C: Data Output Register (Data In * 2 computed)
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_control;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_status;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_in;
    wire [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;

    assign reg_data_out = reg_data_in << 1; // Simple hardware accelerator logic

    // Write State Machine Variables
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                          slv_reg_wren;

    // ------------------------------------------------
    // Write Handshake Logic
    // ------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= 2'b00;
            reg_control   <= 0;
            reg_data_in   <= 0;
            reg_status    <= 32'h00000001; // Ready status
        end else begin
            // Write Address Acceptance
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
                S_AXI_AWREADY <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end

            // Write Data Acceptance
            if (!S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID) begin
                S_AXI_WREADY <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
            end

            // Write Execution & Response Generation
            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                
                // Address Decoding & Register Write
                case (axi_awaddr[3:0])
                    4'h0: begin
                        reg_control <= S_AXI_WDATA;
                        S_AXI_BRESP <= 2'b00; // OKAY
                    end
                    4'h8: begin
                        reg_data_in <= S_AXI_WDATA;
                        S_AXI_BRESP <= 2'b00; // OKAY
                    end
                    default: begin
                        // Unmapped address -> Return DECERR (Decoder Error)
                        S_AXI_BRESP <= 2'b11; 
                    end
                endcase
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // ------------------------------------------------
    // Read Handshake Logic
    // ------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
            S_AXI_RRESP   <= 2'b00;
            S_AXI_RDATA   <= 0;
        end else begin
            // Read Address Acceptance
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
                S_AXI_ARADDR  <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end

            // Read Data Generation & Response
            if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                case (S_AXI_ARADDR[3:0])
                    4'h0: begin
                        S_AXI_RDATA <= reg_control;
                        S_AXI_RRESP <= 2'b00; // OKAY
                    end
                    4'h4: begin
                        S_AXI_RDATA <= reg_status;
                        S_AXI_RRESP <= 2'b00; // OKAY
                    end
                    4'h8: begin
                        S_AXI_RDATA <= reg_data_in;
                        S_AXI_RRESP <= 2'b00; // OKAY
                    end
                    4'hC: begin
                        S_AXI_RDATA <= reg_data_out;
                        S_AXI_RRESP <= 2'b00; // OKAY
                    end
                    default: begin
                        S_AXI_RDATA <= 32'hDEADBEEF;
                        S_AXI_RRESP <= 2'b11; // DECERR for invalid read address
                    end
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule
