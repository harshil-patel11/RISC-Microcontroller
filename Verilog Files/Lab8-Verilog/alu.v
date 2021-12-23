module ALU(Ain, Bin, ALUop, out, ZVN); // ALU module that performs arithmetic operations depending on the ALUop signal.
  input [15:0] Ain, Bin;
  input [1:0] ALUop;
  output [15:0] out;
  output [2:0] ZVN;

  wire [1:0] ALUop;
  reg [15:0] out;
  wire [2:0] ZVN;
  wire ovf;
  
  //Always block to check cases of ALUop 
  always @* begin
    case (ALUop)
      2'b00: out = Ain + Bin; // if ALUop == 00, carry out add 
      2'b01: out = Ain - Bin; // if ALUop == 01, carry out subtract 
      2'b10: out = Ain & Bin; // if ALUop == 10, carry out and
      2'b11: out = ~Bin; // if ALUop == 11, carry out (not Bin)
      default: out = 16'bxxxx_xxxx_xxxx_xxxx; // set default to 16'bxxxx_xxxx_xxxx_xxxx to help with debugging
    endcase
  end
  
  overflow #(16) over_flow(.a(Ain),
                           .b(Bin),
                           .ALUop(ALUop),
                           .ovf(ovf));
  
  assign ZVN[2] = out == 0 ? 1'b1 : 1'b0; // Assign the second bit of ZVN to be 1 if output = 0, else 0.
  assign ZVN[1] = ovf; // "Inputs same sign, result different sign" (SS6 - slide 105)    
  assign ZVN[0] = out[15]; // Assign the zeroth bit of ZVN to be the MSB of out.

endmodule


//same as addSub in SS6
module overflow(a, b, ALUop, ovf);
  parameter n;
  input [n-1:0] a, b;
  input [1:0] ALUop;
  output ovf;
  wire c1, c2;
  reg sub;
  wire [n-1:0] s;
  
  wire ovf = c1 ^ c2;
  
  //assign sub to 1 or 0 depending on the ALUop instruction
  always @* begin
    case (ALUop)
      2'b01: sub = 1'b1;      
      default: sub = 1'b0;
    endcase
  end

  // add non sign bits
  Adder1 #(n-1) AI(a[n-2:0], b[n-2:0]^{n-1{sub}}, sub, c1, s[n-2:0]);
  // add sign bits2:
  Adder1 #(1) AS(a[n-1], b[n-1]^sub, c1, c2, s[n-1]);

endmodule


// Adder module to be instantiated in overflow module
module Adder1 (a, b, cin, cout, s);
  parameter n;
  input [n-1:0] a, b;
  input cin;
  output [n-1:0] s;
  output cout;
  wire [n-1:0] s;
  wire cout;
  
  assign {cout, s} = a + b + cin; // assign the concatenation of the sum and carry to cout, s.
endmodule