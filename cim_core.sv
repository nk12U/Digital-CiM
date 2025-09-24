module cim_core #(
    parameter XIN_BIT_WIDTH = 11,
    parameter MEM_BIT_WIDTH = 8,
    parameter CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1, // 18
    parameter MEM_ADR_WIDTH = 2,
    parameter MEM_DEPTH = (1 << MEM_ADR_WIDTH) // 4
)(
    input                                clk,
    input [MEM_ADR_WIDTH-1:0]            wadr,
    input [MEM_ADR_WIDTH-1:0]            radr,
    input                                encb,
    input                                web,
    input                                reb,
    input [MEM_BIT_WIDTH-1:0]            din,
    input [XIN_BIT_WIDTH-1:0]            xin,
    output reg [CORE_DOUT_BIT_WIDTH-1:0] dout
);
    reg reb_d;
    reg encb_d;
    wire [MEM_BIT_WIDTH-1:0] mem_data;
    wire [CORE_DOUT_BIT_WIDTH-1:0] mac_data;

    sram_1r1w #(
        .MEM_DEPTH(MEM_DEPTH),
        .MEM_BIT_WIDTH(MEM_BIT_WIDTH),
        .MEM_ADR_WIDTH(MEM_ADR_WIDTH)
    ) memory (.clk(clk), .wadr(wadr), .radr(radr), .web(web), .reb(~reb | ~encb), .din(din), .dout(mem_data));

    mult_operator #(
        .XIN_BIT_WIDTH(XIN_BIT_WIDTH),
        .MEM_BIT_WIDTH(MEM_BIT_WIDTH),
        .CORE_DOUT_BIT_WIDTH(CORE_DOUT_BIT_WIDTH)
    ) MAC (.encb(encb_d), .din(mem_data), .xin(xin), .dout(mac_data));

    always @(posedge clk) begin
        reb_d  <= reb;
        encb_d <= encb;
    end

    wire [CORE_DOUT_BIT_WIDTH-1:0] dout_prev;
    assign dout_prev = ~encb_d ? mac_data : ~reb_d ? {{XIN_BIT_WIDTH{1'b0}}, mem_data} : {CORE_DOUT_BIT_WIDTH{1'b0}};
    
    always @(posedge clk) begin
        dout <= dout_prev;
    end

endmodule

// Signed magnitude multiplier
module mult_operator #(
    parameter XIN_BIT_WIDTH = 11,
    parameter MEM_BIT_WIDTH = 8,
    parameter CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1 // 18
)(
    input encb,
    input [MEM_BIT_WIDTH-1:0] din,
    input [XIN_BIT_WIDTH-1:0] xin,
    output [CORE_DOUT_BIT_WIDTH-1:0] dout
);
    wire sign;
    wire [CORE_DOUT_BIT_WIDTH-2:0] mag; // magnitude
    assign mag = din[MEM_BIT_WIDTH-2:0] * xin[XIN_BIT_WIDTH-2:0];
    assign sign = din[MEM_BIT_WIDTH-1] ^ xin[XIN_BIT_WIDTH-1];

    assign dout = ~encb ? {sign, mag} : {CORE_DOUT_BIT_WIDTH{1'd0}};
endmodule

// 1R/1W 2 port memory
module sram_1r1w #(
    parameter MEM_DEPTH = 4,
    parameter MEM_BIT_WIDTH = 8,
    parameter MEM_ADR_WIDTH = 2
)(
    input                          clk,
    input [MEM_ADR_WIDTH-1:0]      wadr, // wordline select address for write
    input [MEM_ADR_WIDTH-1:0]      radr, // wordline select address for read
    input                          web,
    input                          reb,
    input [MEM_BIT_WIDTH-1:0]      din,
    output reg [MEM_BIT_WIDTH-1:0] dout
);
    reg [MEM_BIT_WIDTH-1:0] mem [MEM_DEPTH-1:0]; // 4 word x 8 bit SRAM
    
    // Memory Write Sequence
    always @(posedge clk)
        if (~web)
            mem[wadr] <= din;
    
    // Memory Read Sequence
    always @(posedge clk)
        if (reb)  dout <= mem[radr];
        
endmodule