onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider CPU
add wave -noupdate /lab8_stage2_tb/DUT/CPU/clk
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/PC
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/pc_increment
add wave -noupdate /lab8_stage2_tb/DUT/CPU/N
add wave -noupdate /lab8_stage2_tb/DUT/CPU/V
add wave -noupdate /lab8_stage2_tb/DUT/CPU/Z
add wave -noupdate /lab8_stage2_tb/DUT/CPU/w
add wave -noupdate -divider FSM
add wave -noupdate /lab8_stage2_tb/DUT/CPU/FSM/present_state
add wave -noupdate -divider Registers
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R0
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R1
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R2
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R3
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R4
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R5
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R6
add wave -noupdate -radix hexadecimal /lab8_stage2_tb/DUT/CPU/DP/REGFILE/R7
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {102 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1336 ps}
