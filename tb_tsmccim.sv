`timescale 1ps/1ps

module tb_tsmccim;
    // set DUT parameters as local parameter
    localparam CORE_NUM = 16;
    localparam XIN_BIT_WIDTH = 11;
    localparam MEM_BIT_WIDTH = 8;
    localparam CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1; // 18
    localparam MEM_ADR_WIDTH = 2;
    localparam OUTPUT_BIT_WIDTH = CORE_DOUT_BIT_WIDTH + $clog2(CORE_NUM); // 22

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

    initial begin
        $display("--- Simulation Start ---");
        {banka, bankb, adra, adrb, d} = 0;
        {web, reb, encb} = {1'b1, 1'b1, 1'b1};
        nrst = 0;
        #20;
        nrst = 1;
        #10;

        $display("\n--- 1. Write Sequence ---");
        web = 0;
        @(negedge clk);

        $display("Writing 8'hAA to BANK 0, ADDR 0");
        banka = 4'd0; adra = 2'd0; d = 8'hAA;
        @(negedge clk);

        $display("Writing 8'hB1 to BANK 0, ADDR 1");
        banka = 4'd0; adra = 2'd1; d = 8'hB1;
        @(negedge clk);

        $display("Writing 8'hC2 to BANK 0, ADDR 2");
        banka = 4'd0; adra = 2'd2; d = 8'hC2;
        @(negedge clk);

        $display("Writing 8'hD3 to BANK 0, ADDR 3");
        banka = 4'd0; adra = 2'd3; d = 8'hD3;
        @(negedge clk);

        web = 1;
        {banka, adra, d} = 0;
        repeat (4) @(negedge clk);


        $display("\n--- 2. Read Sequence ---");
        reb = 0;

        $display("Reading from BANK 0, ADDR 0...");
        
        bankb = 4'd0; 
        adrb = 2'd0;
        @(negedge clk);

        adrb = 2'd1;
        @(negedge clk);

        adrb = 2'd2;
        @(negedge clk);

        adrb = 2'd3;
        @(negedge clk);

        reb = 1;
        repeat (4) @(negedge clk);

        $display("\n--- 3. MAC Operation Sequence ---");
        // MAC Operation
        web = 1'b0;
        adra = 2'b0;

        for (int i = 0; i < CORE_NUM; i++) begin
            @(negedge clk);
            case (i)
                0:  d = 8'd34;
                1:  d = 8'd64;
                2:  d = 8'd240;
                3:  d = 8'd242;
                4:  d = 8'd143;
                5:  d = 8'd109;
                6:  d = 8'd166;
                7:  d = 8'd233;
                8:  d = 8'd105;
                9:  d = 8'd148;
                10: d = 8'd74;
                11: d = 8'd182;
                12: d = 8'd28;
                13: d = 8'd100;
                14: d = 8'd22;
                15: d = 8'd235;
                default: d = 8'd0;
            endcase
            banka = i;
        end

        @(negedge clk);
        web = 1'b1;

        repeat (4) @(negedge clk);

        adrb = 2'b0;
        encb = 1'b0;

        // xin 11bit data input
        for (int i = 0; i < CORE_NUM; i++) begin
            case(i)
                0:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(467);
                1:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(451);
                2:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1645);
                3:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(818);
                4:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1262);
                5:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1105);
                6:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1832);
                7:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1011);
                8:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(871);
                9:  xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(464);
                10: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1348);
                11: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1808);
                12: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(1282);
                13: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(987);
                14: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(680);
                15: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(997);
                default: xin[(i+1)*XIN_BIT_WIDTH-1 -: XIN_BIT_WIDTH] = XIN_BIT_WIDTH'(0);
            endcase
        end

        repeat (10) @(negedge CLK);

        $display("\n--- Simulation Finish ---");
        $finish;

    end

    // initial begin
    //     // --- 1. 初期化シーケンス ---
    //     $display("--- Simulation Start ---");
    //     CLK = 0;
    //     NRST = 0; // リセットをアサート
    //     {BANKA, BANKB, ADRA, ADRB, D} = '0;
    //     {WEB, REB, ENCB} = {1'b1, 1'b1, 1'b1}; // 全てのイネーブル信号を非アクティブに
    //     #20;
    //     NRST = 1; // リセットをディアサート
    //     #10;

    //     // --- 2. 全メモリ領域への書き込みテスト ---
    //     $display("\n--- Comprehensive Write Test Start ---");
    //     WEB <= 0; // 書き込みモードを有効化

    //     // 全16バンクをループ
    //     for (int bank = 0; bank < 16; bank = bank + 1) begin
    //         // バンク内の全4ワードをループ
    //         for (int addr = 0; addr < 4; addr = addr + 1) begin
    //             logic [7:0] data_to_write;
    //             // 検証しやすいよう、バンクとアドレスから一意のデータを生成
    //             data_to_write = {bank[3:0], addr[1:0], 2'b00}; 

    //             $display("Writing Data %h to BANK %d, ADDR %d", data_to_write, bank, addr);
    //             BANKA <= bank;
    //             ADRA  <= addr;
    //             D     <= data_to_write;
    //             @(negedge CLK); // 1クロック待機
    //         end
    //     end
    //     WEB <= 1; // 書き込みモードを無効化
    //     {BANKA, ADRA, D} = '0; // 入力信号をクリア
    //     repeat (4) @(negedge CLK);


    //     // --- 3. 全メモリ領域からの読み出しと検証テスト ---
    //     $display("\n--- Comprehensive Read and Verify Test Start ---");
    //     REB <= 0; // 読み出しモードを有効化

    //     // 読み出しコマンドが安定するまで1サイクル待つ
    //     @(negedge CLK); 

    //     // 全16バンクをループ
    //     for (int bank = 0; bank < 16; bank = bank + 1) begin
    //         // バンク内の全4ワードをループ
    //         for (int addr = 0; addr < 4; addr = addr + 1) begin
    //             logic [7:0] expected_data;
    //             // 書き込んだはずの期待値を、書き込み時と同じロジックで計算
    //             expected_data = {bank[3:0], addr[1:0], 2'b00};

    //             $display("Reading from BANK %d, ADDR %d...", bank, addr);
    //             BANKB <= bank;
    //             ADRB  <= addr;

    //             // DUTの読み出しレイテンシ（2クロック）を待機
    //             @(negedge CLK);
    //             @(negedge CLK);

    //             // 2クロック後にデータが出力されるので検証
    //             if (Q[7:0] == expected_data) begin
    //                 $display("  -> OK.   Read: %h, Expected: %h", Q[7:0], expected_data);
    //             end else begin
    //                 $display("  -> FAIL! Read: %h, Expected: %h", Q[7:0], expected_data);
    //             end
    //         end
    //     end
    //     REB <= 1; // 読み出しモードを無効化
    //     repeat (4) @(negedge CLK);


    //     // --- シミュレーション終了 ---
    //     $display("\n--- All tests are complete. Simulation Finish ---");
    //     $stop;
    // end

endmodule