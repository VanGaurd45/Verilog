`timescale 1ns / 1ps

module arbiter #(parameter N = 4)(input in, input [N-1:0] sel, input reset, output out );
    
    wire [N-1:0]up;
    wire [N-1:0]down;
    
    mux_block block0 (in,~in,sel[0],up[0],down[0]);
    generate 
        genvar i;
        for(i = 0; i < N-1; i=i+1) begin: mux_blocks
            mux_block iblock (up[i],down[i],sel[i+1],up[i+1],down[i+1]);
        end
    endgenerate
    
    d_ff D (up[N-1],down[N-1],reset,out);
    
endmodule

module d_ff(input d, input clk, input reset, output reg Q);

    always @(posedge clk or posedge reset) begin
        if(reset)   Q<=1'b0;
        else Q<=d;
    end
    
endmodule

module mux2X1(input i0, input i1, input sel, output out);

    assign out = sel ? i1 : i0;
    
endmodule

module mux_block(input in_up, input in_down, input sel, output out_up, output out_down);

    mux2X1 #0.1 mux_up (in_up,in_down,sel,out_up);
    mux2X1 #0.2 mux_down (in_down,in_up,sel,out_down);
    
endmodule
