//SYNTHESIZABLE CODE

`timescale 1ns / 1ps


// 1. XNOR-XOR Pairwise Filter

module xnor_xor_filter (
    input wire path_i,
    input wire path_j,
    output reg decisive_win, 
    output reg i_beats_j     
);
    
    wire evaluate_now = path_i | path_j;    
    wire reset_now    = ~(path_i | path_j); 

    // Synthesizes to an asynchronous reset D-Latch/Flip-Flop
    always @(posedge evaluate_now or posedge reset_now) begin
        if (reset_now) begin
            decisive_win <= 1'b0;
            i_beats_j    <= 1'b0;
        end else begin
            decisive_win <= path_i ^ path_j;
            i_beats_j    <= path_i & ~path_j;
        end
    end
endmodule


// 2. 6-Pair Evaluation Matrix & Transitivity Rescue

module pairwise_matrix (
    input wire A, B, C, D,
    output wire [5:0] final_comp, // {AB, AC, AD, BC, BD, CD}
    output wire valid_out         
);
    wire v_AB, v_AC, v_AD, v_BC, v_BD, v_CD;
    wire r_AB, r_AC, r_AD, r_BC, r_BD, r_CD;

    xnor_xor_filter f_AB (.path_i(A), .path_j(B), .decisive_win(v_AB), .i_beats_j(r_AB));
    xnor_xor_filter f_AC (.path_i(A), .path_j(C), .decisive_win(v_AC), .i_beats_j(r_AC));
    xnor_xor_filter f_AD (.path_i(A), .path_j(D), .decisive_win(v_AD), .i_beats_j(r_AD));
    xnor_xor_filter f_BC (.path_i(B), .path_j(C), .decisive_win(v_BC), .i_beats_j(r_BC));
    xnor_xor_filter f_BD (.path_i(B), .path_j(D), .decisive_win(v_BD), .i_beats_j(r_BD));
    xnor_xor_filter f_CD (.path_i(C), .path_j(D), .decisive_win(v_CD), .i_beats_j(r_CD));
    
    wire deduced_AB = (~v_AB) ? ((r_AC & ~r_BC) ? 1'b1 : (~r_AC & r_BC) ? 1'b0 : 1'b0) : r_AB;
    wire deduced_AC = (~v_AC) ? ((r_AB & r_BC) ? 1'b1 : (~r_AB & ~r_BC) ? 1'b0 : 1'b0) : r_AC;
    wire deduced_AD = (~v_AD) ? ((r_AC & r_CD) ? 1'b1 : (~r_AC & ~r_CD) ? 1'b0 : 1'b0) : r_AD;
    wire deduced_BC = (~v_BC) ? ((~r_AB & r_AC) ? 1'b1 : (r_AB & ~r_AC) ? 1'b0 : 1'b0) : r_BC;
    wire deduced_BD = (~v_BD) ? ((r_BC & r_CD) ? 1'b1 : (~r_BC & ~r_CD) ? 1'b0 : 1'b0) : r_BD;
    wire deduced_CD = (~v_CD) ? ((~r_AC & r_AD) ? 1'b1 : (r_AC & ~r_AD) ? 1'b0 : 1'b0) : r_CD;

    assign valid_out = (v_AB + v_AC + v_AD + v_BC + v_BD + v_CD) >= 4; 
    assign final_comp = {deduced_AB, deduced_AC, deduced_AD, deduced_BC, deduced_BD, deduced_CD};
endmodule


// 3. (4,3)-Arbiter Rank Encoder

module arbiter_4_3 (
    input wire [5:0] comparisons,
    output wire [2:0] puf_response
);
    wire AB = comparisons[5];
    wire AC = comparisons[4];
    wire AD = comparisons[3];
    wire BC = comparisons[2];
    wire BD = comparisons[1];
    wire CD = comparisons[0];

    assign puf_response[2] = AB;
    assign puf_response[1] = CD;
    assign puf_response[0] = (AB & CD)  ? AC :
                             (AB & ~CD) ? AD :
                             (~AB & CD) ? BC :
                                          BD ;
endmodule


// 4. Structural 64-Stage MUX Delay Chain (Synthesizable)

module arbiter_chain #(
    parameter STAGES = 64,
    parameter integer ROUTE_BIAS = 10000, 
    parameter integer TOP_MUL = 3,        
    parameter integer TOP_MOD = 7,        
    parameter integer BOT_MUL = 5,        
    parameter integer BOT_MOD = 7         
)(
    input wire pulse_in,
    input wire [STAGES-1:0] challenge,
    output wire out_top,
    output wire out_bot
);
    (* DONT_TOUCH = "TRUE" *) wire top_net [STAGES:0];
    (* DONT_TOUCH = "TRUE" *) wire bot_net [STAGES:0];

    assign top_net[0] = pulse_in;
    assign bot_net[0] = pulse_in;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : mux_stage
            wire t_in = top_net[i];
            wire b_in = bot_net[i];

  
            assign top_net[i+1] = challenge[i] ? b_in : t_in;
            assign bot_net[i+1] = challenge[i] ? t_in : b_in;
        end
    endgenerate

    assign out_top = top_net[STAGES];
    assign out_bot = bot_net[STAGES];
endmodule


// 5. Top-Level PUF Wrapper

(* KEEP_HIERARCHY = "TRUE" *)
module puf_structural_top #(
    parameter integer BLOCK_ID = 0   
)(
    input wire challenge_pulse,
    input wire [127:0] challenge_bits,
    output wire [2:0] puf_response,
    output wire response_valid
);
    wire path_A, path_B, path_C, path_D;

    wire [127:0] challenge_bits_rev;
    genvar k;
    generate
        for (k = 0; k < 128; k = k + 1) begin : rev
            assign challenge_bits_rev[k] = challenge_bits[127-k];
        end
    endgenerate

    localparam integer ROT_AMOUNT = ((BLOCK_ID * 7) % 31) + 5;
    wire [127:0] challenge_bits_rot = (challenge_bits_rev << ROT_AMOUNT) |
                                       (challenge_bits_rev >> (128 - ROT_AMOUNT));

    localparam [127:0] BLOCK_MASK = {(BLOCK_ID*32'hD1B54A35 + 32'h9E3779B9),
                                      (BLOCK_ID*32'h9E3779B1 + 32'h85EBCA6B),
                                      (BLOCK_ID*32'h85EBCA6B + 32'hC2B2AE35),
                                      (BLOCK_ID*32'hC2B2AE35 + 32'hD1B54A35)};

    wire [127:0] challenge_bits_cd = challenge_bits_rot ^ BLOCK_MASK;

    arbiter_chain #(
        .STAGES    (64), 
        .ROUTE_BIAS(10000 + BLOCK_ID*173), 
        .TOP_MUL   (2 + (BLOCK_ID % 4)), 
        .TOP_MOD   (7),
        .BOT_MUL   (2 + ((BLOCK_ID + 1) % 4)),
        .BOT_MOD   (7)
    ) chain_AB (
        .pulse_in(challenge_pulse),
        .challenge(challenge_bits[63:0]),        
        .out_top(path_A),
        .out_bot(path_B)
    );

    arbiter_chain #(
        .STAGES    (64), 
        .ROUTE_BIAS(10000 + BLOCK_ID*173), 
        .TOP_MUL   (2 + ((BLOCK_ID + 2) % 4)),
        .TOP_MOD   (7),
        .BOT_MUL   (2 + ((BLOCK_ID + 3) % 4)),
        .BOT_MOD   (7)
    ) chain_CD (
        .pulse_in(challenge_pulse),
        .challenge(challenge_bits_cd[63:0]),    
        .out_top(path_C),
        .out_bot(path_D)
    );

    (* DONT_TOUCH = "TRUE" *) wire butterfly_ctrl = challenge_bits[31]; 

    (* DONT_TOUCH = "TRUE" *) wire path_A_routed = butterfly_ctrl ? path_C : path_A;
    (* DONT_TOUCH = "TRUE" *) wire path_B_routed = butterfly_ctrl ? path_D : path_B;
    (* DONT_TOUCH = "TRUE" *) wire path_C_routed = butterfly_ctrl ? path_A : path_C;
    (* DONT_TOUCH = "TRUE" *) wire path_D_routed = butterfly_ctrl ? path_B : path_D;

    wire [5:0] comp_results;
    
    pairwise_matrix comparator_matrix (
        .A(path_A_routed), .B(path_B_routed), .C(path_C_routed), .D(path_D_routed),
        .final_comp(comp_results),
        .valid_out(response_valid)
    );

    arbiter_4_3 rank_encoder (
        .comparisons(comp_results),
        .puf_response(puf_response)
    );
endmodule


// 6. Top-Level Cryptographic PUF Array

module cryptographic_puf_top #(
    parameter NUM_BLOCKS = 21 
)(
    input wire challenge_pulse,
    input wire [(NUM_BLOCKS*128)-1:0] master_challenge,
    output wire [(NUM_BLOCKS*3)-1:0] aggregated_response,
    output wire [NUM_BLOCKS-1:0]     aggregated_valid
);

    genvar i;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : puf_array
            puf_structural_top #(
                .BLOCK_ID(i)   
            ) individual_puf (
                .challenge_pulse(challenge_pulse),
                .challenge_bits(master_challenge[i*128 +: 128]),
                .puf_response(aggregated_response[i*3 +: 3]),
                .response_valid(aggregated_valid[i])
            );
        end
    endgenerate

endmodule
