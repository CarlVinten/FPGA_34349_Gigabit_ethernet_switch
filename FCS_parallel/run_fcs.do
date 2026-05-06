# 1. Compile the source files
vcom -work work fcs_check_parallel.vhd
vcom -work work tb_fcs_check_parallel.vhd

# 2. Stop any existing simulation
quit -sim

# 3. Load the testbench (Entity: test)
vsim -voptargs="+acc" work.test

# 4. Add Waves from the Testbench (Top Level)
add wave -noupdate -divider "TESTBENCH SIGNALS"
add wave -hex /test/s_clk
add wave -hex /test/s_rst
add wave -hex /test/s_data_in
add wave -hex /test/s_valid
add wave -hex /test/s_start_of_frame
add wave -hex /test/s_end_of_frame
add wave -color "Cyan" -hex /test/s_is_data_valid

# 5. Add Internal Signals from the DUT
add wave -noupdate -divider "DUT INTERNAL"
add wave -hex /test/dut/sum_reg
add wave -hex /test/dut/data_temp
add wave -hex /test/dut/start_cnt

# 6. Run the simulation
run 1000 ns
wave zoom full