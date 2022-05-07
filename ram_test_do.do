setenv LMC_TIMEUNIT -9

vlib work
vmap work work
vlog -work work ram_if.sv
vlog -work work ram.sv
vlog -work work ram_tb.sv

vsim -L work work.ram_tb -dpilib work.my_dpi -wlf ram_sim.wlf -sv_lib my_dpi

add wave -noupdate -group ram_tb
add wave -noupdate -group ram_tb -radix hexadecimal /ram_tb/*
add wave -noupdate -group ram_tb/dut/ramif
add wave -noupdate -group ram_tb/dut/ramif -radix hexadecimal /ram_tb/dut/ramif/*
add wave -noupdate ram_tb/dut/mem
add wave -noupdate -group ram_tb/testing
add wave -noupdate -group ram_tb/testing -radix hexadecimal /ram_tb/testing/*

run -all
