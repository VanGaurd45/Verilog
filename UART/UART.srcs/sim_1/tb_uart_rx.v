`timescale 1ns / 1ps

module UART_Rx_tb;

    parameter CLKS_PER_BIT = 87;                            
    parameter CLK_PERIOD   = 10;                         // 1/clk_freq

    reg clk;
    reg rst;
    reg data_in;

    wire done;
    wire [7:0] data_out;

    UART_Rx dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .done(done),
        .data_out(data_out)
    );

    task uart_send_byte(input [7:0] byte);
        integer i;
        begin
            data_in = 0;                                 // start_bit
            #(CLKS_PER_BIT * CLK_PERIOD);
            
            for (i = 0; i < 8; i = i + 1) begin
                data_in = byte[i];                       // data bit
                #(CLKS_PER_BIT * CLK_PERIOD);
            end
            
            data_in = 1;                                 // stop bit
            #(CLKS_PER_BIT * CLK_PERIOD);
        end
    endtask

    initial begin
        clk = 0;rst = 0;data_in = 1;
        #(CLK_PERIOD/2); rst = 1;
        #(3 * CLK_PERIOD) uart_send_byte(8'hA7);
        #(5 * CLKS_PER_BIT * CLK_PERIOD) $finish;
    end    

    always #(CLK_PERIOD/2) clk = ~clk;
endmodule
