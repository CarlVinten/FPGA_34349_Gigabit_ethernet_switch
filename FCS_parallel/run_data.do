# 1. Clean up the environment
if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# 2. Compile the source files
# Order matters: compile the components first, then the top-level testbench
vcom -reportprogress 300 -work work fcs_check_parallel.vhd
vcom -reportprogress 300 -work work data_input.vhd
vcom -reportprogress 300 -work work tb_data_input.vhd

# 3. Load the simulation
# Use -voptargs="+acc" to ensure internal signals/registers are visible
vsim -voptargs="+acc" work.test

# 4. Configure the Wave window
# Organize with dividers for better readability
add wave -noupdate -divider "TB STIMULUS"
add wave -hex /test/s_clk
add wave -hex /test/s_rst
add wave -hex /test/u_data_in
add wave -hex /test/u_valid

add wave -noupdate -divider "THE BRIDGE (Parser -> Checker)"
add wave -hex /test/f_fcs_data_bridge
add wave -hex /test/f_sof_bridge
add wave -color "Yellow" -hex /test/s_is_data_valid

add wave -noupdate -divider "PARSER INTERNAL"
add wave -hex /test/u_parser/state
add wave -hex /test/u_parser/preamble_cnt
add wave -hex /test/u_parser/data_cnt

add wave -noupdate -divider "CHECKER INTERNAL"
add wave -hex /test/u_checker/sum_reg
add wave -hex /test/u_checker/data_temp

# 5. Run the simulation
# 1200 ns should be enough to see the preamble, data, and final result
run 1200 ns

# 6. View full results
wave zoom full