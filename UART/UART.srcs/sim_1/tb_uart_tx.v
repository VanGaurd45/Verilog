`timescale 1ns / 1ps

module tb_UART_tx;
    parameter CLK_PERIOD   = 10;                                            // 1/clk_freq, here 10MHz
    parameter CLKS_PER_BIT = 87;                                            //  baudrate = 115200

    reg clk;
    reg rst;
    reg [7:0] data_in;
    reg avail;

    wire tx;
    wire done;
    wire busy;

    UART_tx dut (clk,rst,data_in,avail,tx,done,busy);

    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            data_in = data;
            avail   = 1'b1;

            @(posedge clk);
            avail   = 1'b0;
        end
    endtask

    initial begin
        clk = 0;rst = 0;data_in = 0;avail = 0;
        #100;rst = 1;
        #50;
        send_byte(8'hA7);   // 1010_0101
        wait(done == 1);    
        #100 $finish;
    end
always #(CLK_PERIOD) clk = ~clk;
endmodule
