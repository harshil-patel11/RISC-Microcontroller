// Top level module that contains the CPU, controller, regfile, and datapath.
module lab8_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
  
  // Macros for memory states
  `define MNONE 2'b00
  `define MREAD 2'b01
  `define MWRITE 2'b10 

  input CLOCK_50;
  input [3:0] KEY;
  input [9:0] SW;
  output [9:0] LEDR;
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

  wire clk = CLOCK_50; // Assign clk to the complement of KEY[0]
  wire reset = ~KEY[1]; // Assign reset to the complement of KEY[1]
  wire [15:0] in; 

  wire N, V, Z, w;
  wire msel, mem_read, mem_write, write;
  wire [1:0] mem_cmd;
  wire [7:0] read_address, write_address;
  wire [8:0] mem_addr, PC;
  wire [9:0] LEDR;
  wire [15:0] write_data, out, dout, read_data;

  // Module instantiation for the CPU module.
  cpu CPU(.clk(clk),
          .reset(reset),
          .read_data(read_data),
          .out(out),
          .N(N),
          .V(V),
          .Z(Z),
          .w(w),
          .mem_cmd(mem_cmd),
          .mem_addr(mem_addr),        
          .PC(PC));

  
  // Module instantiation for Read Write Memory - Adapted from SS7        
  RAM #(16, 8, "data.txt") MEM (.clk(clk),
                    .read_address(mem_addr[7:0]),
                    .write_address(mem_addr[7:0]),
                    .write(write),
                    .din(write_data),   //use out instead of write_data
                    .dout(dout)); 

  memoryIO #(8) IO (.clk(clk),
                    .mem_addr(mem_addr),
                    .mem_cmd(mem_cmd),
                    .read_data(read_data),
                    .write_data(write_data),
                    .SW(SW[7:0]),
                    .LEDR(LEDR[7:0]));

  read_writeRAM RW (.clk(clk),
                    .mem_addr(mem_addr),
                    .mem_cmd(mem_cmd),
                    .read_data(read_data),
                    .datapath_out(out),
                    .write_data(write_data),
                    .dout(dout),
                    .read_address(read_address),
                    .write_address(write_address),
                    .write(write));              

  sseg hex0(.in(write_data[3:0]), .segs(HEX0)); // Module instantiation for sseg display for HEX0.
  sseg hex1(.in(write_data[7:4]), .segs(HEX1)); // Module instantiation for sseg display for HEX1.
  sseg hex2(.in(write_data[11:8]), .segs(HEX2)); // Module instantiation for sseg display for HEX2.
  sseg hex3(.in(write_data[15:12]), .segs(HEX3)); // Module instantiation for sseg display for HEX3.

  sseg hex4(.in(PC[3:0]), .segs(HEX4)); // HEX4 displays first 4 bits of PC
  sseg hex5(.in(PC[7:4]), .segs(HEX5)); // HEX4 displays next 4 bits of PC

  //lab 8 mods
  assign LEDR[8] = w; // Assign LED[8] to w

endmodule


// Module for the HEX displays
module sseg(in, segs);
  input [3:0] in;
  output [6:0] segs;

  reg[6:0] segs;

  // Always block to select cases for each number of HEX; from 0 to F
  always@* begin
    case(in) 
      4'd0: segs = 7'b100_000_0;
      4'd1: segs = 7'b111_100_1;
      4'd2: segs = 7'b010_010_0;
      4'd3: segs = 7'b011_000_0;
      4'd4: segs = 7'b001_100_1;
      4'd5: segs = 7'b001_001_0;
      4'd6: segs = 7'b000_001_0;
      4'd7: segs = 7'b111_100_0;
      4'd8: segs = 7'b000_000_0;
      4'd9: segs = 7'b001_100_0;
      4'd10: segs = 7'b000_100_0;
      4'd11: segs = 7'b000_001_1;
      4'd12: segs = 7'b100_011_0;
      4'd13: segs = 7'b010_000_1;
      4'd14: segs = 7'b000_011_0;
      4'd15: segs = 7'b000_111_0;
      default: segs = 7'b111_1111; // Set default to all off.
    endcase
  end
endmodule


module memoryIO (clk,mem_addr,mem_cmd,read_data,write_data,SW,LEDR);

  parameter n;

  input clk;
  input [7:0] SW;
  input [8:0] mem_addr;
  input [1:0] mem_cmd;
  output [15:0] read_data;

  input [15:0] write_data;
  output [n-1:0] LEDR;

  wire [n-1:0] LEDR_in;
  reg [15:0] read_data;

  always @(*)
    case({mem_addr, mem_cmd})
      {9'h140,`MREAD}: read_data = {{8{1'b0}}, SW};
      default: read_data = {16{1'bz}};
  endcase  

  assign LEDR_in = ((mem_addr == 9'h100) & (mem_cmd ==`MWRITE)) ? write_data[n-1:0] : {n{1'b0}};
  vDFFE #(8) LED(.clk(clk), .en((mem_addr == 9'h100) & (mem_cmd == `MWRITE)), .in(LEDR_in), .out(LEDR));
endmodule


module read_writeRAM(mem_addr, mem_cmd, read_data, datapath_out, write_data, dout, clk, read_address, write_address, write);

  input [8:0] mem_addr;
  input [15:0] dout, datapath_out;
  input clk;
  input [1:0] mem_cmd;
  output [15:0] read_data, write_data;
  output [7:0] read_address, write_address;
  output write;

  wire read_condition1 = (mem_cmd == `MREAD) ? 1 : 0;
  wire read_condition2 =  (mem_addr[8] == 0) ? 1 : 0;

  wire write_condition1 = (mem_cmd == `MWRITE) ? 1 : 0;
  wire write_condition2 =  (mem_addr[8] == 0) ? 1 : 0;

  assign write_address = mem_addr[7:0];
  assign read_address = mem_addr[7:0];

  assign write = write_condition1 & write_condition2;

  assign write_data = datapath_out;
  wire READ = read_condition1 & read_condition2;
  assign read_data = (READ == 1) ? dout: {16{1'bz}};
endmodule