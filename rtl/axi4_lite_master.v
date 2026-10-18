`timescale 1ns/1ps

// Educational AXI4-Lite master: one outstanding transaction at a time.
// AW and W are launched together but accepted independently, as AXI requires.
module axi4_lite_master (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_write,
    input  wire        start_read,
    input  wire [31:0] write_addr,
    input  wire [31:0] write_data,
    input  wire [3:0]  write_strb,
    input  wire [31:0] read_addr,
    output reg  [31:0] read_data_out,
    output reg  [1:0]  last_bresp,
    output reg  [1:0]  last_rresp,
    output reg         done,
    output wire        busy,

    output reg  [31:0] m_axi_awaddr,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,

    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,

    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,

    output reg  [31:0] m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,

    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);
    localparam [2:0] ST_IDLE      = 3'd0,
                     ST_WRITE     = 3'd1,
                     ST_WRITE_RESP= 3'd2,
                     ST_READ_ADDR = 3'd3,
                     ST_READ_DATA = 3'd4;

    reg [2:0] state;
    assign busy = (state != ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            read_data_out <= 32'b0;
            last_bresp <= 2'b00;
            last_rresp <= 2'b00;
            done <= 1'b0;
            m_axi_awaddr <= 32'b0; m_axi_awvalid <= 1'b0;
            m_axi_wdata <= 32'b0; m_axi_wstrb <= 4'b0; m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            m_axi_araddr <= 32'b0; m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
        end else begin
            done <= 1'b0; // one-cycle completion pulse
            case (state)
                ST_IDLE: begin
                    m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
                    m_axi_bready <= 1'b0; m_axi_arvalid <= 1'b0; m_axi_rready <= 1'b0;
                    // Write has priority if both start inputs are asserted together.
                    if (start_write) begin
                        m_axi_awaddr <= write_addr;
                        m_axi_wdata <= write_data;
                        m_axi_wstrb <= write_strb;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wvalid <= 1'b1;
                        state <= ST_WRITE;
                    end else if (start_read) begin
                        m_axi_araddr <= read_addr;
                        m_axi_arvalid <= 1'b1;
                        state <= ST_READ_ADDR;
                    end
                end
                ST_WRITE: begin
                    if (m_axi_awvalid && m_axi_awready)
                        m_axi_awvalid <= 1'b0;
                    if (m_axi_wvalid && m_axi_wready)
                        m_axi_wvalid <= 1'b0;
                    // Each channel may handshake on a different clock edge.
                    if ((!m_axi_awvalid || m_axi_awready) &&
                        (!m_axi_wvalid  || m_axi_wready)) begin
                        m_axi_bready <= 1'b1;
                        state <= ST_WRITE_RESP;
                    end
                end
                ST_WRITE_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        last_bresp <= m_axi_bresp;
                        m_axi_bready <= 1'b0;
                        done <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
                ST_READ_ADDR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready <= 1'b1;
                        state <= ST_READ_DATA;
                    end
                end
                ST_READ_DATA: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        read_data_out <= m_axi_rdata;
                        last_rresp <= m_axi_rresp;
                        m_axi_rready <= 1'b0;
                        done <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
                default: begin
                    state <= ST_IDLE;
                    m_axi_awvalid <= 1'b0; m_axi_wvalid <= 1'b0;
                    m_axi_bready <= 1'b0; m_axi_arvalid <= 1'b0; m_axi_rready <= 1'b0;
                end
            endcase
        end
    end
endmodule
