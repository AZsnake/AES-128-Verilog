module aes_top (
    input  clk,
    input  rst_n,
    input  [127:0] plaintext,
    input  [127:0] key,
    output [127:0] ciphertext,
    output done
);
    wire [1407:0] full_keys;
    reg  [127:0] pipe_state [0:10];
    reg  [10:0]  valid_pipe;

    // 1. Key Expansion (Pre-calculated)
    aes_key_expand key_inst (.key(key), .full_keys(full_keys));

    // 2. Initial Round (AddRoundKey)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_state[0] <= 128'b0;
            valid_pipe <= 11'b0;
        end else begin
            pipe_state[0] <= plaintext ^ full_keys[0 +: 128];
            valid_pipe <= {valid_pipe[9:0], 1'b1};
        end
    end

    always @(posedge clk) begin
        if (valid_pipe[0]) $display("Round 0: %h", pipe_state[0]);
    end

    // 3. Main Rounds (1-9)
    genvar r;
    generate
        for (r = 1; r <= 9; r = r + 1) begin : round_stages
            wire [127:0] round_out;
            aes_round #(.FINAL(0)) inst (
                .data_in(pipe_state[r-1]), 
                .key_in(full_keys[r*128 +: 128]), 
                .data_out(round_out)
            );
            always @(posedge clk) begin
                pipe_state[r] <= round_out;
            end
            always @(posedge clk) begin
                if (valid_pipe[r]) $display("Round %0d: %h", r, pipe_state[r]);
            end
        end
    endgenerate

    // 4. Final Round (10)
    wire [127:0] final_out;
    aes_round #(.FINAL(1)) final_inst (
        .data_in(pipe_state[9]), 
        .key_in(full_keys[10*128 +: 128]), 
        .data_out(final_out)
    );
    always @(posedge clk) begin
        pipe_state[10] <= final_out;
    end
    always @(posedge clk) begin
        if (valid_pipe[10]) $display("Round 10: %h", pipe_state[10]);
    end

    // 5. Outputs
    assign ciphertext = pipe_state[10];
    assign done = valid_pipe[10];

endmodule
