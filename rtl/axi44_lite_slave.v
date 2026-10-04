// -----------------------------------------------------------------------------
// File: rtl/axi4_lite_slave.v
// Simple 32-bit AXI4-Lite Register Slave
// -----------------------------------------------------------------------------
module axi4_lite_slave (
    input  wire        clk,
    input  wire        rst_n,

    // Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // 4 internal registers (32 bits each)
    reg [31:0] reg_bank [0:3];
    reg [31:0] latched_awaddr;
    reg [31:0] latched_araddr;

    // --- WRITE LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00; // OKAY status
            reg_bank[0]   <= 32'h00000000;
            reg_bank[1]   <= 32'h00000000;
            reg_bank[2]   <= 32'h00000000;
            reg_bank[3]   <= 32'h00000000;
        end else begin
            // Handshake for Write Address
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready  <= 1'b1;
                latched_awaddr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Handshake for Write Data & Store into Register Bank
            if (~s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b1;
                case (latched_awaddr[3:2])
                    2'b00: reg_bank[0] <= s_axi_wdata;
                    2'b01: reg_bank[1] <= s_axi_wdata;
                    2'b10: reg_bank[2] <= s_axi_wdata;
                    2'b11: reg_bank[3] <= s_axi_wdata;
                endcase
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Generate Write Response
            if (s_axi_awready && s_axi_wready && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // --- READ LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00; // OKAY status
            s_axi_rdata   <= 32'h0;
        end else begin
            // Handshake for Read Address
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready  <= 1'b1;
                latched_araddr <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Handshake for Read Data & Fetch from Register Bank
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case (latched_araddr[3:2])
                    2'b00: s_axi_rdata <= reg_bank[0];
                    2'b01: s_axi_rdata <= reg_bank[1];
                    2'b10: s_axi_rdata <= reg_bank[2];
                    2'b11: s_axi_rdata <= reg_bank[3];
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
