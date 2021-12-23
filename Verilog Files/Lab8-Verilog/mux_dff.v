// A module for a 2 input multiplexer with select signal sb
// Some parts adapted from Slideset 5
module Mux2 (a0, a1, sb, b);
  parameter k; 
  input [k-1:0] a0, a1;
  input sb;  //binary select
  output [k-1:0] b;

  reg [k-1:0] b; // Declare output b as a reg for use in the always block.
  
  always @* begin // Always block to check for cases of select signal sb.
    case(sb) 
      1'b0: b = a0; //output a0 for s with 0 at bit position 0.
      1'b1: b = a1; //output a1 for s with 1 at bit position 0.
      default: b = {k{1'bx}}; // default case set b to xxxx_xxxx_xxxx_xxxx to help in debugging.
    endcase
  end  
endmodule


// Module for a 3 input k-bit one-hot select multiplexer.
module Mux3 (a0, a1, a2, s, b);
  parameter k; 
  input [k-1:0] a0, a1, a2;
  input [2:0] s;  //one-hot select
  output [k-1:0] b;

  reg [k-1:0] b; // Declare output b as a reg for use in the always block.
  
  always @* begin // Always block to check for cases of select signal sb.
    case(s) 
      3'b001: b = a0; 
      3'b010: b = a1; 
      3'b100: b = a2; 
      default: b = {k{1'bx}}; // default case set b to xxxx_xxxx_xxxx_xxxx to help in debugging.
    endcase
  end  
endmodule


module Mux4 (a0, a1, a2, a3, s, b);
  parameter k; 
  input [k-1:0] a0, a1, a2, a3;
  input [3:0] s;  //one-hot select
  output [k-1:0] b;

  reg [k-1:0] b; // Declare output b as a reg for use in the always block.
  
  always @* begin // Always block to check for cases of select signal sb.
    case(s) 
      4'b0001: b = a0; 
      4'b0010: b = a1; 
      4'b0100: b = a2; 
      4'b1000: b = a3; 
      default: b = {k{1'bx}}; // default case set b to xxxx_xxxx_xxxx_xxxx to help in debugging.
    endcase
  end  
endmodule


// A module for a multiplexer that takes in 8 (16 bit) inputs and selects one based on the s value.
// Adapted from 3 input mux code from SS6 (Slide 21).
module Mux8 (a0, a1, a2, a3, a4, a5, a6, a7, s, b);
  parameter k; 
  input [k-1:0] a0, a1, a2, a3, a4, a5, a6, a7;
  input [7:0] s;  //one-hot select
  output [k-1:0] b;

  reg [k-1:0] b; // declared output b as reg as it is used with an always block.
  
  always @* begin 
    case(s) 
      8'b0000_0001: b = a0; //output a0 for s with 1 at bit position 0.
      8'b0000_0010: b = a1; //output a1 for s with 1 at bit position 1.
      8'b0000_0100: b = a2; //output a2 for s with 1 at bit position 2.
      8'b0000_1000: b = a3; //output a3 for s with 1 at bit position 3.
      8'b0001_0000: b = a4; //output a4 for s with 1 at bit position 4.
      8'b0010_0000: b = a5; //output a5 for s with 1 at bit position 5.
      8'b0100_0000: b = a6; //output a6 for s with 1 at bit position 6. 
      8'b1000_0000: b = a7; //output a7 for s with 1 at bit position 7.
      default: b = {k{1'bx}}; // default case set b to xxxx_xxxx_xxxx_xxxx to help in debugging.
    endcase
  end  
endmodule


// A module for a register with load enable.
// Adapted from slideset - Lab 5 intro.
module vDFFE (clk, en, in, out);
  parameter n;
  input clk, en;
  input [n-1:0] in;
  output [n-1:0] out;
  
  reg [n-1:0] out;
  wire [n-1:0] next_out;

// assigns in to next_out if en is 1, otherwise assigns out.
  assign next_out = en ? in : out;

// Copies out to next_out at every positive
  always @(posedge clk)
    out = next_out;
endmodule


module vDFFE_PN (clk, en, in, out);
  parameter n;
  input clk, en;
  input [n-1:0] in;
  output [n-1:0] out;
  
  reg [n-1:0] out;
  wire [n-1:0] next_out;

// assigns in to next_out if en is 1, otherwise assigns out.
  assign next_out = en ? in : out;

// Copies out to next_out at every positive
  always @(negedge clk)
    out = next_out;
endmodule


module vDFF(clk, in, out);
  parameter n=1;
  input clk;
  input [n-1:0] in;
  output [n-1:0] out;
  reg [n-1:0] out;
  always @(posedge clk)
    out <= in;
endmodule