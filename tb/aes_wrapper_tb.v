`timescale 1ns / 1ps

module aes_wrapper_tb;

    reg clk;
    reg rst_n;
    reg [3:0] addr;
    reg [31:0] data_in;
    wire [31:0] data_out;
    reg we;
    reg en;

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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // AES-128 Test Vectors (Example)
    // Plaintext: 3243f6a8885a308d313198a2e0370734
    // Key:       2b7e151628aed2a6abf7158809cf4f3c
    // Expected:  3925841d02dc09fbdc118597196a0b32

    initial begin
        // Reset
        rst_n = 0;
        addr = 0;
        data_in = 0;
        we = 0;
        en = 0;
        #20;
        rst_n = 1;
        #10;

        // 1. Load Plaintext
        en = 1; we = 1;
        addr = 4'h0; data_in = 32'hE0370734; #10; // Lowest 32 bits
        addr = 4'h1; data_in = 32'h313198A2; #10;
        addr = 4'h2; data_in = 32'h885A308D; #10;
        addr = 4'h3; data_in = 32'h3243F6A8; #10;

        // 2. Load Key
        addr = 4'h4; data_in = 32'h09CF4F3C; #10;
        addr = 4'h5; data_in = 32'hABF71588; #10;
        addr = 4'h6; data_in = 32'h28AED2A6; #10;
        addr = 4'h7; data_in = 32'h2B7E1516; #10;
        
        we = 0; #10;

        // 3. Wait for Done
        $display("Waiting for AES calculation...");
        #200; // Enough time for 10+ cycles

        // 4. Read Ciphertext
        $display("Reading results...");
        we = 0;
        addr = 4'h8; #10; $display("CT[31:0]:   %h", data_out);
        addr = 4'h9; #10; $display("CT[63:32]:  %h", data_out);
        addr = 4'hA; #10; $display("CT[95:64]:  %h", data_out);
        addr = 4'hB; #10; $display("CT[127:96]: %h", data_out);
        addr = 4'hC; #10; $display("Status:     %h", data_out);

        #50;
        $finish;
    end

endmodule
