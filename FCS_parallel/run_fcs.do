# 1. Compile the source files (Always do this to pick up code changes)
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work tb_fcs_check_parallel.vhd

# 2. Check if a simulation is already running
# If yes, restart it (keeps signals). If no, start it and add signals.
if {[runStatus] != "No Design Loaded"} {
    echo "--- Restarting Existing Simulation ---"
    restart -f
} else {
    echo "--- Starting New Simulation ---"
    vsim -voptargs="+acc" work.test
    
    # 3. Add signals only on the first load to avoid duplicates
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
}

# 4. Run the simulation
run 600 ns

# 5. Zoom to fit
wave zoom full