module shifter(in, shift, sout); // Shifter module that performs the shift operations depending on the shift signal.

  input [15:0] in;
  input [1:0] shift;
  output [15:0] sout;

  reg [15:0] sout;
  wire temp_in;

  assign temp_in = in[15];  //assign the MSB of "in" to the "temp_in" wire. This is used for the fourth case in the always block.

  //Always block to check cases for "shifter" input
  always @* begin
    case (shift)
      2'b00: sout = in;       //if "shift" is 00, then don't shift. Assign "in" to "sout".
      2'b01: sout = in << 1;  //if "shift" is 01, then shift "in" to the left by 1 bit position and assign that value to "sout".
      2'b10: sout = in >> 1;  //if "shift" is 10, then shift "in" to the right by 1 bit position and assign that value to "sout".
      2'b11: begin
              sout = in >> 1; //if "shift" is 11, then shift "in" to the right by 1 bit position and assign that value to "sout".
              sout[15] = temp_in; //set the MSB of "sout" to the MSB of "in" before it was shifted.
            end
      default: sout = 16'bxxxx_xxxx_xxxx_xxxx;  //for the default case, set "sout" to 16'bxxxx_xxxx_xxxx_xxxx.
    endcase
  end

endmodule