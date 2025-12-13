`timescale 1ns / 1ps

module aes_round #(parameter FINAL = 0) (
    input  [127:0] data_in,
    input  [127:0] key_in,
    output [127:0] data_out
);
    wire [127:0] sub_out;
    wire [127:0] shift_out;
    wire [127:0] mix_out;

    // 1. SubBytes
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sb
            aes_sbox sbox_inst (.in(data_in[i*8 +: 8]), .out(sub_out[i*8 +: 8]));
        end
    endgenerate

    // 2. ShiftRows
    assign shift_out = {
        sub_out[127:120], sub_out[87:80],   sub_out[47:40],   sub_out[7:0],
        sub_out[95:88],   sub_out[55:48],   sub_out[15:8],    sub_out[103:96],
        sub_out[63:56],   sub_out[23:16],   sub_out[111:104], sub_out[71:64],
        sub_out[31:24],   sub_out[119:112], sub_out[79:72],   sub_out[39:32]
    };

    // 3. MixColumns (GF Multiplication)
    function [7:0] gmul2(input [7:0] x);
        gmul2 = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    endfunction

    function [7:0] gmul3(input [7:0] x);
        gmul3 = gmul2(x) ^ x;
    endfunction

    reg [127:0] mix_reg;
    integer c;
    always @(*) begin
        for (c = 0; c < 4; c = c + 1) begin
            mix_reg[c*32+24 +: 8] = gmul2(shift_out[c*32+24 +: 8]) ^ gmul3(shift_out[c*32+16 +: 8]) ^ shift_out[c*32+8 +: 8] ^ shift_out[c*32 +: 8];
            mix_reg[c*32+16 +: 8] = shift_out[c*32+24 +: 8] ^ gmul2(shift_out[c*32+16 +: 8]) ^ gmul3(shift_out[c*32+8 +: 8]) ^ shift_out[c*32 +: 8];
            mix_reg[c*32+8 +: 8]  = shift_out[c*32+24 +: 8] ^ shift_out[c*32+16 +: 8] ^ gmul2(shift_out[c*32+8 +: 8]) ^ gmul3(shift_out[c*32 +: 8]);
            mix_reg[c*32 +: 8]     = gmul3(shift_out[c*32+24 +: 8]) ^ shift_out[c*32+16 +: 8] ^ shift_out[c*32+8 +: 8] ^ gmul2(shift_out[c*32 +: 8]);
        end
    end

    assign mix_out = FINAL ? shift_out : mix_reg;

    // 4. AddRoundKey
    assign data_out = mix_out ^ key_in;

endmodule
