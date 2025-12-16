`timescale 1ns / 1ps

module aes_key_expand (
    input  [127:0] key,
    output [1407:0] full_keys // 128 * 11 bits
);
    wire [31:0] w[0:43]; // 44 words for AES-128 (4*11)
    
    // Initial key words
    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];

    genvar i;
    generate
        for (i = 1; i <= 10; i = i + 1) begin : key_gen
            wire [31:0] rot_word;
            wire [31:0] sub_word;

            // RotWord: Cyclic shift
            assign rot_word = {w[i*4-1][23:0], w[i*4-1][31:24]};

            // SubWord: Using S-Box for each byte
            aes_sbox sb0 (.in(rot_word[31:24]), .out(sub_word[31:24]));
            aes_sbox sb1 (.in(rot_word[23:16]), .out(sub_word[23:16]));
            aes_sbox sb2 (.in(rot_word[15:8]),  .out(sub_word[15:8]));
            aes_sbox sb3 (.in(rot_word[7:0]),   .out(sub_word[7:0]));

            // Rcon (FIPS-197 standard powers of 2 in GF(2^8))
            wire [7:0] rcon_val;
            assign rcon_val = (i==1) ? 8'h01 : (i==2) ? 8'h02 : (i==3) ? 8'h04 : (i==4) ? 8'h08 : 
                              (i==5) ? 8'h10 : (i==6) ? 8'h20 : (i==7) ? 8'h40 : (i==8) ? 8'h80 : 
                              (i==9) ? 8'h1b : (i==10) ? 8'h36 : 8'h00;

            // Key generation logic
            assign w[i*4]   = w[(i-1)*4] ^ sub_word ^ {rcon_val, 24'h000000};
            assign w[i*4+1] = w[(i-1)*4+1] ^ w[i*4];
            assign w[i*4+2] = w[(i-1)*4+2] ^ w[i*4+1];
            assign w[i*4+3] = w[(i-1)*4+3] ^ w[i*4+2];
        end
    endgenerate

    // Pack all keys into a single bus
    genvar k;
    generate
        for (k = 0; k < 11; k = k + 1) begin : pack
            assign full_keys[k*128 +: 128] = {w[k*4], w[k*4+1], w[k*4+2], w[k*4+3]};
        end
    endgenerate

endmodule
