`timescale 1ns/1ps

module tb_axi4_lite_system;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst_n = 1'b0;
    reg start_write = 1'b0, start_read = 1'b0;
    reg [31:0] write_addr = 0, write_data = 0, read_addr = 0;
    reg [3:0] write_strb = 4'hF;
    wire [31:0] read_data_out;
    wire [1:0] last_bresp, last_rresp;
    wire done, busy;

    wire [31:0] awaddr, wdata, araddr;
    wire [3:0] wstrb;
    wire awvalid, wvalid, bready, arvalid, rready;
    wire awready, wready, bvalid, arready, rvalid;
    wire [1:0] bresp, rresp;
    wire [31:0] rdata;

    integer passed = 0;

    axi4_lite_master master (
        .clk(clk), .rst_n(rst_n), .start_write(start_write), .start_read(start_read),
        .write_addr(write_addr), .write_data(write_data), .write_strb(write_strb),
        .read_addr(read_addr), .read_data_out(read_data_out),
        .last_bresp(last_bresp), .last_rresp(last_rresp), .done(done), .busy(busy),
        .m_axi_awaddr(awaddr), .m_axi_awvalid(awvalid), .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
        .m_axi_araddr(araddr), .m_axi_arvalid(arvalid), .m_axi_arready(arready),
        .m_axi_rdata(rdata), .m_axi_rresp(rresp), .m_axi_rvalid(rvalid), .m_axi_rready(rready)
    );

    axi4_lite_slave slave (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );

    task do_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0] strb;
        input [1:0] expected_resp;
        integer timeout;
        begin
            @(negedge clk); write_addr=addr; write_data=data; write_strb=strb; start_write=1;
            @(negedge clk); start_write=0;
            timeout=0;
            while (!done && timeout < 100) begin @(negedge clk); timeout=timeout+1; end
            if (timeout >= 100) $fatal(1, "TIMEOUT waiting for write completion at address %h", addr);
            if (last_bresp !== expected_resp)
                $fatal(1, "WRITE RESP mismatch addr=%h expected=%b got=%b", addr, expected_resp, last_bresp);
            passed=passed+1;
            $display("PASS write addr=%h data=%h strobe=%b response=%b", addr, data, strb, last_bresp);
        end
    endtask

    task do_read;
        input [31:0] addr;
        input [31:0] expected_data;
        input [1:0] expected_resp;
        integer timeout;
        begin
            @(negedge clk); read_addr=addr; start_read=1;
            @(negedge clk); start_read=0;
            timeout=0;
            while (!done && timeout < 100) begin @(negedge clk); timeout=timeout+1; end
            if (timeout >= 100) $fatal(1, "TIMEOUT waiting for read completion at address %h", addr);
            if (last_rresp !== expected_resp)
                $fatal(1, "READ RESP mismatch addr=%h expected=%b got=%b", addr, expected_resp, last_rresp);
            if (expected_resp == 2'b00 && read_data_out !== expected_data)
                $fatal(1, "READ DATA mismatch addr=%h expected=%h got=%h", addr, expected_data, read_data_out);
            passed=passed+1;
            $display("PASS read  addr=%h data=%h response=%b", addr, read_data_out, last_rresp);
        end
    endtask

    initial begin
        $dumpfile("axi4_lite_system.vcd");
        $dumpvars(0, tb_axi4_lite_system);
        repeat (4) @(negedge clk); rst_n=1;
        repeat (2) @(negedge clk);

        do_write(32'h00000000, 32'h12345678, 4'b1111, 2'b00);
        do_read (32'h00000000, 32'h12345678, 2'b00);
        do_write(32'h00000000, 32'hAABBCCDD, 4'b0001, 2'b00);
        do_read (32'h00000000, 32'h123456DD, 2'b00);
        do_write(32'h00000004, 32'hCAFEBABE, 4'b1111, 2'b00);
        do_read (32'h00000004, 32'hCAFEBABE, 2'b00);
        do_write(32'h00000010, 32'hDEADBEEF, 4'b1111, 2'b10);
        do_read (32'h00000010, 32'h00000000, 2'b10);

        $display("\nALL TESTS PASSED: %0d checks", passed);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "GLOBAL TESTBENCH TIMEOUT");
    end
endmodule
