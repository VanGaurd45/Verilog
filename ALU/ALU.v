`timescale 1ns / 1ps

module ALU(
    input clk,
    input reset,
    input [31:0] A, 
    input [31:0] B, 
    input [3:0] ALU_control, 
    output reg [31:0] result,
    output reg Z, 
    output reg N, 
    output reg C,
    output reg V
    );
    
    wire Cout;
    wire Z_wire, C_wire, V_wire, N_wire;
    wire [31:0] sum, mux1;
    reg [31:0] result_wire;
    
    // 1. Arithmetic Logic: Addition or Subtraction
    assign mux1 = ALU_control[0] ? ~B : B;
    assign {Cout, sum} = A + mux1 + ALU_control[0];
    

    always @(*) begin
        case(ALU_control)
            4'b0000:  result_wire = sum;                                // addition
            4'b0001:  result_wire = sum;                                // subtraction
            4'b0010:  result_wire = A | B;                              // logical OR   
            4'b0011:  result_wire = A & B;                              // logical AND
            4'b0100:  result_wire = A ^ B;                              // logical XOR
            4'b0101:  result_wire = A << B[4:0];                        // left shift
            4'b0110:  result_wire = A >> B[4:0];                        // Right shift
            4'b0111:  result_wire = {31'b0, $signed(A) < $signed(B)};   // SLT                                            
            4'b1000:  result_wire = {31'b0, A < B};                     // SLTU
            default:  result_wire = 32'b0;
        endcase
    end 
    
    // Combinatorial Flag Logic 
    assign Z_wire = (result_wire == 32'b0);
    assign N_wire = result_wire[31]; 
    
    // Carry is only valid for add/sub (Control 000x)
    assign C_wire = (ALU_control[3:1] == 3'b000) & Cout;
    
    // Overflow logic: Checks if two like signs produced a different sign
    assign V_wire = (ALU_control[3:1] == 3'b000) & (A[31] == mux1[31]) & (result_wire[31] != A[31]);
    
    // 4. Synchronous Output Stage
    // This captures the combinatorial wires into registers simultaneously
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            result <= 32'b0;
            Z <= 0;
            N <= 0;
            V <= 0;
            C <= 0;
        end
        else begin
            result <= result_wire;
            Z <= Z_wire;
            N <= N_wire;
            V <= V_wire;
            C <= C_wire;
        end
    end

endmodule
