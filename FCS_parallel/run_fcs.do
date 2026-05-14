# 1. Compile the source files
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work tb_fcs_check_parallel.vhd

# 2. Clean up any existing simulation
# We use 'quit -sim' to ensure logic changes are reloaded into memory.
# The 'nocheck' prevents the script from stopping if no sim was running.
quit -sim

# 3. Start the simulation
echo "--- Loading Latest Compiled Design ---"
vsim -voptargs="+acc" work.test

# 4. Add Waves
# ModelSim will usually remember your wave window layout 
# if you keep the window open between runs.
add wave -noupdate -divider "Top Level Signals"
add wave -hex /test/s_clk
add wave -hex /test/s_reset
add wave -hex /test/s_data_in
add wave -hex /test/s_valid
add wave -hex /test/s_start_of_frame
add wave -hex /test/s_end_of_frame
add wave -hex /test/s_is_data_valid

add wave -noupdate -divider "Internal DUT Logic"
add wave -hex /test/dut/sum_reg
add wave -hex /test/dut/start_cnt
add wave -hex /test/dut/data_temp

# 5. Run the simulation
run 600 ns

# 6. Zoom to fit
wave zoom full