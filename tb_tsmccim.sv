`timescale 1ns/1ps

module tb_tsmccim;

    reg CLK, NRST;
    reg [3:0] BANKA, BANKB;
    reg [1:0] ADRA, ADRB;
    reg [7:0] D;
    reg WEB, REB, ENCB;
    reg [175:0] XIN;
    wire [21:0] Q;

    tsmccim16x8x11m1 dut (
        .CLK(CLK), .NRST(NRST),
        .BANKA(BANKA), .ADRA(ADRA), .D(D), .WEB(WEB),
        .BANKB(BANKB), .ADRB(ADRB), .REB(REB),
        .ENCB(ENCB), .XIN(XIN),
        .Q(Q)
    );

    initial CLK = 0;
    always #5 CLK = ~CLK;

    initial begin
        $display("--- Simulation Start ---");
        {BANKA, BANKB, ADRA, ADRB, D} = 0;
        {WEB, REB, ENCB} = {1'b1, 1'b1, 1'b1};
        NRST = 0;
        #20;
        NRST = 1;
        #10;

        $display("\n--- 1. Write Sequence ---");
        WEB <= 0;
        @(negedge CLK);

        $display("Writing 8'hAA to BANK 0, ADDR 0");
        BANKA <= 4'd0; ADRA <= 2'd0; D <= 8'hAA;
        @(negedge CLK);

        $display("Writing 8'hB1 to BANK 0, ADDR 1");
        BANKA <= 4'd0; ADRA <= 2'd1; D <= 8'hB1;
        @(negedge CLK);

        $display("Writing 8'hC2 to BANK 0, ADDR 2");
        BANKA <= 4'd0; ADRA <= 2'd2; D <= 8'hC2;
        @(negedge CLK);
        
        WEB <= 1;
        {BANKA, ADRA, D} = 0;
        repeat (4)@(negedge CLK);


        $display("\n--- 2. Read Sequence ---");
        REB <= 0;

        $display("Reading from BANK 0, ADDR 0...");
        BANKB <= 4'd0; ADRB <= 2'd0;

        @(negedge CLK);

        ADRB <= 2'd1;
        @(negedge CLK);

        ADRB <= 2'd2;
        @(negedge CLK);

        REB <= 1;
        repeat (4) @(negedge CLK);

        // MAC Operation
        WEB <= 1'b0;
        ADRA <= 2'b0;

        D = 8'd34;
        BANKA = 4'd0;

        @(negedge CLK);
        D = 8'd64;
        BANKA = 4'd1;

        @(negedge CLK);
        D = 8'd240;
        BANKA = 4'd2;

        @(negedge CLK);
        D = 8'd242;
        BANKA = 4'd3;

        @(negedge CLK);
        D = 8'd143;
        BANKA = 4'd4;

        @(negedge CLK);
        D = 8'd109;
        BANKA = 4'd5;

        @(negedge CLK);
        D = 8'd166;
        BANKA = 4'd6;

        @(negedge CLK);
        D = 8'd233;
        BANKA = 4'd7;

        @(negedge CLK);
        D = 8'd105;
        BANKA = 4'd8;

        @(negedge CLK);
        D = 8'd148;
        BANKA = 4'd9;

        @(negedge CLK);
        D = 8'd74;
        BANKA = 4'd10;

        @(negedge CLK);
        D = 8'd182;
        BANKA = 4'd11;

        @(negedge CLK);
        D = 8'd28;
        BANKA = 4'd12;

        @(negedge CLK);
        D = 8'd100;
        BANKA = 4'd13;

        @(negedge CLK);
        D = 8'd22;
        BANKA = 4'd14;

        @(negedge CLK);
        D = 8'd235;
        BANKA = 4'd15;

        @(negedge CLK);
        WEB <= 1'b1;

        repeat (4) @(negedge CLK);

        ADRB <= 2'b0;
        ENCB <= 1'b0;

        XIN[10:0]  = 11'd467;
        XIN[21:11] = 11'd451;
        XIN[32:22] = 11'd1645;
        XIN[43:33] = 11'd818;
        XIN[54:44] = 11'd1262;
        XIN[65:55] = 11'd1105;
        XIN[76:66] = 11'd1832;
        XIN[87:77] = 11'd1011;
        XIN[98:88] = 11'd871;
        XIN[109:99]= 11'd464;
        XIN[120:110]=11'd1348;
        XIN[131:121]=11'd1808;
        XIN[142:132]=11'd1282;
        XIN[153:143]=11'd987;
        XIN[164:154]=11'd680;
        XIN[175:165]=11'd997;

        repeat (4) @(negedge CLK);

        $display("\n--- Simulation Finish ---");
        $stop;
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