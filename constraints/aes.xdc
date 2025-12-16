# Timing constraints
# Define a 100MHz clock (10ns period)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Voltage and Configuration Bank Voltage Selection
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# I/O Standard constraints (Assuming 3.3V LVCMOS for all ports)
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports {addr[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {data_in[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports we]
set_property IOSTANDARD LVCMOS33 [get_ports en]

# Pin Assignments (Placeholder)
