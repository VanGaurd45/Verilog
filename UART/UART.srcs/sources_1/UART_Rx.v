`timescale 1ns / 1ps


module UART_Rx
#(
    parameter clk_freq = 10000000,             //10MHz
    parameter baudrate = 115200
)
(
    input clk,
    input rst,
    input data_in,
    output reg done,
    output [7:0] data_out
    );

localparam CLKS_PER_BIT = clk_freq/baudrate;
localparam IDLE_st = 2'd0;
localparam START_st = 2'd1;
localparam DATA_st = 2'd2;
localparam STOP_st = 2'd3;

reg [1:0] state = IDLE_st;
reg [$clog2(CLKS_PER_BIT):0] count = 0;
reg [7:0] data = 0;
reg [2:0] index;
reg rx_ff,rx;

//2 FF synchronizer to ensure METASTABILITY
always @(posedge clk) begin
        rx_ff <= data_in;
        rx <= rx_ff;
 end
 
 //fsm
 always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= IDLE_st;
        count <= 0;
        done <= 0;
        index <= 0;
        data <= 0;
     end
     else begin
        done <= 0;
        case(state)
            IDLE_st: begin
                count <= 0;
                done <= 0;
                index <= 0;
                if(!rx) state <= START_st;
                else state <= IDLE_st;
            end
            
            START_st: begin
                if(count == (CLKS_PER_BIT-1)/2)                 // sampling at middle of bit time
                    if(!rx) begin                               // to confirm the start bit is low, not glitch
                            count <= 0;
                            state <= DATA_st;
                        end
                    else state <= IDLE_st;                      // if glitch
                 else count <= count + 1;
            end
            
            DATA_st: begin
                 if (count == CLKS_PER_BIT-1) begin
                    count <= 0;
                    data[index] <= rx;                          // receives at mid of each bit clk 
                    if (index < 7) index <= index + 1;
                    else state <= STOP_st;                      // after all bit is received
                 end
                 else count <= count + 1;
            end 
            
            STOP_st: begin
                if(count < CLKS_PER_BIT-1) count <= count + 1;
                else begin
                    done <= 1;
                    state <= IDLE_st;
                end
            end
            
            default: 
                state <= IDLE_st;
            endcase
        end 
 end

assign data_out = data;
endmodule
