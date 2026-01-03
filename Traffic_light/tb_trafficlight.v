`timescale 1ns / 1ps

module tb_trafficlight();

parameter RED=2'b00;
parameter YELLOW=2'b01;
parameter GREEN=2'b10;

reg clk,sensor,reset;
wire [1:0] hwy,cntry;

traffic_light dut (clk,sensor,reset,hwy,cntry);

initial begin   
    clk=0;reset=0;sensor=0;
    #20 reset=1; sensor=0;
    #40 sensor=1;
    #20 sensor=0;
    #60 sensor=1;
    #40 sensor=0;
    #50 $finish;
end
always #5 clk=~clk;
endmodule
