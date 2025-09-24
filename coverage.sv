    initial begin
        localparam CORE_NUM = 16;
        localparam XIN_BIT_WIDTH = 11;
        localparam MEM_BIT_WIDTH = 8;
        localparam CORE_DOUT_BIT_WIDTH = XIN_BIT_WIDTH + MEM_BIT_WIDTH - 1; // 18
        localparam MEM_ADR_WIDTH = 2;
        localparam OUTPUT_BIT_WIDTH = CORE_DOUT_BIT_WIDTH + $clog2(CORE_NUM); // 22

        //initialize
        #0 nrst = 1'b1;
        @(negedge clk);
        nrst = 1'b0;
        encb = 1'b1; // negative
        web = 1'b1;  // negative
        banka = {$clog2(CORE_NUM){1'd0}};
        adra = {MEM_ADR_WIDTH{1'd0}};
        d = {MEM_BIT_WIDTH{1'd0}};
        reb = 1'b1;  // negative
        bankb = {$clog2(CORE_NUM){1'd0}};
        adrb = {MEM_ADR_WIDTH{1'd0}};
        xin = {(CORE_NUM*XIN_BIT_WIDTH){1'd0}};

        // reset
        @(negedge clk);
        nrst = 1'b1;
        repeat (4) @(negedge clk);

        $display("\n--- Comprehensive Write Read test start ---");
        // Write
        web = 1'b0; // active

        // loop all banks
        for (int bank = 0; bank < CORE_NUM; bank++) begin
            // loop all words
            for (int addr = 0; addr < (1 << MEM_ADR_WIDTH); addr++) begin
                logic [MEM_BIT_WIDTH-1:0] write_data;
                // write unique data
                write_data = {bank[$clog2(CORE_NUM)-1:0],
                              addr[MEM_ADR_WIDTH-1:0],
                              {(MEM_BIT_WIDTH-$clog2(CORE_NUM)-MEM_ADR_WIDTH){1'd0}}
                             };
                
                $display("Write data %h to bank %d, addr %d", write_data, bank, addr);
                banka = bank;
                adra  = addr;
                d     = write_data;
                @(negedge clk); // wait 1 clock
            end
        end

        web = 1'b1; // inactive
        {banka, adra, d} = '0; // clear input signals
        repeat (4) @(negedge clk) #1;

        // Read and Verify
        $display("\n--- Read sequence start ---");
        reb = 1'b0; // active

        // loop all banks
        for (int bank = 0; bank < CORE_NUM; bank++) begin
            // loop all words
            for (int addr = 0; addr < (1 << MEM_ADR_WIDTH); addr++) begin
                logic [MEM_BIT_WIDTH-1:0] expected_data;
                expected_data = {bank[$clog2(CORE_NUM)-1:0],
                                 addr[MEM_ADR_WIDTH-1:0],
                                 {(MEM_BIT_WIDTH-$clog2(CORE_NUM)-MEM_ADR_WIDTH){1'd0}}
                                };

                $display("Read from bank %d, addr %d", bank, addr);
                bankb = bank;
                adrb  = addr;

                // wait 3 clk
                repeat (3) @(negedge clk) #1;

                if (q == expected_data) begin
                    $display("  Read data %h matches expected %h", q, expected_data);
                end else begin
                    $display("  ERROR: Read data %h does NOT match expected %h", q, expected_data);
                end
            end
        end

        reb = 1'b1; // inactive
        $display("\n--- Finished Write Read test ---");
        {banka, adra, d} = '0; // clear input signals
        repeat (4) @(negedge clk) #1;
    end