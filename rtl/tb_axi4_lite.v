// -----------------------------------------------------------------------------
// File: tb/tb_axi4_lite.v
// Self-Checking Testbench connecting Master and Slave
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_axi4_lite;

    reg clk;
    reg rst_n;

    // Master Trigger Signals
    reg        start_write;
    reg        start_read;
    reg [31:0] write_addr;
    reg [31:0] write_data;
    reg [31:0] read_addr;
    wire [31:0] read_data_out;
    wire        done;

    // AXI Interconnect Wires
    wire [31:0] awaddr;
    wire        awvalid, awready;
    wire [31:0] wdata;
    wire [3:0]  wstrb;
    wire        wvalid, wready;
    wire [1:0]  bresp;
    wire        bvalid, bready;
    wire [31:0] araddr;
    wire        arvalid, arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid, rready;

    // 1. Instantiate Master
    axi4_lite_master u_master (
        .clk(clk), .rst_n(rst_n),
        .start_write(start_write), .start_read(start_read),
        .write_addr(write_addr), .write_data(write_data),
        .read_addr(read_addr), .read_data_out(read_data_out), .done(done),
        .m_axi_awaddr(awaddr), .m_axi_awvalid(awvalid), .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
        .m_axi_araddr(araddr), .m_axi_arvalid(arvalid), .m_axi_arready(arready),
        .m_axi_rdata(rdata), .m_axi_rresp(rresp), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
    );

    // 2. Instantiate Slave
    axi4_lite_slave u_slave (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Simulation Sequence
    initial begin
        // Setup GTKWave dump file
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_axi4_lite);

        // Initial Values
        clk = 0;
        rst_n = 0;
        start_write = 0;
        start_read  = 0;

        // Apply Reset
        #20 rst_n = 1;
        #10;

        // --- TEST 1: WRITE DATA (0x12345678 to Address 0x0) ---
        $display("[TB] Starting WRITE operation...");
        write_addr  = 32'h0000_0000;
        write_data  = 32'h1234_5678;
        start_write = 1'b1;
        #10 start_write = 1'b0;

        // Wait until transaction completes
        wait(done);
        $display("[TB] WRITE finished!");
        #20;

        // --- TEST 2: READ DATA BACK (From Address 0x0) ---
        $display("[TB] Starting READ operation...");
        read_addr  = 32'h0000_0000;
        start_read = 1'b1;
        #10 start_read = 1'b0;

        // Wait until read completes
        wait(done);
        $display("[TB] READ finished! Received Data = 0x%h", read_data_out);

        // Check result
        if (read_data_out === 32'h1234_5678) begin
            $display("[TB] SUCCESS: Read data matches written data!");
        end else begin
            $display("[TB] ERROR: Mismatch detected!");
        end

        #50;
        $finish;
    end

endmodule
