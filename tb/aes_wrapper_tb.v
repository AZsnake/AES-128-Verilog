`timescale 1ns / 1ps

module aes_wrapper_tb;

    // Fixed ASSIGN-5: Initialize at declaration
    reg clk = 0;
    reg rst_n = 0;
    reg [3:0] addr = 4'h0;
    reg [31:0] data_in = 32'h0;
    wire [31:0] data_out;
    reg we = 0;
    reg en = 0;

    integer pass_count = 0;
    integer fail_count = 0;

    reg [31:0] data_out_full_read = 32'h0;
    reg [31:0] linter_check_sum = 32'h0;

    // Instantiate the wrapper
    aes_wrapper uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out),
        .we(we),
        .en(en)
    );

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task for a single AES test case
    task run_test_case(
        input [127:0] pt,
        input [127:0] key,
        input [127:0] expected_ct,
        input [31:0]  case_num
    );
        reg [127:0] read_ct;
        begin
            $display("--- Test Case %0d ---", case_num);
            $display("Private Text : %h", pt);
            $display("Key          : %h", key);

            // 1. Load Plaintext
            en = 1; we = 1;
            addr = 4'h0; data_in = pt[31:0];   #10;
            addr = 4'h1; data_in = pt[63:32];  #10;
            addr = 4'h2; data_in = pt[95:64];  #10;
            addr = 4'h3; data_in = pt[127:96]; #10;

            // 2. Load Key
            addr = 4'h4; data_in = key[31:0];   #10;
            addr = 4'h5; data_in = key[63:32];  #10;
            addr = 4'h6; data_in = key[95:64];  #10;
            addr = 4'h7; data_in = key[127:96]; #10;

            // 3. Start Calculation
            addr = 4'hC; data_in = 32'h1; #10;
            we = 0; 

            // 4. Wait for Done bit
            addr = 4'hC;
            @(posedge clk);
            data_out_full_read = data_out;
            linter_check_sum = linter_check_sum ^ data_out_full_read; 
            while (data_out_full_read[0] !== 1'b1) begin
                @(posedge clk);
                data_out_full_read = data_out;
                linter_check_sum = linter_check_sum ^ data_out_full_read;
            end
            $display("Calculation Done at %t", $time);

            // 5. Read and Verify Ciphertext
            #5; 
            addr = 4'h8;

            #1;
            
            data_out_full_read = data_out;
            read_ct[31:0]   = data_out_full_read;
            linter_check_sum = linter_check_sum ^ data_out_full_read;
            addr = 4'h9;
            
            #1;

            data_out_full_read = data_out;
            read_ct[63:32]  = data_out_full_read;
            linter_check_sum = linter_check_sum ^ data_out_full_read;
            addr = 4'hA;
            
            #1;

            data_out_full_read = data_out;
            read_ct[95:64]  = data_out_full_read;
            linter_check_sum = linter_check_sum ^ data_out_full_read;
            addr = 4'hB;
            
            #1;
            
            data_out_full_read = data_out;
            read_ct[127:96] = data_out_full_read;
            linter_check_sum = linter_check_sum ^ data_out_full_read;

            $display("Exp: %h", expected_ct);
            $display("Got: %h", read_ct);

            if (read_ct === expected_ct) begin
                $display("RESULT: [PASS]");
                pass_count = pass_count + 1;
            end else begin
                $display("RESULT: [FAIL] *******");
                fail_count = fail_count + 1;
            end
            $display("");
            #20;
        end
    endtask

    initial begin
        // Reset System
        rst_n = 0; addr = 4'h0; data_in = 32'h0; we = 0; en = 0;
        #50;
        rst_n = 1;
        #20;

        // Test Case 1: FIPS-197 Standard
        run_test_case(
            128'h3243f6a8885a308d313198a2e0370734,
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h3925841d02dc09fbdc118597196a0b32,
            1
        );

        // Test Case 2: All Zeros/Incremental
        run_test_case(
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            128'h69c4e0d86a7b0430d8cdb78070b4c55a,
            2
        );

        // Test Case 3: NIST SP 800-38A
        run_test_case(
            128'hf69f2445df4f9b17ad2b417be66c3710,
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h7b0c785e27e8ad3f8223207104725dd4,
            3
        );

        // Summary
        $display("---------------------------------------");
        $display("Simulation Summary:");
        $display("Total Cases: %0d", pass_count + fail_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("---------------------------------------");
        $display("Check Sum: %h (data_out parity: %b)", linter_check_sum, ^data_out);

        if (fail_count == 0) 
            $display("Overall Result: SUCCESS");
        else 
            $display("Overall Result: FAILURE");

        #50;
        $finish;
    end

endmodule
