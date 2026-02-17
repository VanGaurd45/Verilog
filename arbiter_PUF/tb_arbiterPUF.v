module tb_arbiter;
  parameter N = 128;
  reg in, reset;
  reg [N-1:0]sel;
  wire out;
  
  arbiter #(N) dut (in,sel,reset,out);

  initial begin
    in = 0;reset = 0; sel = 0;
    repeat (50) begin   
      #10; in = $random;    
      sel = $random;
    end
    #10; $finish;
  end
endmodule
