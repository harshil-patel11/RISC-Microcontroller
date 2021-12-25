# RISC-Microcontroller

A Simple RISC Machine Microcontroller / CPU:

- Executes programs written using a small set of instructions
- Based on instructions from ARM architecture
- Allows the execution of instructions such as LOAD, STORE, MOV, ADD, SUB, AND, NOT (and other shift operations), HALT, BLX (conditional/ unconditional branches) and more

## ALU (Arithmetic Logic Unit)

- Can perform arithmetic or logical instructions
- It contains a multiplexer that decides which instruction to carry out based on the ALUop select signal
- Allows for addition, subtraction, AND, NOT, shift operations (can be found in shifter.v)

## Register File

- Small memory block that stores data in registers at certain addresses
- Eight registers, each can store 16 bits of data
- Built using registers with load enables (written in Verilog)

## Datapath

- Includes all the building blocks of the RISC machine such as Program Counter, RAM, I/O etc
- Controller decides the path taken by the data using a Finite State Machine [FSM] by setting the select/enable signals to multiplexers/registers

## CPU

- Responsible for updating PC, address calculation and selection for instructions and data that travel through the datapath
- Responsible for reading/writing to RAM

## Controller

- Uses an FSM in order to perform instructions
- An instruction read from memory begins the execution of a program in cycles with hardware operations controlled by the controller
