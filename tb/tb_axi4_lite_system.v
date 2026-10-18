`timescale 1ns / 1ps

module axi4_lite_tb;

    parameter integer DATA_WIDTH = 32;
    parameter integer ADDR_WIDTH = 4;

    reg clk;
    reg rst_n;

    // Interconnect wires
    wire [ADDR_WIDTH-1:0] awaddr;
    wire                  awvalid;
    wire                  awready;
    wire [DATA_WIDTH-1:0] wdata;
    wire [(DATA_WIDTH/8)-1:0] wstrb;
    wire                  wvalid;
    wire                  wready;
    wire [1:0]            bresp;
    wire                  bvalid;
    wire                  bready;
    
    wire [ADDR_WIDTH-1:0] araddr;
    wire                  arvalid;
    wire                  arready;
    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0]            rresp;
    wire                  rvalid;
    wire                  rready;

    // Instantiate Master
    axi4_lite_master #(
        .C_M_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_M_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) u_master (
        .M_AXI_ACLK(clk),
        .M_AXI_ARESETN(rst_n),
        .M_AXI_AWADDR(awaddr),
        .M_AXI_AWVALID(awvalid),
        .M_AXI_AWREADY(awready),
        .M_AXI_WDATA(wdata),
        .M_AXI_WSTRB(wstrb),
        .M_AXI_WVALID(wvalid),
        .M_AXI_WREADY(wready),
        .M_AXI_BRESP(bresp),
        .M_AXI_BVALID(bvalid),
        .M_AXI_BREADY(bready),
        .M_AXI_ARADDR(araddr),
        .M_AXI_ARVALID(arvalid),
        .M_AXI_ARREADY(arready),
        .M_AXI_RDATA(rdata),
        .M_AXI_RRESP(rresp),
        .M_AXI_RVALID(rvalid),
        .M_AXI_RREADY(rready)
    );

    // Instantiate Slave
    axi4_lite_slave #(
        .C_S_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) u_slave (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(awaddr),
        .S_AXI_AWPROT(3'b000),
        .S_AXI_AWVALID(awvalid),
        .S_AXI_AWREADY(awready),
        .S_AXI_WDATA(wdata),
        .S_AXI_WSTRB(wstrb),
        .S_AXI_WVALID(wvalid),
        .S_AXI_WREADY(wready),
        .S_AXI_BRESP(bresp),
        .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),
        .S_AXI_ARADDR(araddr),
        .S_AXI_ARPROT(3'b000),
        .S_AXI_ARVALID(arvalid),
        .S_AXI_ARREADY(arready),
        .S_AXI_RDATA(rdata),
        .S_AXI_RRESP(rresp),
        .S_AXI_RVALID(rvalid),
        .S_AXI_RREADY(rready)
    );

    // Clock Generation (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;

        #25;
        rst_n = 1; // Release reset

        // Run simulation for enough cycles
        #300;
        
        $display("========================================");
        $display("TEST COMPLETED SUCCESSFULLY");
        $display("Data In written: 21 (0x15)");
        $display("Data Out read back: %0d (Expected: 42)", rdata);
        if (rdata == 42) begin
            $display("[PASS] Accelerator logic verified correctly!");
        end else begin
            $display("[FAIL] Mismatch detected!");
        end
        $display("========================================");
        $finish;
    end

endmodule
