`timescale 1ns/1ps

// Small memory-mapped AXI4-Lite slave with four 32-bit registers.
// Supported byte strobes; one outstanding write and one outstanding read maximum.
module axi4_lite_slave (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);
    localparam [1:0] RESP_OKAY = 2'b00, RESP_SLVERR = 2'b10;

    reg [31:0] reg0, reg1, reg2, reg3;
    reg [31:0] awaddr_hold, wdata_hold;
    reg [3:0]  wstrb_hold;
    reg        have_aw, have_w;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;
    wire ar_fire = s_axi_arvalid && s_axi_arready;

    // Four word-aligned addresses: 0x00, 0x04, 0x08, 0x0C.
    function address_valid;
        input [31:0] addr;
        begin
            address_valid = (addr[31:4] == 28'd0) && (addr[1:0] == 2'b00);
        end
    endfunction

    function [31:0] read_word;
        input [31:0] addr;
        begin
            case (addr[3:2])
                2'b00: read_word = reg0;
                2'b01: read_word = reg1;
                2'b10: read_word = reg2;
                2'b11: read_word = reg3;
                default: read_word = 32'b0;
            endcase
        end
    endfunction

    assign s_axi_awready = !have_aw && !s_axi_bvalid;
    assign s_axi_wready  = !have_w  && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    task apply_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            case (addr[3:2])
                2'b00: begin
                    if (strb[0]) reg0[7:0]   <= data[7:0];
                    if (strb[1]) reg0[15:8]  <= data[15:8];
                    if (strb[2]) reg0[23:16] <= data[23:16];
                    if (strb[3]) reg0[31:24] <= data[31:24];
                end
                2'b01: begin
                    if (strb[0]) reg1[7:0]   <= data[7:0];
                    if (strb[1]) reg1[15:8]  <= data[15:8];
                    if (strb[2]) reg1[23:16] <= data[23:16];
                    if (strb[3]) reg1[31:24] <= data[31:24];
                end
                2'b10: begin
                    if (strb[0]) reg2[7:0]   <= data[7:0];
                    if (strb[1]) reg2[15:8]  <= data[15:8];
                    if (strb[2]) reg2[23:16] <= data[23:16];
                    if (strb[3]) reg2[31:24] <= data[31:24];
                end
                2'b11: begin
                    if (strb[0]) reg3[7:0]   <= data[7:0];
                    if (strb[1]) reg3[15:8]  <= data[15:8];
                    if (strb[2]) reg3[23:16] <= data[23:16];
                    if (strb[3]) reg3[31:24] <= data[31:24];
                end
            endcase
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg0 <= 32'b0; reg1 <= 32'b0; reg2 <= 32'b0; reg3 <= 32'b0;
            awaddr_hold <= 32'b0; wdata_hold <= 32'b0; wstrb_hold <= 4'b0;
            have_aw <= 1'b0; have_w <= 1'b0;
            s_axi_bresp <= RESP_OKAY; s_axi_bvalid <= 1'b0;
            s_axi_rdata <= 32'b0; s_axi_rresp <= RESP_OKAY; s_axi_rvalid <= 1'b0;
        end else begin
            if (aw_fire) begin awaddr_hold <= s_axi_awaddr; have_aw <= 1'b1; end
            if (w_fire) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                have_w <= 1'b1;
            end

            // Commit a write only after both independent channels have arrived.
            if (have_aw && have_w && !s_axi_bvalid) begin
                if (address_valid(awaddr_hold)) begin
                    apply_write(awaddr_hold, wdata_hold, wstrb_hold);
                    s_axi_bresp <= RESP_OKAY;
                end else begin
                    s_axi_bresp <= RESP_SLVERR;
                end
                have_aw <= 1'b0;
                have_w <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (ar_fire) begin
                if (address_valid(s_axi_araddr)) begin
                    s_axi_rdata <= read_word(s_axi_araddr);
                    s_axi_rresp <= RESP_OKAY;
                end else begin
                    s_axi_rdata <= 32'b0;
                    s_axi_rresp <= RESP_SLVERR;
                end
                s_axi_rvalid <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end
endmodule
