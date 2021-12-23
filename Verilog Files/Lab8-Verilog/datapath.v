// Module for datapath that contains regfile, alu, shifter and all other combinational building blocks.
module datapath(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, sximm8, sximm5, mdata, PC, ZVN_out, datapath_out);

  input clk, loada, loadb, asel, bsel, loadc, loads, write;
  input [1:0] shift, ALUop;
  input [2:0] readnum, writenum; 
  input [3:0] vsel;
  input [8:0] PC;
  input [15:0] sximm8, sximm5, mdata;
  output [2:0] ZVN_out;
  output [15:0] datapath_out;

  wire [15:0] data_in, data_out; 
  wire [15:0] aout, bout; 
  wire [15:0] Ain, Bin, sout;
  wire [15:0] out;
  wire [15:0] sximm8, sximm5;
  wire [15:0] mdata;
  wire [8:0] PC;
  wire [2:0] ZVN;
  wire clk, loada, loadb, asel, bsel, loadc, loads, write;

  //Module instantiation for Mux2 (2 input multiplexer).
  Mux4 #(16) vsel_mux(.a3(mdata), 
                      .a2(sximm8),
                      .a1({7'b0, PC}),
                      .a0(datapath_out),
                      .s(vsel), 
                      .b(data_in));
  
  //Module instantiation for regfile.
  regfile REGFILE(.data_in(data_in), 
                  .writenum(writenum), 
                  .write(write), 
                  .readnum(readnum), 
                  .clk(clk), 
                  .data_out(data_out));
  
  //Module instantiation for Register with load enable (for Register A).
  vDFFE #(16) A(.clk(clk), 
                .en(loada), 
                .in(data_out),
                .out(aout));

  //Module instantiation for Register with load enable (for Register B).
  vDFFE #(16) B(.clk(clk), 
                .en(loadb), 
                .in(data_out),
                .out(bout));   
  
  //Module instantiation for 2 input multiplexer for asel.
  Mux2 #(16) asel_mux(.a0(aout),
                      .a1(16'b0),
                      .sb(asel),
                      .b(Ain));

  //Module instantiation for shifter (instance name U1).
  shifter shifter_U1(.in(bout),
                     .shift(shift),
                     .sout(sout));
  
  //Module instantiation for 2 input multiplexer for bsel
  Mux2 #(16) bsel_mux(.a0(sout),
                      .a1(sximm5),
                      .sb(bsel),
                      .b(Bin));    
  
  //Module instantiation for the ALU (instance name U2).
  ALU ALU_U2(.Ain(Ain),
             .Bin(Bin),
             .ALUop(ALUop),
             .out(out),
             .ZVN(ZVN));    
  
  //Module instantiation for Register with load enable (for Register C).
  vDFFE #(16) C(.clk(clk),
                .en(loadc),
                .in(out),
                .out(datapath_out));   

  //Module instantiation for Register with load enable for status register.
  vDFFE #(3) status(.clk(clk),
                    .en(loads),
                    .in(ZVN),
                    .out(ZVN_out));  
                                                                                                          
endmodule


