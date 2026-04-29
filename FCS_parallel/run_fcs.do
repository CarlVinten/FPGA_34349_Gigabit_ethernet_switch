# 1. Compile
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work tb_fcs_check_parallel.vhd

# 2. Manage Simulation State
if {[runStatus] != "No Design Loaded"} {
    echo "--- Restarting Existing Simulation ---"
    restart -f
} else {
    echo "--- Starting New Simulation ---"
    vsim -voptargs="+acc" work.test
}

# 3. Add Waves (Moved outside the 'else' so they always refresh)
# This will ensure 'sum_reg' (no 's_') is added to the window
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

# 4. Run and Zoom
run 600 ns
wave zoom full