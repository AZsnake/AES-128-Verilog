`timescale 1ns / 1ps

module aes_top (
    input  clk,
    input  rst_n,
    input  en_i,
    input  [127:0] plaintext,
    input  [127:0] key,
    output [127:0] ciphertext,
    output done
);
    reg  [127:0] pipe_state [0:10];
    reg  [10:0]  valid_pipe;
    reg  [10:0]  valid_pipe_q; // For edge detection in printing

    // 1. Key Expansion Pipeline
    // Each round key is registered to break the long combinational path
    reg [127:0] key_pipe [0:10];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_pipe[0] <= 128'b0;
        end else if (en_i) begin
            key_pipe[0] <= key;
        end
    end

    genvar i;
    generate
        for (i = 1; i <= 10; i = i + 1) begin : key_expansion_pipe
            wire [127:0] next_key;
            wire [7:0] rcon_val;
            
            assign rcon_val = (i==1) ? 8'h01 : (i==2) ? 8'h02 : (i==3) ? 8'h04 : (i==4) ? 8'h08 : 
                              (i==5) ? 8'h10 : (i==6) ? 8'h20 : (i==7) ? 8'h40 : (i==8) ? 8'h80 : 
                              (i==9) ? 8'h1b : (i==10) ? 8'h36 : 8'h00;
            
            aes_key_step step_inst (
                .key_in(key_pipe[i-1]), 
                .rcon(rcon_val), 
                .key_out(next_key)
            );
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    key_pipe[i] <= 128'b0;
                end else if (en_i) begin
                    key_pipe[i] <= next_key;
                end
            end
        end
    endgenerate

    // 2. Initial Round (AddRoundKey)
    reg [127:0] plaintext_q;
    reg en_i_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plaintext_q <= 128'b0;
            en_i_q <= 1'b0;
            pipe_state[0] <= 128'b0;
            valid_pipe <= 11'b0;
            valid_pipe_q <= 11'b0;
        end else begin
            valid_pipe_q <= valid_pipe;
            plaintext_q <= plaintext;
            en_i_q <= en_i;
            
            if (en_i_q) begin
                pipe_state[0] <= plaintext_q ^ key_pipe[0];
                valid_pipe <= {valid_pipe[9:0], 1'b1};
            end else begin
                valid_pipe <= {valid_pipe[9:0], 1'b0};
            end
        end
    end

    // 3. Main Rounds (1-9)
    genvar r;
    generate
        for (r = 1; r <= 9; r = r + 1) begin : round_stages
            wire [127:0] round_out;
            aes_round #(.FINAL(0)) inst (
                .data_in(pipe_state[r-1]), 
                .key_in(key_pipe[r]), 
                .data_out(round_out)
            );
            always @(posedge clk) begin
                if (en_i) pipe_state[r] <= round_out;
            end
        end
    endgenerate

    // 4. Final Round (10)
    wire [127:0] final_out;
    aes_round #(.FINAL(1)) final_inst (
        .data_in(pipe_state[9]), 
        .key_in(key_pipe[10]), 
        .data_out(final_out)
    );
    always @(posedge clk) begin
        if (en_i) pipe_state[10] <= final_out;
    end

    // 5. Outputs
    assign ciphertext = pipe_state[10];
    assign done = valid_pipe[10] & ~valid_pipe_q[10];

endmodule

// Helper module for key expansion steps
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
