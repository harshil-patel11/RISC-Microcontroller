module cpu(clk, reset, read_data, out, N, V, Z, w, mem_cmd, mem_addr, PC); //CPU module containing a FSM controller, an instruction decoder, and a datapath

  input clk, reset;
  input [15:0] read_data;
  output [15:0] out;
  output N, V, Z, w; 
  output [1:0] mem_cmd;
  output [8:0] mem_addr, PC;

  wire clk, reset, load;
  wire [15:0] in, out;
  wire N, V, Z, w;

  wire [15:0] instruction_register_out, sximm8, sximm5;
  reg [8:0] pc_increment;
  wire [8:0] choose_pc_plus;
  wire [3:0] vsel;
  wire [2:0] nsel, opcode, readnum, writenum, ZVN_out, cond;
  wire [1:0] op, ALUop, shift, mem_cmd;
  wire loada, loadb, loadc, loads, asel, bsel, write, reset_pc, load_pc, addr_sel, load_addr, load_ir, load_sximm8, pc_plus;

  wire [8:0] pc_in, next_pc, PC, mem_addr, data_addr_out;
  wire [15:0] read_data, mdata;
  wire select_pc;
  
  // Register with load enable instantiation for the instruction register.
  vDFFE #(16) instruction_register (.clk(clk), .en(load_ir), .in(read_data), .out(instruction_register_out));
  
  // Module instantiation for instruction decoder needed to decode the output from the instruction register.
  instruction_decoder instr_dec(.in(instruction_register_out),
                                .nsel(nsel),
                                .opcode(opcode),
                                .op(op),
                                .ALUop(ALUop),
                                .shift(shift),
                                .readnum(readnum),
                                .writenum(writenum),
                                .sximm8(sximm8),
                                .sximm5(sximm5),
                                .cond(cond));

  // Module instantiation for the controller for the state machine to control the datapath.  
  FSMController FSM ( .clk(clk),
                      .reset(reset),
                      .op(op),
                      .opcode(opcode),
                      .cond(cond),
                      .loada(loada),
                      .loadb(loadb),
                      .loadc(loadc),
                      .loads(loads),
                      .write(write),
                      .asel(asel),
                      .bsel(bsel),
                      .nsel(nsel),
                      .vsel(vsel),
                      .reset_pc(reset_pc),
                      .load_pc(load_pc),
                      .addr_sel(addr_sel),
                      .load_addr(load_addr),
                      .load_ir(load_ir),
                      .load_sximm8(load_sximm8),
                      .pc_plus(pc_plus),
                      .mem_cmd(mem_cmd),
                      .select_pc(select_pc),
                      .w(w));                              

  // Module instantiation for the datapath module.
  datapath DP ( .clk(clk),
                .readnum(readnum),
                .writenum(writenum),
                .write(write),
                .vsel(vsel),
                .loada(loada),
                .loadb(loadb),
                .loadc(loadc),
                .loads(loads),
                .shift(shift),
                .ALUop(ALUop),
                .asel(asel),
                .bsel(bsel),
                .sximm8(sximm8),
                .sximm5(sximm5),
                .mdata(mdata),
                .PC(choose_pc_plus),
                .datapath_out(out),    
                .ZVN_out(ZVN_out));                

  assign mdata = read_data; // assign the read_data from the RAM as an input wire mdata to the datapath.           

  // vDFFE_PN #(1) regZ(.clk(clk), .en(), .in(ZVN_out[2]), .out(Z));  
  // vDFFE_PN #(1) regV(.clk(clk), .en(), .in(ZVN_out[1]), .out(V));  
  // vDFFE_PN #(1) regN(.clk(clk), .en(), .in(ZVN_out[0]), .out(N));        

  assign Z = ZVN_out[2]; // Assign the second bit of ZVN_out to Z which makes it 1 if the output of datapath is 0.           
  assign V = ZVN_out[1]; // Assign the first bit of ZVN_out to V which makes it 1 if there is an overflow.
  assign N = ZVN_out[0]; // Assign the zeroth bit of ZVN_out to N which makes it 1 if there is a negative result.

  // Program Counter
  // Counter #(9) pc_incrementer (.clk(clk), .load_pc(load_pc), .rst(reset_pc), .out(pc_in)); //  Module instantiation for the increment by 1 module.
  // vDFFE #(8) pc_sximm8_select(.clk(clk), .en(load_sximm8), .in(sximm8[7:0]), .out(sximm8_out));

  // assign pc_increment = load_sximm8 ? PC + 1'b1 + sximm8[7:0] : PC + 1'b1;  //load_sximm8 comes out of FSM
  // assign pc_increment = PC + 1'b1; 

  // Data Address
  // for lab 8, we replaced write_data with out (they mean the same thing)
  //vDFFE #(9) data_address_register (.clk(clk), .en(load_addr), .in(write_data[8:0]), .out(data_addr_out));

  vDFFE #(9) data_address_register (.clk(clk), .en(load_addr), .in(out[8:0]), .out(data_addr_out));
  Mux2 #(9) addr_mux (.a0(data_addr_out), .a1(PC), .sb(addr_sel), .b(mem_addr)); // Module instantiation for the data address multiplexer. 

  // Program Counter lab 8 mod
  // Always block for deciding PC value.
  always @* begin
    if (load_sximm8 == 1'b1) begin //If load_sximm8 is high.
      casex({cond, opcode, op}) // Decide pc_increment based on concatenation of given inputs.
        {3'b000, 3'bxxx, 2'bxx}:  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0]; 
        
        {3'b001, 3'bxxx, 2'bxx}: if (Z == 1'b1) // Condition for BEQ
                                  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0];
                                else
                                  pc_increment = PC + 9'b0000_0000_1; 

        {3'b010, 3'bxxx, 2'bxx}: if (Z == 1'b0) // Condition for BNE
                                  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0];
                                else
                                  pc_increment = PC + 9'b0000_0000_1; 

        {3'b011, 3'bxxx, 2'bxx}: if (N !== V) // Condition for BLT
                                  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0];
                                else
                                  pc_increment = PC + 9'b0000_0000_1; 

        {3'b100, 3'bxxx, 2'bxx}: if (N !== V | Z == 1'b1) // Condition for BLE
                                  pc_increment = PC + 1'b1 + sximm8[8:0];
                                else
                                  pc_increment = PC + 9'b0000_0000_1;   
        // Set default as shown
        {3'bxxx, 3'b010, 2'b11}:  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0];                                              

        default: pc_increment = PC + 9'b0000_0000_1;            
      endcase
    end else begin
      pc_increment = PC + 9'b0000_0000_1; // Otherwise, add 1
    end
  end    

  // always @* begin
  //   if (load_sximm8 == 1'b1) begin
  //     case({opcode, op})
  //       {3'b010, 2'b11}:  pc_increment = PC + 9'b0000_0000_1 + sximm8[8:0];    
  //       default: pc_increment = PC + 9'b0000_0000_1;            
  //     endcase
  //   end else begin
  //     pc_increment = PC + 9'b0000_0000_1;
  //   end
  // end   


  wire [8:0] pc_increment_sximm8;
  vDFFE #(9) pc_increment_reg(.clk(clk), .en(load_sximm8), .in(pc_increment), .out(pc_increment_sximm8));
  wire [8:0] new_pc = select_pc ? pc_increment_sximm8 : pc_increment;
  wire [8:0] pc_rd = (opcode == 3'b010) && (op == 2'b00 || op == 2'b10) ? out : new_pc;

  Mux2 #(9) pc_mux (.a0(pc_rd), .a1({9{1'b0}}), .sb(reset_pc), .b(next_pc)); // Module instantiation for the pc multiplexer.
  vDFFE #(9) pc_register (.clk(clk), .en(load_pc), .in(next_pc), .out(PC)); // Module instantiation for the pc register with load enable.

  // Mux2 #(9) pc_mux (.a0(pc_increment), .a1({9{1'b0}}), .sb(reset_pc), .b(next_pc)); // Module instantiation for the pc multiplexer.
  // vDFFE #(9) pc_register (.clk(clk), .en(load_pc), .in(next_pc), .out(PC)); // Module instantiation for the pc register with load enable.
  
  //vDFF #(1) branch_reg(.clk(clk), .in(branch_out), .out(branch_in));

  // Assign choose_pc_plus to PC+1 if pc_plus is 1, else no change.
  assign choose_pc_plus = pc_plus ? PC + 9'b0000_0000_1 : PC;

  
endmodule



//Instruction Decoder module decodes a 16 bit 
module instruction_decoder (in, nsel, opcode, op, ALUop, shift, readnum, writenum, sximm8, sximm5, cond);

  input [15:0] in;
  input [2:0] nsel;
  output [1:0] op, ALUop, shift;
  output [2:0] opcode, readnum, writenum, cond;
  output [15:0] sximm8, sximm5;  

  wire [1:0] shift;

  //wire [1:0] shift = in[4:3];

  wire [2:0] Rn = in[10:8];
  wire [2:0] Rd = in[7:5];
  wire [2:0] Rm = in[2:0];

  wire [2:0] mux_out; 
  wire [2:0] readnum, writenum;
  
  //3 input one hot select mux for selecting between Rn, Rd, and Rm
  Mux3 #(3) nsel_mux (.a0(Rm), .a1(Rd), .a2(Rn), .s(nsel), .b(mux_out));  
  
  assign readnum = mux_out;   // assign the output of the nsel_mux to readnum
  assign writenum = mux_out;  // assign the output of the nsel_mux to writenum also
  
  //wire [1:0] shift = in[4:3]; // assign bits 4:3 of in to bits 1:0 of shift
  wire [7:0] imm8 = in[7:0];  // assign bits 7:0 of in to bits 7:0 of imm8
  wire [4:0] imm5 = in[4:0];  // assign bits 4:0 of in to bits 4:0
  
  wire [15:0] sximm8 = {{8{imm8[7]}}, imm8};  // sign extend bit 7 of imm8 to 16 bits
  wire [15:0] sximm5 = {{11{imm5[4]}}, imm5}; // sign extend bit 5 of imm5 to 16 bits

  wire [1:0] ALUop = in[12:11];   // assign bits 12:11 of in to bits 1:0 of ALUop
  wire [1:0] op = in[12:11];      // assign bits 12:11 of in to bits 1:0 of op
  wire [2:0] opcode = in[15:13];  // assign bits 15:13 of in to bits 2:0 of opcode

  assign shift = (opcode == 3'b100) & (op == 2'b00) ? 2'b00 : in[4:3]; 
  //do for ldr also

  //lab 8 extension
  wire [2:0] cond = in[10:8];

endmodule

// Module for Counter
module Counter (clk, load_pc, rst, out);
  parameter n;
  input rst, clk, load_pc;
  output [n-1:0] out;
  reg [n-1:0] next;

  vDFFE #(n) count(clk, load_pc, next, out); // Module instantiation for D-Flip-Flop

  //Always block to increment value of out if rst is 1.
  always @* begin
    case (rst)
    1'b1: next = 0; // If rst is 1, next is 0.
    1'b0: next = out + 1; // If rst is 0, next is out incremented by 1.
    default: next = {n{1'bx}}; // Set default to x to aid with debugging.
    endcase
  end
endmodule

// Module for Equality Comparator
module EqComp(a, b, eq);
  parameter k;
  input [k-1:0] a, b;
  output eq;
  wire eq;

  assign eq = (a==b); // Assign eq = 1 if a is equal to b (behavioral verilog for equality).
endmodule

// Module for Read-Write Memory from Slide-Set 7
module RAM(clk, read_address, write_address, write, din, dout);
  parameter data_width;
  parameter addr_width;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input [data_width-1:0] din;
  input write;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;
  
  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem); //Read the memory the file given.

  // Always block to write memory on the rising edge of the clock is write signal is 1.
  always @ (posedge clk) begin
    if (write) // Only if we need to write
      mem[write_address] <= din;
    dout <= mem[read_address]; //Copy the value of the memory at read_address.
  end

endmodule