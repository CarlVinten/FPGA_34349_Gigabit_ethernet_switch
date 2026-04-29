# 1. Compile the source files
# This picks up your latest VHDL code changes
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work tb_fcs_check_parallel.vhd

# 2. Manage Simulation State
if {[runStatus] != "No Design Loaded"} {
    # If the simulation is already open, just reset the time.
    # This preserves your Wave window and zoom settings.
    echo "--- Resetting Simulation (Keeping Waves) ---"
    restart -f
} else {
    # If no simulation is open, start it and add signals for the first time.
    echo "--- Starting New Simulation Session ---"
    vsim -voptargs="+acc" work.test
    
    # 3. Add waves ONLY on the first load to avoid duplicates
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
}

# 4. Run the simulation
run 600 ns

# 5. Zoom to fit the full view
wave zoom full