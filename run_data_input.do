# Create the work library if it doesn't already exist
vlib work
vmap work work

# -------------------------------------------------------------------------
# COMPILE VHDL FILES IN DEPENDENCY ORDER
# -------------------------------------------------------------------------

# 1. Compile Global Variables Package first (required by all other modules) [cite: 84]
vcom -reportprogress 300 -work work global.vhd

# 2. Compile independent sub-components [cite: 50, 106]
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work MAC_learning.vhd

# 3. Compile the Data Input module (instantiates sub-components) [cite: 2]
vcom -reportprogress 300 -work work data_input.vhd

# 4. Compile the Testbench [cite: 140]
vcom -reportprogress 300 -work work tb_data_input.vhd

# -------------------------------------------------------------------------
# START SIMULATION
# -------------------------------------------------------------------------

# Load the testbench entity named 'test' [cite: 140]
# -voptargs=+acc enables visibility for all signals in the waveform
vsim -voptargs=+acc work.test

# -------------------------------------------------------------------------
# ADD WAVES
# -------------------------------------------------------------------------

# Add top-level Testbench signals [cite: 143-146]
add wave -divider "Testbench Signals"
add wave -position insertpoint sim:/test/*

# Add internal Data Input (DUT) signals [cite: 2, 8-23]
add wave -divider "DUT Internal Signals"
add wave -position insertpoint sim:/test/DUT/*

# Add independent port state arrays to monitor parallel execution 
add wave -divider "Port States"
add wave -position insertpoint sim:/test/DUT/state

# -------------------------------------------------------------------------
# RUN SIMULATION
# -------------------------------------------------------------------------

# Run until the report "Simulation Finished" is reached [cite: 167]
run 100 ns

# Zoom to fit the entire simulation in the wave window
wave zoom full