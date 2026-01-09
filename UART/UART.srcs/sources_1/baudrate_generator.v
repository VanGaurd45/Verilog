`timescale 1ns/1ps

module baudrate_generator
#(
parameter cycle_tx = 5208,
  parameter cycle_rx = 325,
  parameter length_tx = 13,
  parameter length_rx = 10)
  
(input clk,input reset,output tx_en, output rx_en);
	
  
  reg [length_tx-1:0] count_tx;
  reg [length_rx-1:0] count_rx;
  
  always @(posedge clk or negedge reset) begin
    if(!reset)
      	count_tx <= 0;
  else
    count_tx <= (count_tx == cycle_tx-1) ? 0 : count_tx + 1;
  end
  
  always @(posedge clk or negedge reset) begin
    if(!reset)
      	count_rx <= 0;
  else
    count_rx <= (count_rx == cycle_rx-1) ? 0 : count_rx + 1;
  end
  
  assign tx_en = (count_tx == 0) ? 1 : 0;
  assign rx_en = (count_rx == 0) ? 1 : 0;
  
endmodule