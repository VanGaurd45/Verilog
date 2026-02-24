`timescale 1ns / 1ps

module tb_ALU();

    reg clk;
    reg reset;
    reg [31:0] A;
    reg [31:0] B;
    reg [3:0] ALU_control;
    wire [31:0] result;
    wire Z, N, C, V;

    ALU Dut (
    .clk(clk),
    .reset(reset),
        .A(A), 
        .B(B), 
        .ALU_control(ALU_control), 
        .result(result), 
        .Z(Z), 
        .N(N), 
        .C(C), 
        .V(V)
    );
    
    initial clk = 0;
    always #10 clk = ~clk;
    
    initial begin
        reset = 1; #45; reset = 0;
        
        #40 A = 32'd10; B = 32'd5; ALU_control = 4'b0001; // SUB (Res: 5)
        #40 A = 32'd10; B = 32'd5; ALU_control = 4'b0000; // ADD (Res: 15)
        #40 A = 32'd10; B = 32'd5; ALU_control = 4'b0010; // OR  (Res: 15)
        #40 A = 32'd10; B = 32'd5; ALU_control = 4'b0011; // AND (Res: 0)      
        // XOR: 10 (1010) ^ 5 (0101) = 15 (1111)
        #40 A = 32'd10; B = 32'd5; ALU_control = 4'b0100; // XOR
        // Left Shift (SLL): 1 << 4 = 16 (0x10)
        #40 A = 32'd1;  B = 32'd4; ALU_control = 4'b0101; // SLL
        // Right Shift (SRL): 32 >> 2 = 8
        #40 A = 32'd32; B = 32'd2; ALU_control = 4'b0110; // SRL
        // Set Less Than (SLT - Signed): -5 < 10 is True (Result: 1)
        #40 A = -32'd5; B = 32'd10; ALU_control = 4'b0111; // SLT
        // Set Less Than Unsigned (SLTU): -5 (large unsigned) < 10 is False (Result: 0)
        #40 A = -32'd5; B = 32'd10; ALU_control = 4'b1000; // SLTU
        // --- Flag Edge Cases ---
        // Zero Flag Check: 5 - 5 = 0
        #40 A = 32'd5; B = 32'd5; ALU_control = 4'b0001;  // SUB (Z should go high)
        // Overflow Check
        #40 A = 32'h7FFFFFFF; B = 32'd1; ALU_control = 4'b0000; // ADD

        #100 $finish;
   end

endmodule