<CodeBlock language="verilog" editable>
`timescale 1ns/1ps
module axi_arbiter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] req,
    output reg  [2:0] grant,
    input  wire       bus_busy
);
localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    reg state;
always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant
