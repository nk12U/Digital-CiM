# Clock constraints
create_clock -name "CLK" -period 100 [get_ports {CLK}]

# tsu/th constraints
set_input_delay -clock CLK -max 5 [get_ports -filter {DIRECTION == IN && NAME != "CLK"}]
set_input_delay -clock CLK -min 2 [get_ports -filter {DIRECTION == IN && NAME != "CLK"}]

# tco constraints
set_output_delay -clock CLK -max 5 [all_outputs]
set_output_delay -clock CLK -min 2 [all_outputs]
