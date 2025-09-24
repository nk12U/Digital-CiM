module tsmccim16x8x11m1 #(
    parameter CORE_NUM = 16,                                            // power of 2
    parameter XIN_BIT_WIDTH = 11,                                       // natural number
    parameter MEM_BIT_WIDTH = 8,                                        // natural number, bitline
    parameter CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1,  // 18
    parameter MEM_ADR_WIDTH = 2,                                        // natural number, wordline
    parameter OUTPUT_BIT_WIDTH = CORE_DOUT_BIT_WIDTH + $clog2(CORE_NUM) // 22
    )(
    input CLK,
    input NRST,
    input ENCB,                              // active low  
    input WEB,                               // active low
    input [$clog2(CORE_NUM)-1:0] BANKA,      // select write bank
    input [MEM_ADR_WIDTH-1:0] ADRA,
    input [MEM_BIT_WIDTH-1:0] D,
    input REB,                               // active low
    input [$clog2(CORE_NUM)-1:0] BANKB,      // select read bank
    input [MEM_ADR_WIDTH-1:0] ADRB,
    input [(CORE_NUM*XIN_BIT_WIDTH)-1:0] XIN,
    output [OUTPUT_BIT_WIDTH-1:0] Q
);
    reg [XIN_BIT_WIDTH-1:0] xin [CORE_NUM-1:0];                        // input to core

    wire        [CORE_DOUT_BIT_WIDTH-1:0] core_dout    [CORE_NUM-1:0]; // output from core
    wire signed [CORE_DOUT_BIT_WIDTH-1:0] core_dout_tc [CORE_NUM-1:0]; // 2's complement output from core
    wire [OUTPUT_BIT_WIDTH-1:0] adder_tree_out;                        // Adder Tree output

    wire [CORE_NUM-1:0] write_bank_select;                             // one-hot write bank select from decoder
    wire [CORE_NUM-1:0] read_bank_select;                              // one-hot read bank select from decoder

    // Write Decoder
    decoder #(
        .ADDR_WIDTH($clog2(CORE_NUM)),
        .OUTPUT_WIDTH(CORE_NUM)
    ) WriteDecoder (
        .in(BANKA),
        .out(write_bank_select)
    );

    // Read Decoder
    decoder #(
        .ADDR_WIDTH($clog2(CORE_NUM)),
        .OUTPUT_WIDTH(CORE_NUM)
    ) ReadDecoder (
        .in(BANKB),
        .out(read_bank_select)
    );

    // split XIN into 11bit and store in xin array
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            for (int i = 0; i < CORE_NUM; i++)
                xin[i] <= {XIN_BIT_WIDTH{1'd0}};
        end else begin
            for (int i = 0; i < CORE_NUM; i++)
                xin[i] <= XIN[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH]; // [start bit -: bit width]
        end
    end

    // generate cim_core and connect signals
    genvar i;
    generate
        for (i = 0; i < CORE_NUM; i++) begin : cim_core_gen // cim_core_gen[0].cim_core_inst
            cim_core #(
                .XIN_BIT_WIDTH(XIN_BIT_WIDTH),              // 11
                .MEM_BIT_WIDTH(MEM_BIT_WIDTH),              // 8
                .CORE_DOUT_BIT_WIDTH(CORE_DOUT_BIT_WIDTH),  // 18
                .MEM_ADR_WIDTH(MEM_ADR_WIDTH),              // 2 
                .MEM_DEPTH(1 << MEM_ADR_WIDTH)              // 2^2 = 4
            ) cim_core_inst (
                .clk(CLK),
                .wadr(ADRA),
                .radr(ADRB),
                .encb(ENCB),
                .web(WEB | ~write_bank_select[i]), // web is active low, so disable write for unselected banks
                .reb(REB | ~read_bank_select[i]),  // reb is active low, so disable read for unselected banks
                .din(D),
                .xin(xin[i]),
                .dout(core_dout[i])
            );
        end
    endgenerate

    // delayed bankb_d1
    reg [$clog2(CORE_NUM)-1:0] bankb_d1;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            bankb_d1 <= {$clog2(CORE_NUM){1'd0}};
        end else begin
            bankb_d1 <= BANKB;
        end
    end

    // delayed bankb_d2
    reg [$clog2(CORE_NUM)-1:0] bankb_d2;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            bankb_d2 <= {$clog2(CORE_NUM){1'd0}};
        end else begin
            bankb_d2 <= bankb_d1;
        end
    end

    wire [MEM_BIT_WIDTH-1:0] read_data_mux_out;

    assign read_data_mux_out = core_dout[bankb_d2][MEM_BIT_WIDTH-1:0];  

    reg reb_d1;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            reb_d1 <= 1'b1;
        end else begin
            reb_d1 <= REB;
        end
    end

    reg reb_d2;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            reb_d2 <= 1'b1;
        end else begin
            reb_d2 <= reb_d1;
        end
    end

    reg encb_d1;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            encb_d1 <= 1'b1;
        end else begin
            encb_d1 <= ENCB;
        end
    end

    reg encb_d2;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            encb_d2 <= 1'b1;
        end else begin
            encb_d2 <= encb_d1;
        end
    end

    localparam ADDER_TREE_STAGES = $clog2(CORE_NUM);
    localparam ADDER_TREE_LATENCY = ADDER_TREE_STAGES + 1;

    reg reb_pipe [ADDER_TREE_LATENCY-1:0];
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            for (int i = 0; i < ADDER_TREE_LATENCY; i++) begin
                reb_pipe[i] <= 1'b1;
            end 
        end else begin
            reb_pipe[0] <= reb_d2;
            for (int i = 0; i < ADDER_TREE_LATENCY - 1; i++) begin
                reb_pipe[i+1] <= reb_pipe[i];
            end
        end
    end
    wire reb_final = reb_pipe[ADDER_TREE_LATENCY-1];

    reg encb_pipe [ADDER_TREE_LATENCY-1:0];
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            for (int i = 0; i < ADDER_TREE_LATENCY; i++) begin
                encb_pipe[i] <= 1'b1;
            end 
        end else begin 
            encb_pipe[0] <= encb_d2;
            for (int i = 0; i < ADDER_TREE_LATENCY - 1; i++) begin
                encb_pipe[i+1] <= encb_pipe[i];
            end
        end
    end
    wire encb_final = encb_pipe[ADDER_TREE_LATENCY-1];

    reg [MEM_BIT_WIDTH-1:0] read_data_mux_out_pipe [ADDER_TREE_LATENCY-1:0];
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            for (int i = 0; i < ADDER_TREE_LATENCY; i++) begin
                read_data_mux_out_pipe[i] <= {MEM_BIT_WIDTH{1'b0}};
            end 
        end else begin
            read_data_mux_out_pipe[0] <= read_data_mux_out;
            for (int i = 0; i < ADDER_TREE_LATENCY - 1; i++) begin
                read_data_mux_out_pipe[i+1] <= read_data_mux_out_pipe[i];
            end
        end
    end
    wire [MEM_BIT_WIDTH-1:0] read_data_mux_out_final = read_data_mux_out_pipe[ADDER_TREE_LATENCY-1];

    wire [OUTPUT_BIT_WIDTH-1:0] Q_prev;
    assign Q_prev = ~reb_final ? {{{OUTPUT_BIT_WIDTH - MEM_BIT_WIDTH}{1'b0}}, read_data_mux_out_final} : adder_tree_out;

    // for signal confirm
    wire [CORE_DOUT_BIT_WIDTH-1:0] core_dout_tc0 = core_dout_tc[0];
    wire [CORE_DOUT_BIT_WIDTH-1:0] core_dout_tc3 = core_dout_tc[3];

    TC_Converter #(
        .CORE_NUM(CORE_NUM),
        .CORE_DOUT_BIT_WIDTH(CORE_DOUT_BIT_WIDTH)
    ) TC_Converter_inst (
        .in(core_dout),
        .out(core_dout_tc)
    );

    AdderTree #(
        .CORE_NUM(CORE_NUM),
        .CORE_DOUT_BIT_WIDTH(CORE_DOUT_BIT_WIDTH),
        .OUTPUT_BIT_WIDTH(OUTPUT_BIT_WIDTH)
    ) AdderTree_inst (
        .CLK(CLK),
        .NRST(NRST),
        .in(core_dout_tc),
        .sum(adder_tree_out)
    );

    reg [OUTPUT_BIT_WIDTH-1:0] Q_reg;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            Q_reg <= {OUTPUT_BIT_WIDTH{1'b0}};
        end else if (~reb_final | ~encb_final) begin
            Q_reg <= Q_prev;
        end else begin
            Q_reg <= Q_reg;    // hold previous value
        end
    end

    assign Q = Q_reg;

endmodule

module decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUTPUT_WIDTH = 16
)(
    input [ADDR_WIDTH-1:0] in,
    output [OUTPUT_WIDTH-1:0] out
);
    assign out = (1 << in); // in-bit shift left
endmodule

module TC_Converter #(
    parameter CORE_NUM = 16,
    parameter CORE_DOUT_BIT_WIDTH = 18
)(
    input         [CORE_DOUT_BIT_WIDTH-1:0] in  [CORE_NUM-1:0], // signed magnitude
    output signed [CORE_DOUT_BIT_WIDTH-1:0] out [CORE_NUM-1:0]  // 2's complement
);
    genvar i;
    generate
        for (i = 0; i < CORE_NUM; i++) begin : TC_Converter
            // if sign bit is 1, convert to 2's complement
            assign out[i] = in[i][CORE_DOUT_BIT_WIDTH-1] ? (~{1'b0, in[i][CORE_DOUT_BIT_WIDTH-2:0]} + 1'b1) : in[i];
        end
    endgenerate
endmodule

//================================================================
// Pipelined AdderTree
//================================================================
module AdderTree #(
    parameter CORE_NUM = 16,
    parameter CORE_DOUT_BIT_WIDTH = 18,
    parameter OUTPUT_BIT_WIDTH = 22
)(
    input CLK,
    input NRST,
    // input and output are signed(2's complement)
    input signed [CORE_DOUT_BIT_WIDTH-1:0] in [CORE_NUM-1:0],
    output signed [OUTPUT_BIT_WIDTH-1:0] sum
);
    localparam STAGES = $clog2(CORE_NUM); // 4 STAGES for CORE_NUM = 16

    reg signed [OUTPUT_BIT_WIDTH-1:0] sums [STAGES:0][CORE_NUM-1:0]; // bit, stage, index

    integer i, stage;
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            for (stage = 0; stage <= STAGES; stage++) begin
                for (i = 0; i < CORE_NUM; i++) begin
                    sums[stage][i] <= 'd0;
                end
            end
        end else begin
            // stage 0: input assignment
            for (i = 0; i < CORE_NUM; i++) begin
                sums[0][i] <= in[i]; // automatically sign-extended
            end

            // stage 1 to final stage
            for (stage = 0; stage < STAGES; stage++) begin
                for (i = 0; i < (CORE_NUM >> (stage + 1)); i++) begin
                    sums[stage+1][i] <= sums[stage][2*i] + sums[stage][2*i+1];
                end
            end
        end
    end

    // final sum
    assign sum = sums[STAGES][0];
endmodule

// module AdderTree #(
//     parameter CORE_NUM = 16,
//     parameter CORE_DOUT_BIT_WIDTH = 18,
//     parameter OUTPUT_BIT_WIDTH = 22
// )(
//     // input and output are signed(2's complement)
//     input signed [CORE_DOUT_BIT_WIDTH-1:0] in [CORE_NUM-1:0],
//     output signed [OUTPUT_BIT_WIDTH-1:0] sum
// );
//     localparam STAGES = $clog2(CORE_NUM); // 4 STAGES for CORE_NUM = 16

//     wire signed [OUTPUT_BIT_WIDTH-1:0] sums [STAGES:0][CORE_NUM-1:0]; // bit, stage, index

//     // stage 0: input assignment
//     genvar i;
//     generate
//         for (i = 0; i < CORE_NUM; i++) begin : input_stage
//             assign sums[0][i] = in[i]; // automatically sign-extended
//         end
//     endgenerate

//     // stage 1 to final stage
//     genvar stage;
//     generate
//         for (stage = 0; stage < STAGES; stage++) begin : stage_loop
//             localparam ADDERS_NUM = CORE_NUM >> (stage + 1); // number of adders are halved each stage
//             for (i = 0; i < ADDERS_NUM; i++) begin : adder_loop
//                 assign sums[stage+1][i] = sums[stage][2*i] + sums[stage][2*i+1];
//             end
//         end
//     endgenerate

//     // final sum
//     assign sum = sums[STAGES][0];
// endmodule

// module AdderTree #(
//     parameter CORE_NUM = 16,
//     parameter CORE_DOUT_BIT_WIDTH = 18,
//     parameter OUTPUT_BIT_WIDTH = 22
// )(
//     input [CORE_DOUT_BIT_WIDTH-1:0] in [CORE_NUM-1:0],
//     output [OUTPUT_BIT_WIDTH-1:0] sum
// );
//     wire [CORE_DOUT_BIT_WIDTH:0]   sum_level1 [CORE_NUM/2-1:0];
//     wire [CORE_DOUT_BIT_WIDTH+1:0] sum_level2 [CORE_NUM/4-1:0];
//     wire [CORE_DOUT_BIT_WIDTH+2:0] sum_level3 [CORE_NUM/8-1:0];
    
//     // Level 1
//     genvar i;
//     generate
//         for (i = 0; i < CORE_NUM/2; i++) begin : level1
//             assign sum_level1[i] = {in[2*i][CORE_DOUT_BIT_WIDTH-1], in[2*i]} + {in[2*i+1][CORE_DOUT_BIT_WIDTH-1], in[2*i+1]};
//         end
//     endgenerate

//     // Level 2
//     generate
//         for (i = 0; i < CORE_NUM/4; i++) begin : level2
//             assign sum_level2[i] = {sum_level1[2*i][CORE_DOUT_BIT_WIDTH], sum_level1[2*i]} + {sum_level1[2*i+1][CORE_DOUT_BIT_WIDTH], sum_level1[2*i+1]};
//         end
//     endgenerate

//     // Level 3
//     generate
//         for (i = 0; i < CORE_NUM/8; i++) begin : level3
//             assign sum_level3[i] = {sum_level2[2*i][CORE_DOUT_BIT_WIDTH+1], sum_level2[2*i]} + {sum_level2[2*i+1][CORE_DOUT_BIT_WIDTH+1], sum_level2[2*i+1]};
//         end
//     endgenerate

//     // Final Sum
//     assign sum = {sum_level3[0][CORE_DOUT_BIT_WIDTH+2], sum_level3[0]} + {sum_level3[1][CORE_DOUT_BIT_WIDTH+2], sum_level3[1]};
// endmodule
