# 1. Quit any current simulation
quit -sim

# 2. Create and map the work library
vlib work
vmap work work

# 3. Compile your VHDL files
# (Using the names from your screenshot)
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work tb_fcs_check_parallel.vhd

# 4. Start the simulation on the test entity
# -voptargs="+acc" ensures signals aren't optimized away so you can see them
vsim -voptargs="+acc" work.test

# 5. Add signals to the wave window
# The '*' adds all top-level signals. 
# The '-recursive' would add internal DUT signals too.
add wave -noupdate -divider "Top Level Signals"
add wave -hex /test/*

add wave -noupdate -divider "Internal DUT Logic"
add wave -hex /test/dut/*

# 6. Run the simulation
run 400 ns

# 7. Zoom to fit the full waveform
wave zoom full