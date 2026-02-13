`timescale 1ns/1ps
module arbiter #(parameter N = 128) (
  input in,reset,[N-1:0]sel,
  output out
);
  wire [N-1:0] m;
  wire [N-1:0] n;

  mux_block block0 (in,~in,sel[0],m[0],n[0]);

  generate
    genvar i;
    for (i = 0; i < N - 1; i = i + 1) begin: mux_block
      mux_block block(
        m[i],
        n[i],
        sel[i],
        m[i+1],
        n[i+1]
      );
    end
  endgenerate
  d_latch sr(n[N-1],m[N-1],reset,out);

endmodule  

module d_latch(
  input d_in, clk, reset,
  output reg q_out
);
  always @( posedge clk or posedge reset) begin
    if(reset)
      q_out <= 1'b0;
    else if (!reset)
      q_out <= d_in;
  end
endmodule

module mux_block(
  input in_up,in_down,sel,
  output out_up,out_down
);
  
  mux2x1 #0.1 mux_up(in_up,in_down,sel,out_up);
  mux2x1 #0.2 mux_down(in_down,in_up,sel,out_down);
  
endmodule

module mux2x1(
  input in_0, in_1,sel,
  output out
);
  assign out = sel ? in_1 : in_0;
endmodule
