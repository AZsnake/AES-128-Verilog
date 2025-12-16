`timescale 1ns / 1ps

module aes_key_step (
    input  [127:0] key_in,
    input  [7:0]   rcon,
    output [127:0] key_out
);
    wire [31:0] w[0:3];
    wire [31:0] next_w[0:3];

    assign w[0] = key_in[127:96];
    assign w[1] = key_in[95:64];
    assign w[2] = key_in[63:32];
    assign w[3] = key_in[31:0];

    wire [31:0] rot_word = {w[3][23:0], w[3][31:24]};
    wire [31:0] sub_word;

    aes_sbox sb0 (.in(rot_word[31:24]), .out(sub_word[31:24]));
    aes_sbox sb1 (.in(rot_word[23:16]), .out(sub_word[23:16]));
    aes_sbox sb2 (.in(rot_word[15:8]),  .out(sub_word[15:8]));
    aes_sbox sb3 (.in(rot_word[7:0]),   .out(sub_word[7:0]));

    assign next_w[0] = w[0] ^ sub_word ^ {rcon, 24'h000000};
    assign next_w[1] = w[1] ^ next_w[0];
    assign next_w[2] = w[2] ^ next_w[1];
    assign next_w[3] = w[3] ^ next_w[2];

    assign key_out = {next_w[0], next_w[1], next_w[2], next_w[3]};

endmodule
