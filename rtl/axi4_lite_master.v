// -----------------------------------------------------------------------------
// File: rtl/axi4_lite_master.v
// Simple 32-bit AXI4-Lite Initiator Master
// -----------------------------------------------------------------------------
module axi4_lite_master (
    input  wire        clk,
    input  wire        rst_n,

    // Controls to start operations
    input  wire        start_write,
    input  wire        start_read,
    input  wire [31:0] write_addr,
    input  wire [31:0] write_data,
    input  wire [31:0] read_addr,
    output reg  [31:0] read_data_out,
    output reg         done,

    // Write Address Channel
    output reg  [31:0] m_axi_awaddr,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,

    // Write Data Channel
    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,

    // Write Response Channel
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,

    // Read Address Channel
    output reg  [31:0] m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,

    // Read Data Channel
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);

    // State Machine States
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_WRITE = 2'b01;
    localparam STATE_READ  = 2'b10;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_IDLE;
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid  <= 1'b0;
            m_axi_bready  <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_rready  <= 1'b0;
            m_axi_wstrb   <= 4'b1111;
            done          <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start_write) begin
                        state         <= STATE_WRITE;
                        m_axi_awaddr  <= write_addr;
                        m_axi_wdata   <= write_data;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wvalid  <= 1'b1;
                        m_axi_bready  <= 1'b1;
                    end else if (start_read) begin
                        state         <= STATE_READ;
                        m_axi_araddr  <= read_addr;
                        m_axi_arvalid <= 1'b1;
                        m_axi_rready  <= 1'b1;
                    end
                end

                STATE_WRITE: begin
                    if (m_axi_awready) m_axi_awvalid <= 1'b0;
                    if (m_axi_wready)  m_axi_wvalid  <= 1'b0;
                    
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        done         <= 1'b1;
                        state        <= STATE_IDLE;
                    end
                end

                STATE_READ: begin
                    if (m_axi_arready) m_axi_arvalid <= 1'b0;

                    if (m_axi_rvalid && m_axi_rready) begin
                        read_data_out <= m_axi_rdata;
                        m_axi_rready  <= 1'b0;
                        done          <= 1'b1;
                        state         <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
