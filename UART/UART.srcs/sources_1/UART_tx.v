`timescale 1ns / 1ps

module UART_tx
#(
    parameter clk_freq = 10000000,                                          //10MHz CLOCK
    parameter baudrate = 115200
)
(   input clk,
    input reset,
    input [7:0] data_in,                                                    // parallel data
    input avail,                                                            // start bit is available 
    output reg tx,                                                          // serial data
    output reg done,                                                        // denotes transmission is done
    output reg busy                                                         // denotes transmission in ON
    );
 
localparam CLKS_PER_BIT = clk_freq/baudrate;
localparam IDLE_st = 2'd0;
localparam START_st = 2'd1;
localparam DATA_st = 2'd2;
localparam STOP_st = 2'd3;
  
reg [7:0] data;
reg [$clog2(CLKS_PER_BIT):0] count;
reg [1:0] state;
reg [3:0] index;

always @(posedge clk or negedge reset) begin 
    if(!reset) begin 
        state <= IDLE_st;
        data <= 0;
        count <= 0;
        index <= 0;
        done <= 0;
        busy <= 0;
        tx <= 1;
    end
    
    else begin
        done <= 0;
        case (state)
            IDLE_st: begin                                                  //waits for start_bit
                count <= 0;
                index <= 0;
                tx <= 1;
                if(avail) begin
                    busy <= 1;
                    data <= data_in;
                    state <= START_st;
                end
                else busy <= 0;
             end 
             
             START_st: begin                                                //waits for the entire start bit to go
                if (count == 0) tx <= 0;
                if(count < CLKS_PER_BIT-1) count <= count + 1;
                else begin 
                    count <= 0;
                    state <= DATA_st;
                end
             end
               
             DATA_st: begin
                if (count == 0) tx <= data[index];                          // transmit data 
                if(count < CLKS_PER_BIT-1) count <= count + 1;              //wait for 1 bit time
                else begin
                    count <= 0;
                    if(index < 7) index <= index + 1;                       // counts no of bit transmitted
                    else begin
                        index <= 0;
                        state <= STOP_st;
                    end
                end
             end
             
             STOP_st: begin
                if(count == 0)  tx <= 1;                                    // transmit stop_bit
                if(count < CLKS_PER_BIT - 1) count <= count + 1;            // wait for 1 bit time
                else begin
                    done <= 1;
                    busy <= 0;
                    state <= IDLE_st;
                end
             end
             
             default: 
                state <= IDLE_st;
            
        endcase
    end
end

endmodule
