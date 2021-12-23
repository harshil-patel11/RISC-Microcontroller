// FSM controller module whose outputs are input signals of the datapath and can be used to control the datapath.
module FSMController (clk, opcode, op, reset, cond,
  loada, loadb, loadc, loads, vsel, nsel, asel, bsel, write, reset_pc, load_pc, addr_sel, load_ir, load_addr, load_sximm8, select_pc, pc_plus, mem_cmd, w);
  
  // Macro definitions for States
  `define SW 5
  `define RST 5'b00000
  `define DEC 5'b00001
  `define GET_A 5'b00010
  `define GET_B 5'b00011  
  `define ADD_OPSH 5'b00100 //OPSH means optional shift
  `define ADD_OPSH2 5'b11100
  `define CMP_OPSH 5'b00101
  `define AND_OPSH 5'b00110
  `define MVN_OPSH 5'b00111
  `define WRITE_IMM 5'b01000
  `define WRITE_REG 5'b01001
  `define IF1 5'b01010
  `define IF2 5'b01011
  `define UPDATE_PC 5'b01100
  `define DATA_ADDRESS 5'b01101 
  `define MEM 5'b01110 
  `define HALT 5'b01111 
  `define B 5'b10000
  `define BEQ 5'b10001
  `define BNE 5'b10010
  `define BLT 5'b10011
  `define BLE 5'b10100
  `define SEL_PC 5'b11111
  `define DATA_PROCESS 5'b10111
  
  // Macro definitions for nsel
  `define Rn 3'b100
  `define Rd 3'b010 
  `define Rm 3'b001 

  // Macro definitions for vsel
  `define C 4'b0001
  `define PC 4'b0010
  `define SXIMM8 4'b0100
  `define MDATA 4'b1000 

  // Macro definitions for asel, bsel, addr_sel
  `define ASEL 1'b0
  `define BSEL 1'b0 
  `define ADDR_SEL 1'b0

  // Macro definitions for load, write, reset_pc, w
  `define LA 1'b1
  `define LB 1'b1
  `define LC 1'b1
  `define LS 1'b1
  `define WRITE 1'b1  
  `define L_PC 1'b1
  `define L_SX 1'b1
  `define LOAD_IR 1'b1 
  `define L_ADDR 1'b1  
  `define RESET_PC 1'b1
  `define PC_PLUS 1'b1
  `define L_SPC 1'b1
  `define C_SPC 1'b1
  `define W 1'b1

  // Macros for memory states
  `define MNONE 2'b00
  `define MREAD 2'b01
  `define MWRITE 2'b10 

  //FSM inputs
  input clk, reset;
  input [1:0] op;
  input [2:0] opcode, cond;
  
  //FSM outputs
  output loada, loadb, loadc, loads, asel, bsel, write, reset_pc, load_pc, addr_sel, load_ir, load_addr, load_sximm8, select_pc, pc_plus, w;
  output [1:0] mem_cmd;
  output [2:0] nsel;
  output [3:0] vsel; 

  reg [30:0] next;  //a reg that has all outputs concatenated into a single variable
  reg temp_pc;
  wire temp_pc_out;
  wire choose_select_pc;
  wire load_select_pc;


  //The FSM below follows the slideset 5 and 7 good FSM code style

  wire [`SW-1:0] present_state, next_state_reset, next_state; 

  //Module instantiation for D - Flip-Flop
  vDFF #(`SW) STATE(.clk(clk), .in(next_state_reset), .out(present_state));
  assign next_state_reset = reset ? `RST : next_state; //Assign the reset state to next_state_reset if reset is set to 1

  always @(*) begin
    casex ({present_state, opcode, op, cond}) // Use the concatenation of present_state, s, opcode, op as state inputs.
      //Reset (RST) state: if reset is 1, enter this state.
      {`RST, 3'bxxx, 2'bxx, 3'bxxx}:          next = {`IF1, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, `RESET_PC, `L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // States: IF1 -> IF2 -> UPDATE_PC  
      {`IF1, 3'bxxx, 2'bxx, 3'bxxx}:          next = {`IF2, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC, `MREAD, ~`W};
      {`IF2, 3'bxxx, 2'bxx, 3'bxxx}:          next = {`DATA_PROCESS, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, `LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC, `MREAD, ~`W};  
      {`DATA_PROCESS, 3'b001, 2'b00, 3'bxxx}: next = {`DEC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC, `MNONE, ~`W};
      {`DATA_PROCESS, 3'b010, 2'bxx, 3'bxxx}: next = {`DEC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC, `MNONE, ~`W};
      {`DATA_PROCESS, 3'bxxx, 2'bxx, 3'bxxx}: next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC, `MNONE, ~`W};
      
      {`UPDATE_PC, 3'b001, 2'b00, 3'bxxx}:    next = {`IF1, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, `L_PC, `ADDR_SEL, `L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};  
      {`UPDATE_PC, 3'b010, 2'bxx, 3'bxxx}:    next = {`IF1, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, `L_PC, `ADDR_SEL, `L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};  
      {`UPDATE_PC, 3'bxxx, 2'bxx, 3'bxxx}:    next = {`DEC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, `L_PC, `ADDR_SEL, `L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};      
      
      // {`SEL_PC, 3'b001, 2'b00, 3'bxxx}:       next = {`IF1, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      // {`SEL_PC, 3'b010, 2'bxx, 3'bxxx}:       next = {`IF1, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      // {`SEL_PC, 3'bxxx, 2'bxx, 3'bxxx}:       next = {`DEC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
                         
      // MOV Rn, #<im8>. If opcode is 110 and op is 10 (to AND) 
      // States: DEC -> WRITE_IMM -> IF1. 
      {`DEC, 3'b110, 2'b10, 3'bxxx}:          next = {`WRITE_IMM, ~`WRITE, `SXIMM8, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`WRITE_IMM, 3'b110, 2'b10, 3'bxxx}:    next = {`IF1, `WRITE, `SXIMM8, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // MOV Rd, Rm{,<sh_op>}. If opcode is 110 and op is 00
      // States: DEC -> GET_B -> ADD_OPSH -> WRITE_REG -> IF1. 
      {`DEC, 3'b110, 2'b00, 3'bxxx}:          next = {`GET_B, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b110, 2'b00, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W}; 
      {`ADD_OPSH, 3'b110, 2'b00, 3'bxxx}:     next = {`WRITE_REG, ~`WRITE, `C, `Rm, ~`ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`WRITE_REG, 3'b110, 2'b00, 3'bxxx}:    next = {`IF1, `WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MREAD, ~`W};

      // ADD Rd,Rn,Rm{,<sh_op>}. If opcode is 101 and op is 00 (to ADD)
      // States: DEC -> GET_A -> GET_B -> ADD_OPSH -> WRITE_REG -> IF1. 
      {`DEC, 3'b101, 2'b00, 3'bxxx}:          next = {`GET_A, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_A, 3'b101, 2'b00, 3'bxxx}:        next = {`GET_B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, `LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b101, 2'b00, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH, 3'b101, 2'b00, 3'bxxx}:     next = {`WRITE_REG, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`WRITE_REG, 3'b101, 2'b00, 3'bxxx}:    next = {`IF1, `WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // CMP Rn,Rm{,<sh_op>}. If opcode is 101 and op is 01 (to compare)
      // States: DEC -> GET_A -> GET_B -> CMP_OPSH -> IF1. 
      {`DEC, 3'b101, 2'b01, 3'bxxx}:          next = {`GET_A, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_A, 3'b101, 2'b01, 3'bxxx}:        next = {`GET_B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, `LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b101, 2'b01, 3'bxxx}:        next = {`CMP_OPSH, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`CMP_OPSH, 3'b101, 2'b01, 3'bxxx}:     next = {`IF1, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, `LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // AND Rd,Rn,Rm{,<sh_op>}. If opcode is 101 and op is 10 (to AND)
      // States: DEC -> GET_A -> GET_B -> AND_OPSH -> WRITE_REG -> IF1. 
      {`DEC, 3'b101, 2'b10, 3'bxxx}:          next = {`GET_A, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_A, 3'b101, 2'b10, 3'bxxx}:        next = {`GET_B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, `LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b101, 2'b10, 3'bxxx}:        next = {`AND_OPSH, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`AND_OPSH, 3'b101, 2'b10, 3'bxxx}:     next = {`WRITE_REG, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`WRITE_REG, 3'b101, 2'b10, 3'bxxx}:    next = {`IF1, `WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // MVN Rd,Rm{,<sh_op>}. If opcode is 101 and op is 11 (to NEGATE/COMPLEMENT)
      // States: DEC -> GET_B -> MVN_OPSH -> WRITE_REG -> IF1.
      {`DEC, 3'b101, 2'b11, 3'bxxx}:          next = {`GET_B, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};  
      {`GET_B, 3'b101, 2'b11, 3'bxxx}:        next = {`MVN_OPSH, ~`WRITE, `C, `Rm, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`MVN_OPSH, 3'b101, 2'b11, 3'bxxx}:     next = {`WRITE_REG, ~`WRITE, `C, `Rm, ~`ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`WRITE_REG, 3'b101, 2'b11, 3'bxxx}:    next = {`IF1, `WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // LDR Rd,[Rn{,#<im5>}]. If opcode is 011 and op is 00
      // States: DEC -> GET_A -> ADD_OPSH -> DATA_ADDRESS -> MEM -> WRITE_REG.
      {`DEC, 3'b011, 2'b00, 3'bxxx}:          next = {`GET_A, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_A, 3'b011, 2'b00, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rn, `ASEL, `BSEL, `LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH, 3'b011, 2'b00, 3'bxxx}:     next = {`DATA_ADDRESS, ~`WRITE, `C, `Rn, `ASEL, ~`BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`DATA_ADDRESS, 3'b011, 2'b00, 3'bxxx}: next = {`MEM, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, `L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`MEM, 3'b011, 2'b00, 3'bxxx}:          next = {`WRITE_REG, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MREAD, ~`W};
      {`WRITE_REG, 3'b011, 2'b00, 3'bxxx}:    next = {`IF1, `WRITE, `MDATA, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MREAD, ~`W};

      // STR Rd,[Rn{,#<im5>}]. If opcode is 100 and op is 00
      // States: DEC -> GET_A -> ADD_OPSH -> DATA_ADDRESS -> GET_B -> ADD_OPSH2 -> MEM.
      {`DEC, 3'b100, 2'b00, 3'bxxx}:          next = {`GET_A, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_A, 3'b100, 2'b00, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rn, `ASEL, `BSEL, `LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH, 3'b100, 2'b00, 3'bxxx}:     next = {`DATA_ADDRESS, ~`WRITE, `C, `Rn, `ASEL, ~`BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`DATA_ADDRESS, 3'b100, 2'b00, 3'bxxx}: next = {`GET_B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, `L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b100, 2'b00, 3'bxxx}:        next = {`ADD_OPSH2, ~`WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH2, 3'b100, 2'b00, 3'bxxx}:    next = {`MEM, ~`WRITE, `C, `Rd, ~`ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`MEM, 3'b100, 2'b00, 3'bxxx}:          next = {`IF1, ~`WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, `L_SPC, ~`C_SPC,  `MWRITE, ~`W};
      
      // B <label>. If opcode is 001 and cond is 000
      // States: DEC -> B
      {`DEC, 3'b001, 2'b00, 3'b000}:          next = {`B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`B, 3'b001, 2'b00, 3'b000}:            next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, ~`PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // BEQ <label>. If opcode is 001 and cond is 001
      // States: DEC -> BEQ
      {`DEC, 3'b001, 2'b00, 3'b001}:          next = {`BEQ, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`BEQ, 3'b001, 2'b00, 3'b001}:          next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, ~`PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // BNE <label>. If opcode is 001 and cond is 010
      // States: DEC -> BNE
      {`DEC, 3'b001, 2'b00, 3'b010}:          next = {`BNE, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`BNE, 3'b001, 2'b00, 3'b010}:          next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, ~`PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // BLT <label>. If opcode is 001 and cond is 011
      // States: DEC -> BLT
      {`DEC, 3'b001, 2'b00, 3'b011}:          next = {`BLT, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};   
      {`BLT, 3'b001, 2'b00, 3'b011}:          next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, ~`PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // BLE <label>. If opcode is 001 and cond is 100
      // States: DEC -> BLE
      {`DEC, 3'b001, 2'b00, 3'b100}:          next = {`BLE, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};     
      {`BLE, 3'b001, 2'b00, 3'b100}:          next = {`UPDATE_PC, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, ~`PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W};

      // BL <label> (Direct Call). If opcode is 010 and op is 11
      // States: DEC -> WRITE_IMM
      {`DEC, 3'b010, 2'b11, 3'bxxx}:          next = {`WRITE_IMM, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W}; 
      {`WRITE_IMM, 3'b010, 2'b11, 3'bxxx}:    next = {`UPDATE_PC, `WRITE, `PC, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, `PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W}; 

      // BX Rd (Return). If opcode is 010 and op is 00
      // States: DEC -> GET_B -> ADD_OPSH
      {`DEC, 3'b010, 2'b00, 3'bxxx}:          next = {`GET_B, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`GET_B, 3'b010, 2'b00, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH, 3'b010, 2'b00, 3'bxxx}:     next = {`UPDATE_PC, ~`WRITE, `C, `Rd, ~`ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};

      // BLX Rd (Indirect Call). If opcode is 010 and op is 10
      // States: DEC -> WRITE_IMM -> GET_B -> ADD_OPSH
      {`DEC, 3'b010, 2'b10, 3'bxxx}:          next = {`WRITE_IMM, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`WRITE_IMM, 3'b010, 2'b11, 3'bxxx}:    next = {`GET_B, `WRITE, `PC, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, `L_SX, `PC_PLUS, `L_SPC, ~`C_SPC, `MNONE, ~`W}; 
      {`GET_B, 3'b010, 2'b10, 3'bxxx}:        next = {`ADD_OPSH, ~`WRITE, `C, `Rd, `ASEL, `BSEL, ~`LA, `LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};
      {`ADD_OPSH, 3'b010, 2'b10, 3'bxxx}:     next = {`UPDATE_PC, ~`WRITE, `C, `Rd, ~`ASEL, `BSEL, ~`LA, ~`LB, `LC, ~`LS, ~`RESET_PC, ~`L_PC, ~`ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, ~`W};                             

      // HALT. If opcode is 111 and op is xx or "not care".
      // States: DEC -> HALT.
      {`DEC, 3'b111, 2'bxx, 3'bxxx}:          next = {`HALT, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, ~`RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, `C_SPC,  `MNONE, ~`W};
      {`HALT, 3'b111, 2'bxx, 3'bxxx}:         next = {`HALT, ~`WRITE, `C, `Rn, `ASEL, `BSEL, ~`LA, ~`LB, ~`LC, ~`LS, `RESET_PC, ~`L_PC, `ADDR_SEL, ~`L_ADDR, ~`LOAD_IR, ~`L_SX, `PC_PLUS, ~`L_SPC, ~`C_SPC,  `MNONE, `W};
      
      //default: go to RST state
      default:  next = {{5{1'bx}}, ~`WRITE, {25{1'bx}}};

    endcase
  end

  //assign the concatenation of all outputs of the FSM to next.
  assign {next_state, write, vsel, nsel, asel, bsel, loada, loadb, loadc, loads, reset_pc, load_pc, addr_sel, load_addr, load_ir, load_sximm8, pc_plus, load_select_pc, choose_select_pc, mem_cmd, w} = next;   

  // Always block to assign select_pc, choose_select_pc from FSM controller
  always @* begin
    casex({present_state, opcode, op, cond}) //Decide temp_pc based on given concatenation of cases.
      // {`RST, 3'bxxx, 2'bxx, 3'bxxx}:        temp_pc = 1'b0;
      // {`SEL_PC, 3'bxxx, 2'bxx, 3'bxxx}:     temp_pc = 1'b0;

      {`B, 3'b001, 2'b00, 3'b000}:          temp_pc = 1'b1;
      {`BEQ, 3'b001, 2'b00, 3'b001}:        temp_pc = 1'b1;
      {`BNE, 3'b001, 2'b00, 3'b010}:        temp_pc = 1'b1;
      {`BLT, 3'b001, 2'b00, 3'b011}:        temp_pc = 1'b1;
      {`BLE, 3'b001, 2'b00, 3'b100}:        temp_pc = 1'b1;
      {`WRITE_IMM, 3'b010, 2'b11, 3'bxxx}:  temp_pc = 1'b1;
      {`WRITE_IMM, 3'b010, 2'b11, 3'bxxx}:  temp_pc = 1'b1;  

      default: temp_pc = 1'b0; //Set temp_pc to 0 by default.
    endcase
  end

  // Module instantiatiom for a register with load enable to load temp_pc.
  vDFFE #(1) tempReg (clk, load_select_pc, temp_pc, temp_pc_out);
  assign select_pc = choose_select_pc ? temp_pc_out : 1'b0; //Assign select_pc to temp_pc_out if choose_select_pc is 1, else 0.

endmodule