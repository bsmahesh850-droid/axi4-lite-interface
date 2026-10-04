// =============================================================================
// ENHANCED AXI4-LITE SLAVE (Supports WSTRB & SLVERR)
// =============================================================================
module axi4_lite_slave (
    input  wire        clk,
    input  wire        rst_n,

    // Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,     // Byte strobes
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // Write Response Channel
    output reg  [1:0]  s_axi_bresp,     // 2'b00 = OKAY, 2'b10 = SLVERR
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,     // 2'b00 = OKAY, 2'b10 = SLVERR
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    reg [31:0] reg_bank [0:3];
    reg [31:0] latched_awaddr;
    reg [31:0] latched_araddr;
    integer i;

    // --- ENHANCED WRITE LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            reg_bank[0]   <= 32'h0;
            reg_bank[1]   <= 32'h0;
            reg_bank[2]   <= 32'h0;
            reg_bank[3]   <= 32'h0;
        end else begin
            // Address Handshake & Error Check
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready  <= 1'b1;
                latched_awaddr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Byte Strobe Masking Execution
            if (~s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b1;
                
                // Out of range check (Only addresses 0x0 to 0xC are valid)
                if (latched_awaddr > 32'h0000_000C) begin
                    s_axi_bresp <= 2'b10; // SLVERR (Slave Error)
                end else begin
                    s_axi_bresp <= 2'b00; // OKAY
                    // Respect s_axi_wstrb bitmask (1 bit per byte)
                    case (latched_awaddr[3:2])
                        2'b00: for (i=0; i<4; i=i+1) if (s_axi_wstrb[i]) reg_bank[0][(i*8)+:8] <= s_axi_wdata[(i*8)+:8];
                        2'b01: for (i=0; i<4; i=i+1) if (s_axi_wstrb[i]) reg_bank[1][(i*8)+:8] <= s_axi_wdata[(i*8)+:8];
                        2'b10: for (i=0; i<4; i=i+1) if (s_axi_wstrb[i]) reg_bank[2][(i*8)+:8] <= s_axi_wdata[(i*8)+:8];
                        2'b11: for (i=0; i<4; i=i+1) if (s_axi_wstrb[i]) reg_bank[3][(i*8)+:8] <= s_axi_wdata[(i*8)+:8];
                    endcase
                end
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Response Handshake
            if (s_axi_awready && s_axi_wready && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // --- ENHANCED READ LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready  <= 1'b1;
                latched_araddr <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                
                // Out of range check
                if (latched_araddr > 32'h0000_000C) begin
                    s_axi_rresp <= 2'b10; // SLVERR (Slave Error)
                    s_axi_rdata <= 32'hDEAD_BEEF;
                end else begin
                    s_axi_rresp <= 2'b00; // OKAY
                    case (latched_araddr[3:2])
                        2 me: s_axi_rdata <= reg_bank[0];
                        2'b00: s_axi_rdata <= reg_bank[0];
                        2'b01: s_axi_rdata <= reg_bank[1];
                        2'b10: s_axi_rdata <= reg_bank[2];
                        2'b11: s_axi_rdata <= reg_bank[3];
                    endcase
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
