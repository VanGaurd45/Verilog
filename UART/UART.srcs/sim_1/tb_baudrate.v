`timescale 1ns/1ps

module tb_baudrate_generator;

  reg clk;
  reg reset;
  wire tx_en;
  wire rx_en;

  // -------- DUT instantiation --------
  baudrate_generator dut (
    .clk   (clk),
    .reset (reset),
    .tx_en (tx_en),
    .rx_en (rx_en)
  );

  // -------- Clock generation (10 ns period) --------
  initial begin
    clk = 0;
    forever #3 clk = ~clk;
  end

  // -------- Reset sequence --------
  initial begin
    reset = 0;
    #5;
    reset = 1;
  end

  // -------- Monitor outputs --------
  initial begin
    $monitor("Time=%0t | reset=%b | tx_en=%b | rx_en=%b",
              $time, reset, tx_en, rx_en);
  end


endmodule
