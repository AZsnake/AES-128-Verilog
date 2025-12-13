module aes_wrapper (
    input  clk,
    input  rst_n,
    input  [3:0] addr,
    input  [31:0] data_in,
    output reg [31:0] data_out,
    input  we,
    input  en
);

    // Internal registers for plaintext and key
    reg [127:0] plaintext_reg;
    reg [127:0] key_reg;
    wire [127:0] ciphertext_out;
    wire done_out;
    reg start_reg;

    // Instantiate the AES core
    aes_top aes_inst (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext(plaintext_reg),
        .key(key_reg),
        .ciphertext(ciphertext_out),
        .done(done_out)
    );

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plaintext_reg <= 128'b0;
            key_reg <= 128'b0;
            start_reg <= 1'b0;
        end else if (en && we) begin
            case (addr)
                4'h0: plaintext_reg[31:0]   <= data_in;
                4'h1: plaintext_reg[63:32]  <= data_in;
                4'h2: plaintext_reg[95:64]  <= data_in;
                4'h3: plaintext_reg[127:96] <= data_in;
                4'h4: key_reg[31:0]         <= data_in;
                4'h5: key_reg[63:32]        <= data_in;
                4'h6: key_reg[95:64]        <= data_in;
                4'h7: key_reg[127:96]       <= data_in;
                4'hC: start_reg             <= data_in[0];
            endcase
        end else begin
            // Reset start signal after one cycle if needed, 
            // but for a pipelined core, we might not need it.
            // Let's keep it simple for now.
        end
    end

    // Read logic
    always @(*) begin
        if (en) begin
            case (addr)
                4'h0: data_out = plaintext_reg[31:0];
                4'h1: data_out = plaintext_reg[63:32];
                4'h2: data_out = plaintext_reg[95:64];
                4'h3: data_out = plaintext_reg[127:96];
                4'h4: data_out = key_reg[31:0];
                4'h5: data_out = key_reg[63:32];
                4'h6: data_out = key_reg[95:64];
                4'h7: data_out = key_reg[127:96];
                4'h8: data_out = ciphertext_out[31:0];
                4'h9: data_out = ciphertext_out[63:32];
                4'hA: data_out = ciphertext_out[95:64];
                4'hB: data_out = ciphertext_out[127:96];
                4'hC: data_out = {31'b0, done_out};
                default: data_out = 32'h0;
            endcase
        end else begin
            data_out = 32'h0;
        end
    end

endmodule
