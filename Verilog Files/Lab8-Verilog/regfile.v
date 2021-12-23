// Regfile module that handles writing and reading from 8 different registers.
module regfile(data_in, writenum, write, readnum, clk, data_out);

  input [15:0] data_in; //16 bit input
  input [2:0] writenum, readnum; // 3 bit input for reading/writing number from one of eight registers.
  input write, clk; //1 bit input for write, 1 bit input for clk
  output [15:0] data_out; //16 bit output copied from the correct register

  wire [7:0] decoder1_out, decoder2_out; // 8 bit outputs from each of the 2 (3:8) decoders
  wire [7:0] load; // 8 bit bus where each wire [i] is the load input for register R[i]
  wire clk; // clk to make changes at rising edge.
  wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7; // 8 16 bit registers
  wire [15:0] data_out; // wire of data_out to allow to output in a module instantiation.
 
  Dec #(3, 8) decoder1 (writenum, decoder1_out); //Instantiate a (3:8) decoder used to write a number to a specific register.

  assign load = {8{write}} & decoder1_out; // Creating 8 copies of 1 bit write input and ANDing them with each wire of decoder1_out.

  vDFFE #(16) register0 (clk, load[0], data_in, R0); // Instantiating register 0 that takes input from load[0] and outputs into wire R0.
  vDFFE #(16) register1 (clk, load[1], data_in, R1); // Instantiating register 1 that takes input from load[1] and outputs into wire R1.
  vDFFE #(16) register2 (clk, load[2], data_in, R2); // Instantiating register 2 that takes input from load[2] and outputs into wire R2.
  vDFFE #(16) register3 (clk, load[3], data_in, R3); // Instantiating register 3 that takes input from load[3] and outputs into wire R3.
  vDFFE #(16) register4 (clk, load[4], data_in, R4); // Instantiating register 4 that takes input from load[4] and outputs into wire R4.
  vDFFE #(16) register5 (clk, load[5], data_in, R5); // Instantiating register 5 that takes input from load[5] and outputs into wire R5.
  vDFFE #(16) register6 (clk, load[6], data_in, R6); // Instantiating register 6 that takes input from load[6] and outputs into wire R6.
  vDFFE #(16) register7 (clk, load[7], data_in, R7); // Instantiating register 7 that takes input from load[7] and outputs into wire R7.

  Dec #(3, 8) decoder2 (readnum, decoder2_out); //Instantiate a (3:8) decoder used to read a number from a specific register.

  Mux8 #(16) reg_mux (R0, R1, R2, R3, R4, R5, R6, R7, decoder2_out, data_out); // Instantiating a multiplexer that picks an output (register) based on a one hot-code.

endmodule



//A module for a 3:8 decoder.
// Adapted from slide 8 of slideset 6.
module Dec(a, b);
  parameter n;
  parameter m;

  input [n-1:0] a;
  output [m-1:0] b;

  wire [m-1:0] b = 1 << a; //shifts 1 to the left by a bit positions.
  
endmodule

