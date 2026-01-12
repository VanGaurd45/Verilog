`timescale 1ns / 1ps

module traffic_light
#(parameter RED=2'b00,
parameter YELLOW=2'b01,
parameter GREEN=2'b10,
parameter S0=3'b000,    //GR
parameter S1=3'b001,    //YR
parameter S2=3'b010,    //RR
parameter S3=3'b011,    //RG
parameter S4=3'b100     //RY
)
(   input clk,
    input sensor,
    input reset,
    output reg [1:0] hwy,           //highway signal
    output reg [1:0] cntry          //country road signal
    );

reg [2:0] current_st,next_st;
    
// always for sequential
always @(posedge clk or negedge reset) begin
    if(!reset) current_st <= S0; 
    else current_st <= next_st;   
end

//always for state change
always @(current_st or sensor) begin
    
    case(current_st)
        S0:
           if(sensor) next_st <= S1;
           else next_st <= S0;
        S1:  
           next_st <= S2;
        S2:
           next_st <= S3;
        S3:
           if(sensor) next_st <= S3;
           else next_st <= S4; 
        S4:
           next_st <= S0;
        default: 
           next_st <= S0;
    endcase
end 

//always for output
always @(current_st) begin
    case(current_st)
        S0: begin hwy = GREEN; cntry = RED; end
        S1: begin hwy = YELLOW; cntry = RED; end
        S2: begin hwy = RED; cntry = RED; end
        S3: begin hwy = RED; cntry = GREEN; end
        S4: begin hwy = RED; cntry = YELLOW; end
    endcase    
end
endmodule
