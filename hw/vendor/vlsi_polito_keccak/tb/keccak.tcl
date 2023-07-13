
set workdir [pwd]
puts "Working directory :"
puts $workdir
set rtldir $workdir/../../rtl/src_64bit/with_FSM_noBuffer
puts "Rtl directory :"
puts $rtldir
quit -sim 

vcom -reportprogress 300 -work work $rtldir/keccak_globals.vhd
vcom -reportprogress 300 -work work $rtldir/Keccak_2to1mux.vhd
vcom -reportprogress 300 -work work $rtldir/Keccak_REG_rst_n.vhd
vcom -reportprogress 300 -work work $rtldir/reg_en_rst_n.vhd
vcom -reportprogress 300 -work work $rtldir/keccak_round_constants_gen.vhd
vcom -reportprogress 300 -work work $rtldir/keccak_round.vhd
vcom -reportprogress 300 -work work $rtldir/keccak_datapath.vhd
vlog -reportprogress 300 -work work $rtldir/keccak_cu.sv
vcom -reportprogress 300 -work work $rtldir/keccak.vhd
vcom -reportprogress 300 -work work $workdir/keccak_tb.vhd

vsim -debugDB -t 1ns work.keccak_tb

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /keccak_tb/clk
add wave -noupdate /keccak_tb/rst_n

add wave -noupdate -group KECCAK_DP /keccak_tb/start
add wave -noupdate -group KECCAK_DP /keccak_tb/din
add wave -noupdate -group KECCAK_DP /keccak_tb/permutation_computed
add wave -noupdate -group KECCAK_DP /keccak_tb/dout
add wave -noupdate -group KECCAK_DP /keccak_tb/keccak_i/DP/counter_nr_rounds
add wave -noupdate -group KECCAK_DP /keccak_tb/DP/keccak_i/permutation_computed 
add wave -noupdate -group KECCAK_DP /keccak_tb/DP/keccak_i/compute_permutation

add wave -noupdate -group KECCAK_CU /keccak_tb/keccak_i/CU/start_dp_o
add wave -noupdate -group KECCAK_CU /keccak_tb/keccak_i/CU/State
add wave -noupdate -group KECCAK_CU /keccak_tb/keccak_i/CU/State_next
add wave -noupdate -group KECCAK_CU /keccak_tb/keccak_i/CU/counter
add wave -noupdate -group KECCAK_CU /keccak_tb/keccak_i/CU/status
 


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 250
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
configure wave -timelineunits ns
update

run 20 us
WaveRestoreZoom {0 ns} {300 ns}
