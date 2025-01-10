# Температурный датчик I2C
set_property PACKAGE_PIN M19 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports scl]
set_property PACKAGE_PIN M20 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sda]

# Выходы управления двигателем
set_property PACKAGE_PIN K19 [get_ports motor_phase_a]
set_property IOSTANDARD LVCMOS33 [get_ports motor_phase_a]
set_property PACKAGE_PIN K20 [get_ports motor_phase_b]
set_property IOSTANDARD LVCMOS33 [get_ports motor_phase_b] 