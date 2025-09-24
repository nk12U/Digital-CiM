`timescale 1ps/1ps

module simtop;
    // set DUT parameters as local parameter
    localparam CORE_NUM = 16;
    localparam XIN_BIT_WIDTH = 11;
    localparam MEM_BIT_WIDTH = 8;
    localparam CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1; // 18
    localparam MEM_ADR_WIDTH = 2;
    localparam OUTPUT_BIT_WIDTH = CORE_DOUT_BIT_WIDTH + $clog2(CORE_NUM); // 22

    localparam NUM_RAMDOM_ITERATIONS = 10;

    parameter clk_peri = 10_000; // 100MHz, clock period

    // expected value
    parameter [OUTPUT_BIT_WIDTH-1:0] EXPECTED_Q_VALUE = 22'h009eb0;
    reg clk;
    reg nrst;
    reg encb;
    reg web;
    reg [$clog2(CORE_NUM)-1:0] banka;
    reg [MEM_ADR_WIDTH-1:0] adra;
    reg [MEM_BIT_WIDTH-1:0] d;
    reg reb;
    reg [$clog2(CORE_NUM)-1:0] bankb;
    reg [MEM_ADR_WIDTH-1:0] adrb;
    reg [(CORE_NUM*XIN_BIT_WIDTH)-1:0] xin;
    wire [OUTPUT_BIT_WIDTH-1:0] q;

    // Generate Clock
    initial begin
        #0 clk = 1'b0;
        forever begin
            #(clk_peri/2) clk = ~clk;
        end
    end

    // Generate FSDB file
    initial begin
        #0;
        $fsdbDumpfile ("verilog.fsdb");
        $fsdbDumpvars (0, simtop);
        $fsdbDumpvars ("+all");
        $fsdbDumpSVA;
    end

    // Test vector coding
    `include "coverage.v"

    // DUT
    tsmccim16x8x11m1 #(
        .CORE_NUM(CORE_NUM),
        .XIN_BIT_WIDTH(XIN_BIT_WIDTH),
        .MEM_BIT_WIDTH(MEM_BIT_WIDTH),
        .MEM_ADR_WIDTH(MEM_ADR_WIDTH),
    ) DUT (
        .CLK(clk),
        .NRST(nrst),
        .ENCB(encb),
        .WEB(web),
        .BANKA(banka),
        .ADRA(adra),
        .D(d),
        .REB(reb),
        .BANKB(bankb),
        .ADRB(adrb),
        .XIN(xin),
        .Q(q)
    );

endmodule // simtop
